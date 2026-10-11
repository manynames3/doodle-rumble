extends SceneTree
## Focused live-stage checks for Fuse's committed missiles and reload window.
const DT := 1.0 / 60.0
var game
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func clear_shots() -> void:
	for shot in game.projectiles: game._discard_projectile(shot)
	game.projectiles.clear()

func begin_pattern(index: int, target: Vector2 = Vector2(800, 599)) -> void:
	clear_shots()
	game.second.reset_at(Vector2(500, 599))
	game.first.reset_at(target)
	game.fuse_ai.reset()
	game.fuse_ai.pattern = index
	game.fuse_ai.state = "approach"
	game.fuse_ai.time_left = 0.0
	game.fuse_ai.read_input(DT, game.second, game.first)

func release_pattern() -> Dictionary:
	var command: Dictionary = {}
	for frame in range(54):
		var next: Dictionary = game.fuse_ai.read_input(DT, game.second, game.first)
		if bool(next.attack): command = next
		if game.fuse_ai.state in ["released", "executing"]: break
	return command

func pressure_damage(stage: int) -> int:
	game.arcade_stage = stage
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(450, 599))
	game.second.reset_at(Vector2(770, 599))
	var dealt := 0
	for frame in range(1500):
		game.first.health = 100
		game.second.health = game.second.max_health
		await physics_frame
		game._physics_process(DT)
		dealt += 100 - game.first.health
	return dealt

func verify_real_frames() -> void:
	game.arcade_stage = 6
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(360, 599))
	game.second.reset_at(Vector2(890, 599))
	check(game.second.rig.has_packed_art(), "Fuse has its authored runtime art")
	game.fuse_ai.state = "approach"
	game.fuse_ai.time_left = 0.0
	await physics_frame
	game._physics_process(DT)
	check(game.second.rig.packed_art.shown_frame == "aim", "real warning physics tick selects the authored aim pose")
	game._update_enemy_warning()
	check(game.enemy_warning_label.position.y < game.second.rig.global_position.y + game.second.rig.packed_art.visual_head.y * absf(game.second.rig.scale.y), "warning stays above Fuse's authored head")
	var saw_fire := false
	for frame in range(56):
		await physics_frame
		game._physics_process(DT)
		if game.fuse_ai.state == "released":
			saw_fire = game.second.rig.packed_art.shown_frame == "fire"
			var art = game.second.rig.packed_art
			var muzzle: Array = art.frames["fire"]["muzzle"]
			var authored: Vector2 = game.second.position + Vector2(game.second.facing * float(muzzle[0]) * art.pixels_to_local * absf(game.second.rig.scale.x), float(muzzle[1]) * art.pixels_to_local * absf(game.second.rig.scale.y))
			check(not game.projectiles.is_empty() and game.projectiles[0].position.distance_to(authored) < 20.0, "live missile leaves the authored firing muzzle")
			break
	check(saw_fire, "real release physics tick holds the empty-barrel fire pose")
	for frame in range(10):
		await physics_frame
		game._physics_process(DT)
	check(game.fuse_ai.state == "reload" and game.second.rig.packed_art.shown_frame == "reload", "real recovery physics ticks show the vulnerable reload pose")
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(760, 599))
	game.second.reset_at(Vector2(890, 599))
	game.fuse_ai.pattern = 3
	game.fuse_ai.state = "approach"
	game.fuse_ai.time_left = 0.0
	var late_active_protected := false
	var cleared_after_active := false
	for frame in range(100):
		await physics_frame
		game._physics_process(DT)
		if game.second.attack_time >= 0.0:
			var active_end: float = float(game.second.attack_spec.windup) + float(game.second.attack_spec.active)
			if game.second.attack_time >= active_end - DT * 1.5 and game.second.attack_time < active_end:
				late_active_protected = game.second.guard_remaining > 0.0
			if game.second.attack_time >= active_end + DT and game.second.guard_remaining == 0.0:
				cleared_after_active = true
				break
	check(late_active_protected and cleared_after_active, "bash remains committed through late active frames, then opens to punishment")

func run() -> void:
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.mode = "arcade"
	game.optional_hazards = false
	game.arcade_stage = 6
	game.start_match()
	game.countdown = 0.0
	check(game.second.definition.id == "fuse" and game.second.max_health == 215, "Fuse is the 215 HP stage before Dark lord")
	check(is_equal_approx(game.second.body_scale, game.first.BODY_SCALE * 1.1), "Fuse body and collision use the 1.1 scale")
	var strength = load("res://scripts/boss_strength.gd")
	check(strength.damage("fuse", 20) == 42, "Fuse's 50 percent stronger damage tier rounds once")
	for difficulty in range(3):
		game.fuse_ai.configure_difficulty(difficulty)
		begin_pattern(0)
		check(is_equal_approx(game.fuse_ai.time_left, 0.85), "full missile tell survives difficulty %d" % difficulty)
	game.fuse_ai.configure_difficulty(0)
	begin_pattern(0)
	var committed_angle: float = game.fuse_ai.committed_angle
	check(game.fuse_ai.tell == "MISSILE! DODGE!" and game.second.boss_cast == "missile_single", "single missile has a distinct visible warning")
	game.first.position.x = 200.0
	for frame in range(49): game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.projectiles.is_empty(), "crossing behind never shortens the 0.85-second tell")
	release_pattern()
	check(game.projectiles.size() == 1 and game.second.facing == 1, "single missile fires once in the committed direction")
	check(absf(game.projectiles[0].velocity.angle() - committed_angle) < 0.01, "missile keeps the warning's fixed aim")
	check(game.fuse_ai.state == "released" and game.second.boss_cast == "missile_single" and game.second.boss_charge == 1.0, "release holds the firing pose for a visible beat")
	check(game.second.guard_remaining == 0.0 and not game.second.boss_guard, "missile release immediately opens a punish window")
	for frame in range(8): game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.fuse_ai.state == "reload" and game.second.boss_cast == "reload" and is_equal_approx(game.fuse_ai.time_left, 0.45), "firing pose leads into a punishable reload")
	check(game.projectiles[0].damage == 38, "single missile applies Fuse damage tier once")
	begin_pattern(1)
	release_pattern()
	check(game.projectiles.size() == 3, "salvo releases exactly three missiles")
	check(game.projectiles[0].velocity.y < game.projectiles[1].velocity.y and game.projectiles[1].velocity.y < game.projectiles[2].velocity.y, "salvo fan has three fixed lanes")
	begin_pattern(2, Vector2(800, 340))
	check(game.fuse_ai.committed_angle < -0.2, "Fuse aims up at an elevated opponent")
	release_pattern()
	check(game.projectiles.size() == 2 and game.projectiles[0].velocity.y < game.projectiles[1].velocity.y, "high/low warning releases two separated lanes")
	begin_pattern(3, Vector2(620, 599))
	check(game.fuse_ai.tell == "LAUNCHER SWING!", "close attack has its own readable warning")
	var bash: Dictionary = release_pattern()
	check(bool(bash.attack) and bool(bash.lock_facing) and game.second.facing == 1, "launcher bash starts in its committed direction")
	game.second.start_attack(false)
	check(game.second.attack_spec.damage == 42, "launcher bash uses Fuse's damage tier")
	game.second.attack_time = float(game.second.attack_spec.windup) + float(game.second.attack_spec.active) + 0.01
	game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.second.guard_remaining == 0.0, "launcher bash becomes punishable after active frames")
	game.second.attack_time = -1.0
	game.fuse_ai.time_left = 0.0
	game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.fuse_ai.state == "reload", "launcher bash also gets a real recovery window")
	begin_pattern(3)
	check(game.fuse_ai.pattern == 4 and game.fuse_ai.tell == "BURST! KEEP MOVING!", "distant target turns an unreachable bash into the burst tell")
	check(is_equal_approx(game.fuse_ai.time_left, 0.85), "burst keeps the full warning after distance selection")
	release_pattern()
	check(game.projectiles.size() == 1 and game.fuse_ai.state == "released", "burst launches its first missile after the tell")
	var burst_angle: float = game.projectiles[0].velocity.angle()
	game.first.position.x = 200.0
	for frame in range(10): game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.projectiles.size() == 1, "burst does not fire its second missile early")
	game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.projectiles.size() == 2, "burst spaces its second missile by 0.18 seconds")
	for frame in range(10): game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.projectiles.size() == 2, "burst does not fire its third missile early")
	game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.projectiles.size() == 3, "burst spaces its third missile by 0.18 seconds")
	check(game.fuse_ai.state == "released" and game.second.boss_cast == "missile_burst" and game.second.facing == 1, "fire pose and direction hold through the last burst missile")
	check(game.projectiles[1].velocity.angle() == burst_angle and game.projectiles[2].velocity.angle() == burst_angle, "all burst missiles keep the warned aim")
	for frame in range(8): game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.fuse_ai.state == "reload" and game.fuse_ai.time_left >= 0.43, "burst finishes in the full vulnerable reload")
	begin_pattern(4)
	release_pattern()
	check(game.second.take_hit(1, -1) and is_equal_approx(game.second.hurt_time, 0.10), "a real hit applies Fuse's short stun")
	game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.fuse_ai.state == "stagger" and is_equal_approx(game.fuse_ai.time_left, 0.08) and game.fuse_ai.burst_shots_left == 0, "one hit cancels remaining burst missiles and starts one brief recovery")
	for frame in range(4): game.fuse_ai.read_input(DT, game.second, game.first)
	check(is_equal_approx(game.fuse_ai.time_left, 0.08), "hurt ticks do not repeatedly restart recovery")
	game.second.hurt_time = 0.0
	for frame in range(5): game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.fuse_ai.state == "approach", "Fuse resumes its attack decision after 0.08 seconds")
	game.fuse_ai.read_input(DT, game.second, game.first)
	check(game.fuse_ai.state == "tell" and game.fuse_ai.pattern == 0 and is_equal_approx(game.fuse_ai.time_left, 0.85), "interrupted burst advances to a different full-length tell")
	check(game.projectiles.size() == 1, "cancelled burst has no late missile release")
	begin_pattern(0, Vector2(800, 340))
	release_pattern()
	var elevated_shot = game.projectiles[0]
	var hit := false
	for frame in range(90):
		if elevated_shot.tick(DT, game.first):
			hit = game.first.health < 100
			break
	check(hit, "an aimed missile can hit an elevated target")
	begin_pattern(0)
	release_pattern()
	var reflected = game.projectiles[0]
	check(reflected.reflect_from(game.first) and reflected.owner_fighter == game.first and reflected.velocity.x < 0.0, "existing projectile reflection reverses missile ownership")
	check(reflected.damage == 29 and not reflected.reflect_from(game.second), "reflected missile is weakened and cannot reflect twice")
	clear_shots()
	await verify_real_frames()
	var hacker_pressure: int = await pressure_damage(5)
	var fuse_pressure: int = await pressure_damage(6)
	var dark_pressure: int = await pressure_damage(7)
	print("FUSE_PRESSURE hacker_25s=%d fuse_25s=%d dark_25s=%d" % [hacker_pressure, fuse_pressure, dark_pressure])
	check(hacker_pressure < fuse_pressure and fuse_pressure < dark_pressure, "Fuse pressure sits between H4CK3R and Dark lord")
	game.queue_free()
	root.get_node("Sound").shutdown()
	await process_frame
	print("FUSE_BOSS_TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
