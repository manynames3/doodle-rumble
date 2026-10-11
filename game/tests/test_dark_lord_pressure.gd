extends SceneTree
## Dark lord pursuit, camp response, committed tells and hit recovery.
const BossAI = preload("res://scripts/boss_controller.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
const Journey = preload("res://scripts/solo_ladder.gd")
const DT := 1.0 / 60.0
var checks := 0
var failures := 0

class FakeFighter extends RefCounted:
	var position := Vector2(950, 599)
	var weapon := {"reach": 335.0}
	var health := 240
	var max_health := 240
	var hurt_time := 0.0
	var attack_time := -1.0
	var attack_spec := {"windup": 0.27, "active": 0.18}
	var cooldown := 0.0
	var guard_remaining := 0.0
	var boss_guard := false
	var boss_cast := ""
	var boss_charge := 0.0
	var facing := -1
	func is_on_floor() -> bool:
		return true

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	await process_frame
	check("--isolated-qa" in OS.get_cmdline_user_args(), "QA uses isolated preferences")
	var ai = BossAI.new()
	ai.configure_difficulty(Difficulty.HARD)
	check(is_equal_approx(ai.approach_speed / (1.22 * Difficulty.move_factor(Difficulty.HARD)), 1.30), "pursuit speed rises exactly 30 percent")
	check(is_equal_approx(0.78 / BossAI.APPROACH_SECONDS, 1.30), "approach decision rate rises exactly 30 percent")
	check(is_equal_approx(ai.tell_duration, 0.65), "full attack tell remains intact")
	var fighter = FakeFighter.new()
	var opponent = FakeFighter.new()
	opponent.position = Vector2(100, 599)
	ai.reset()
	var released := []
	ai.pattern_released.connect(func(kind: String): released.append(kind))
	for frame in range(130):
		ai.read_input(DT, fighter, opponent)
		if ai.state == "tell": break
	check(ai.pattern == 2 and ai.tell == "VOID VOLLEY!", "distant shooter provokes a ranged attack instead of an out-of-reach sweep")
	check(fighter.facing == -1 and fighter.boss_cast == "void_orb", "ranged cast commits its direction and visible cue")
	opponent.position.x = 1150
	for frame in range(38): ai.read_input(DT, fighter, opponent)
	check(released.is_empty() and fighter.facing == -1, "crossing behind cannot shorten or reverse the full warning")
	for frame in range(3): ai.read_input(DT, fighter, opponent)
	check(released == ["void_orb"] and fighter.facing == -1, "distant attack releases in its committed direction")
	ai.reset()
	fighter.position = Vector2(950, 599)
	opponent.position = Vector2(120, 340)
	for frame in range(130):
		ai.read_input(DT, fighter, opponent)
		if ai.state == "tell": break
	check(ai.pattern == 6 and fighter.boss_cast == "void_pillar", "distant platform camper receives a full-height marked attack")
	ai.state = "tell"
	ai.tell = "VOID PILLAR! MOVE!"
	ai.time_left = 0.3
	fighter.boss_cast = "void_pillar"
	fighter.boss_charge = 0.5
	fighter.guard_remaining = 0.4
	fighter.boss_guard = true
	fighter.hurt_time = 0.12
	ai.read_input(DT, fighter, opponent)
	check(ai.state == "rest" and is_equal_approx(ai.time_left, BossAI.HIT_REST_SECONDS), "one hit interrupts once into short recovery")
	check(ai.tell == "" and fighter.boss_cast == "" and fighter.boss_charge == 0 and not fighter.boss_guard, "interrupted cast clears visible and physical guard")
	for frame in range(6): ai.read_input(DT, fighter, opponent)
	check(is_equal_approx(ai.time_left, BossAI.HIT_REST_SECONDS), "continued hit stun does not repeatedly restart recovery")
	fighter.hurt_time = 0.0
	var resumed := false
	for frame in range(50):
		ai.read_input(DT, fighter, opponent)
		if ai.state == "tell":
			resumed = true
			break
	check(resumed and ai.tell == "VOID PILLAR! MOVE!", "boss quickly resumes the pending pattern with its complete warning")
	var real_boss = load("res://scripts/fighter.gd").new()
	root.add_child(real_boss)
	real_boss.setup("dark_lord", 2, true)
	real_boss.reset_at(Vector2(800, 599))
	real_boss.take_hit(1, -1)
	check(is_equal_approx(real_boss.hurt_time, 0.12) and is_equal_approx(real_boss.invulnerable, 0.68), "shorter boss hit stun keeps fixed damage protection")
	real_boss.queue_free()
	await _test_live_camper()
	root.get_node("Sound").shutdown()
	print("DARK_LORD_PRESSURE_TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func _test_live_camper() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "arcade"
	game.selected[0] = "purple"
	game.optional_hazards = false
	game.arcade_stage = Journey.STAGES.size() - 1
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(100, 599))
	game.second.reset_at(Vector2(1180, 599))
	var shots := 0
	var damage := 0
	var closest_distance := 1080.0
	var boss_hurt := false
	var resumed_after_hit := false
	var released := []
	game.boss_ai.pattern_released.connect(func(kind: String): released.append(kind))
	for frame in range(720):
		# Hold attack at the bow's real recovery cadence, including hit interruptions.
		if game.first.attack_time < 0 and game.first.hurt_time <= 0 and game.first.health > 0:
			if game.first.start_attack(false): shots += 1
		await physics_frame
		game._physics_process(DT)
		damage += 100 - game.first.health
		game.first.health = 100
		closest_distance = minf(closest_distance, absf(game.first.position.x - game.second.position.x))
		boss_hurt = boss_hurt or game.second.hurt_time > 0.0
		if boss_hurt and game.boss_ai.state == "tell" and game.boss_ai.tell != "": resumed_after_hit = true
	check(shots >= 12, "far camper fires real arrows at held-attack cadence")
	check(boss_hurt and resumed_after_hit, "Dark lord escapes live arrow hit stun and resumes a full attack tell")
	check(closest_distance < 500.0, "Dark lord closes the gap under continuous arrow pressure")
	check(released.has("void_orb") and damage > 0, "Dark lord reaches and damages the distant shooter")
	print("DARK_LORD_LIVE_CAMPER arrows=%d released=%s damage=%d closest_distance=%.1f" % [shots, str(released), damage, closest_distance])
	game.queue_free()
	await process_frame
