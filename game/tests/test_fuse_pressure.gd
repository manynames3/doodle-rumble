extends SceneTree
## Real held-bow pressure must not leave Fuse cycling through hit pauses.
const DT := 1.0 / 60.0
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	await process_frame
	check("--isolated-qa" in OS.get_cmdline_user_args(), "QA preferences are isolated")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "arcade"
	game.selected[0] = "purple"
	game.optional_hazards = false
	game.arcade_stage = 6
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(210, 599))
	game.second.reset_at(Vector2(1060, 599))
	var arrows := 0
	var damage := 0
	var hit_frames := 0
	var wait_after_hit := 0
	var longest_wait := 0
	var recovering := false
	var resumed := 0
	var released := []
	game.fuse_ai.pattern_released.connect(func(kind: String, _angle: float): released.append(kind))
	for frame in range(900):
		if game.first.attack_time < 0 and game.first.hurt_time <= 0 and game.first.health > 0:
			if game.first.start_attack(false): arrows += 1
		await physics_frame
		game._physics_process(DT)
		damage += 100 - game.first.health
		game.first.health = 100
		game.second.health = game.second.max_health
		if game.second.hurt_time > 0:
			hit_frames += 1
			recovering = true
			wait_after_hit = 0
		elif recovering:
			wait_after_hit += 1
			if game.fuse_ai.state == "tell":
				longest_wait = maxi(longest_wait, wait_after_hit)
				resumed += 1
				recovering = false
	check(arrows >= 15, "opponent fires real bow shots at held-attack cadence")
	check(hit_frames > 0 and resumed > 0, "Fuse takes live arrows and resumes a full warning")
	check(longest_wait <= 45, "live post-hit restart avoids a full reload pause")
	check(released.size() >= 8, "Fuse continues launching frequent attacks under arrow pressure")
	var distinct := {}
	for kind in released: distinct[kind] = true
	check(distinct.size() >= 3, "live ranged fight varies its missile patterns")
	check(damage > 0, "missiles reach and damage the active shooter")
	print("FUSE_LIVE_BOW arrows=%d hit_frames=%d resumed=%d longest_restart_frames=%d releases=%s damage=%d" % [arrows, hit_frames, resumed, longest_wait, str(released), damage])
	game.queue_free()
	root.get_node("Sound").shutdown()
	await process_frame
	print("FUSE_PRESSURE_TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
