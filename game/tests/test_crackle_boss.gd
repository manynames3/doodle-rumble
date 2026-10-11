extends SceneTree
## Crackle's fixed tells, pop ownership, collision sweep, and live stage timing.
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
	game.crackle_ai.reset()
	game.crackle_ai.pattern = index
	game.crackle_ai.state = "approach"
	game.crackle_ai.time_left = 0.0
	game.crackle_ai.read_input(DT, game.second, game.first)

func release_pattern() -> Dictionary:
	var command: Dictionary = {}
	for frame in range(65):
		var next: Dictionary = game.crackle_ai.read_input(DT, game.second, game.first)
		if bool(next.attack): command = next
		if game.crackle_ai.state in ["released", "executing"]: break
	return command

func pressure_damage(stage: int) -> int:
	game.arcade_stage = stage
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(450, 599))
	game.second.reset_at(Vector2(770, 599))
	var dealt := 0
	for frame in range(900):
		game.first.health = 100
		game.second.health = game.second.max_health
		await physics_frame
		game._physics_process(DT)
		dealt += 100 - game.first.health
	return dealt

func live_pose_check() -> void:
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(360, 599))
	game.second.reset_at(Vector2(890, 599))
	check(game.second.rig.has_packed_art(), "Crackle uses authored runtime art")
	if not game.second.rig.has_packed_art(): return
	game.crackle_ai.state = "approach"
	game.crackle_ai.time_left = 0.0
	await physics_frame
	game._physics_process(DT)
	check(game.second.rig.packed_art.shown_frame == "cast_windup", "real tell tick chooses cast windup art")
	for frame in range(58):
		await physics_frame
		game._physics_process(DT)
		if game.crackle_ai.state == "released": break
	check(game.crackle_ai.state == "released" and game.second.rig.packed_art.shown_frame == "cast_impact", "real release tick holds the cast impact pose")
	var art = game.second.rig.packed_art
	var muzzle: Array = art.frames["cast_impact"].get("muzzle", [])
	check(muzzle.size() == 2, "authored cast impact frame has a muzzle")
	if muzzle.size() == 2 and not game.projectiles.is_empty():
		var authored: Vector2 = game.second.position + Vector2(game.second.facing * float(muzzle[0]) * art.pixels_to_local * absf(game.second.rig.scale.x), float(muzzle[1]) * art.pixels_to_local * absf(game.second.rig.scale.y))
		check(game.projectiles[0].position.distance_to(authored) < 20.0, "rocket starts at authored muzzle")
	for frame in range(12):
		await physics_frame
		game._physics_process(DT)
	check(game.crackle_ai.state == "recovery" and game.second.rig.packed_art.shown_frame == "cast_recover", "real recovery tick shows vulnerable cast recovery")
	check(game.second.guard_remaining == 0.0, "recovery is punishable")

func run() -> void:
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.mode = "arcade"
	game.optional_hazards = false
	game.arcade_stage = 3
	game.start_match()
	game.countdown = 0.0
	check(game.second.definition.id == "crackle" and game.second.max_health == 170, "Crackle is the 170 HP stage before Pac-Man")
	check(is_equal_approx(game.second.body_scale, game.first.BODY_SCALE * 1.08), "Crackle art and collision share 1.08 scale")
	var strength = load("res://scripts/boss_strength.gd")
	check(strength.damage("crackle", 16) == 20, "Crackle's 1.20 damage tier rounds once")
	for difficulty in range(3):
		game.crackle_ai.configure_difficulty(difficulty)
		begin_pattern(0)
		check(is_equal_approx(game.crackle_ai.time_left, 0.78), "full rocket tell survives difficulty %d" % difficulty)
	game.crackle_ai.configure_difficulty(0)
	begin_pattern(0)
	var fixed_angle: float = game.crackle_ai.committed_angle
	check(game.crackle_ai.tell == "ROCKET!" and game.second.boss_cast == "rocket_single", "rocket has a distinct visible warning")
	game.first.position.x = 180.0
	for frame in range(44): game.crackle_ai.read_input(DT, game.second, game.first)
	check(game.projectiles.is_empty(), "crossing behind does not shorten rocket warning")
	release_pattern()
	check(game.projectiles.size() == 1 and game.second.facing == 1, "rocket releases once in committed direction")
	check(absf(game.projectiles[0].velocity.angle() - fixed_angle) < 0.01, "rocket holds fixed aim from warning")
	check(game.projectiles[0].damage == 22, "rocket applies Crackle damage tier once")
	check(game.projectiles[0].crackle_texture != null, "rocket uses authored projectile texture")
	check(game.projectiles[0].exhaust_texture != null, "rocket uses authored exhaust texture")
	check(game.second.guard_remaining == 0.0 and not game.second.boss_guard, "rocket release immediately opens a punish window")
	var rocket = game.projectiles[0]
	rocket.position = game.first.position + Vector2(-80, -60)
	rocket.velocity = Vector2(2000, 0)
	var boss_score: int = game.second.total_damage
	check(rocket.tick(1.0 / 20.0, game.first) and game.first.health == game.first.max_health - 22 and game.second.total_damage == boss_score + 22, "rocket sweep scores a hit across the hurtbox at low FPS")
	var old_motion: bool = root.get_node("Settings").reduced_motion
	root.get_node("Settings").reduced_motion = true
	var effect_count: int = game.world.get_child_count()
	rocket.spawn_impact(game.world)
	check(game.world.get_child_count() == effect_count, "reduced motion omits decorative rocket impact")
	root.get_node("Settings").reduced_motion = false
	rocket.spawn_impact(game.world)
	check(game.world.get_child_count() == effect_count + 1, "rocket impact uses authored burst art")
	game.world.get_child(game.world.get_child_count() - 1).queue_free()
	root.get_node("Settings").reduced_motion = old_motion
	for frame in range(8): game.crackle_ai.read_input(DT, game.second, game.first)
	check(game.crackle_ai.state == "recovery" and is_equal_approx(game.crackle_ai.time_left, 0.68), "rocket has full recovery")
	begin_pattern(1)
	check(game.crackle_ai.tell == "FIRECRACKER! POP!", "arcing firecracker announces its pop")
	release_pattern()
	check(game.projectiles.size() == 1 and game.projectiles[0].kind == "firecracker_arc", "firecracker launches as one arcing projectile")
	var cracker = game.projectiles[0]
	check(cracker.crackle_texture != null, "firecracker uses authored projectile texture")
	var first_y: float = cracker.position.y
	var popped := false
	for frame in range(31):
		if cracker.tick(DT, game.first):
			popped = true
			break
	check(popped, "firecracker reaches its timed pop")
	check(cracker.position.y < first_y, "firecracker visibly rises before pop: %.1f to %.1f" % [first_y, cracker.position.y])
	check(game.first.health == game.first.max_health, "firecracker flight is harmless before pop")
	effect_count = game.world.get_child_count()
	cracker.spawn_impact(game.world)
	check(game.world.get_child_count() == effect_count + 1, "timed pop uses authored burst art")
	game.world.get_child(game.world.get_child_count() - 1).queue_free()
	var sparks: Array = cracker.spawn_fragments()
	check(sparks.size() == 8 and cracker.spawn_fragments().is_empty(), "pop emits exactly one radial burst of eight sparks")
	var directions: Dictionary = {}
	for spark in sparks:
		directions[roundi(spark.velocity.angle() * 100)] = true
	check(directions.size() == 8 and sparks[0].damage == 10, "radial sparks have distinct lanes and one scaled damage value")
	check(sparks[0].crackle_texture != null, "burst sparks use authored projectile texture")
	check(cracker.lifetime + sparks[0].lifetime < 0.13 + 0.68 + 0.22, "burst sparks expire before the next warning can begin")
	check(sparks[0].reflect_from(game.first) and sparks[0].owner_fighter == game.first and not sparks[0].reflect_from(game.second), "a popped spark changes ownership and only reflects once")
	var boss_health: int = game.second.health
	var player_score: int = game.first.total_damage
	sparks[0].position = game.second.position + Vector2(75, -60)
	sparks[0].velocity = Vector2(-390, 0)
	for frame in range(12):
		if sparks[0].tick(DT, game.second): break
	check(game.second.health < boss_health and game.first.total_damage > player_score, "reflected spark damages Crackle and awards the player score")
	var burst_boss_score: int = game.second.total_damage
	for frame in range(30):
		for spark in sparks.slice(1):
			if not spark.consumed: spark.tick(DT, game.first)
	check(game.first.health < game.first.max_health and game.second.total_damage > burst_boss_score, "natural radial burst reaches and scores a stationary target")
	for spark in sparks: spark.queue_free()
	begin_pattern(2)
	check(game.crackle_ai.tell == "FIREWORK FAN!", "fan has a distinct warning")
	release_pattern()
	check(game.projectiles.size() == 3, "fan launches three rockets at once")
	check(game.projectiles[0].exhaust_texture != null, "fan rockets use authored exhaust texture")
	check(game.projectiles[0].velocity.y < game.projectiles[1].velocity.y and game.projectiles[1].velocity.y < game.projectiles[2].velocity.y, "fan holds three readable fixed lanes")
	check(game.projectiles[0].damage == 12, "fan damage is below single rocket damage")
	begin_pattern(3, Vector2(620, 599))
	check(game.crackle_ai.tell == "SPEAR THRUST!", "close spear attack has its own warning")
	var thrust: Dictionary = release_pattern()
	check(bool(thrust.attack) and bool(thrust.lock_facing) and game.second.facing == 1, "spear thrust commits to original direction")
	game.second.start_attack(false)
	check(game.second.attack_spec.damage == strength.damage("crackle", int(game.second.weapon.damage)), "spear applies tier once")
	game.second.attack_time = float(game.second.attack_spec.windup) + float(game.second.attack_spec.active) + 0.01
	game.crackle_ai.read_input(DT, game.second, game.first)
	check(game.second.guard_remaining == 0.0, "spear opens after active frames")
	game.second.attack_time = -1.0
	game.crackle_ai.time_left = 0.0
	game.crackle_ai.read_input(DT, game.second, game.first)
	check(game.crackle_ai.state == "recovery", "spear also has punishable recovery")
	clear_shots()
	await live_pose_check()
	var green_pressure: int = await pressure_damage(2)
	var crackle_pressure: int = await pressure_damage(3)
	var pac_pressure: int = await pressure_damage(4)
	print("CRACKLE_PRESSURE green_15s=%d crackle_15s=%d pac_15s=%d" % [green_pressure, crackle_pressure, pac_pressure])
	check(green_pressure < crackle_pressure and crackle_pressure < pac_pressure, "Crackle pressure sits between Green and Pac-Man")
	game.queue_free()
	root.get_node("Sound").shutdown()
	await process_frame
	print("CRACKLE_BOSS_TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
