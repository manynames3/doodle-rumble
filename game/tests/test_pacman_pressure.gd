extends SceneTree
## Exercise a long Pac-Man fight with real movement, attack clocks, and hit rules.
const DT = 1.0 / 60.0
var Fighter: GDScript
var PacAI: GDScript
var world: Node2D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func spawn(id: String, slot: int, at: Vector2):
	var fighter = Fighter.new()
	world.add_child(fighter)
	fighter.setup(id, slot, true)
	fighter.reset_at(at)
	return fighter

func run() -> void:
	await process_frame
	Fighter = load("res://scripts/fighter.gd")
	PacAI = load("res://scripts/pacman_controller.gd")
	if not Fighter or not Fighter.can_instantiate() or not PacAI or not PacAI.can_instantiate():
		push_error("Pac-Man pressure dependencies failed to compile")
		quit(1)
		return
	world = Node2D.new()
	root.add_child(world)
	var floor_body = StaticBody2D.new()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(1280, 100)
	collider.shape = shape
	floor_body.add_child(collider)
	floor_body.position = Vector2(640, 650)
	world.add_child(floor_body)
	await physics_frame
	await test_full_pressure_cycle()
	await test_direction_commitment()
	await test_platform_pursuit()
	await test_aerial_chomp_contact()
	world.queue_free()
	root.get_node("Sound").shutdown()
	await process_frame
	print("PACMAN_PRESSURE_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func test_full_pressure_cycle() -> void:
	var pac = spawn("pac_man", 2, Vector2(350, 599))
	var player = spawn("orange", 1, Vector2(650, 599))
	# Extra fixture health lets the same passive opponent expose two complete
	# cycles without interrupting the controller when the normal round would end.
	player.health = 500
	var ai = PacAI.new()
	ai.reset()
	var released := {"bite":0, "dash":0, "pellet_fan":0, "leap_chomp":0}
	var pellet_events: Array[String] = []
	ai.pattern_released.connect(func(kind: String): pellet_events.append(kind))
	var elapsed := 0.0
	var warning_started := -1.0
	var max_idle := 0.0
	var last_release := 0.0
	var saw_chase := false
	var saw_recovery_open := false
	var saw_guarded_tell := false
	var bad_warning := false
	for frame in range(2100):
		await physics_frame
		var prior_tell: String = ai.tell
		var prior_pellets: int = pellet_events.size()
		var command: Dictionary = ai.read_input(DT, pac, player)
		if prior_tell == "" and ai.tell != "":
			warning_started = elapsed
		if ai.state == "tell" and pac.boss_guard and pac.guard_remaining > 0.0:
			saw_guarded_tell = true
		if absf(float(command.move)) > 1.0 and ai.state == "approach":
			saw_chase = true
		var released_kind := ""
		if command.special:
			released_kind = "dash"
		elif command.attack:
			if ai.current_pattern == "leap_chomp":
				check(command.lock_facing and pac.facing == ai.committed_facing, "airborne chomp keeps its warned direction")
			else:
				released_kind = "bite"
		elif pellet_events.size() > prior_pellets:
			released_kind = "pellet_fan"
		elif command.jump and ai.state == "leaping":
			released_kind = "leap_chomp"
		if released_kind != "":
			if warning_started < 0.0 or elapsed - warning_started < float(PacAI.TELL_SECONDS[released_kind]) - DT * 1.5:
				bad_warning = true
			max_idle = maxf(max_idle, elapsed - last_release)
			last_release = elapsed
			released[released_kind] += 1
			if released_kind == "pellet_fan":
				check(pellet_events.back() == "pellet_fan", "pellet release carries the expected event kind")
			if released_kind in ["bite", "dash"]:
				check(command.lock_facing and pac.facing == ai.committed_facing, "melee releases retain their warned direction")
			warning_started = -1.0
		pac.tick(DT, command, player)
		player.tick(DT, {}, pac)
		pac.try_hit(player)
		if ai.state == "executing" and pac.attack_time >= 0.0 and pac.attack_time >= float(pac.attack_spec.get("windup", 0.0)) + float(pac.attack_spec.get("active", 0.0)) and not pac.boss_guard:
			saw_recovery_open = true
		elapsed += DT
		if released.bite >= 2 and released.dash >= 2 and released.pellet_fan >= 2 and released.leap_chomp >= 2:
			break
	check(saw_chase, "Pac-Man closes distance at his faster approach speed")
	check(released.bite >= 2 and released.dash >= 2 and released.pellet_fan >= 2 and released.leap_chomp >= 2, "a sustained live fight uses all four patterns twice")
	check(not bad_warning, "every pattern has its full warning before release")
	check(saw_guarded_tell, "a committed warning has bounded hit-stun protection")
	check(saw_recovery_open, "the boss becomes punishable after an active attack")
	check(max_idle < 5.5, "the controller sustains pressure without multi-second idle gaps")
	check(pellet_events.size() == released.pellet_fan, "one pellet fan is emitted per warned pattern")
	check(player.health > 0 and pac.health > 0, "the long simulation stays in a live fight")
	print("PACMAN_PRESSURE_METRICS elapsed=%.2f releases=%s max_gap=%.2f player_hp=%d" % [elapsed, str(released), max_idle, player.health])
	pac.queue_free()
	player.queue_free()
	await process_frame

func test_direction_commitment() -> void:
	var pac = spawn("pac_man", 2, Vector2(430, 599))
	var player = spawn("orange", 1, Vector2(670, 599))
	var ai = PacAI.new()
	ai.reset()
	ai.pattern_index = 1 # Charged dash is the clearest facing commitment.
	ai.time_left = 0.0
	var warned := false
	var crossed := false
	var fired := false
	for frame in range(180):
		await physics_frame
		var command: Dictionary = ai.read_input(DT, pac, player)
		if ai.state == "tell" and not warned:
			warned = true
			check(ai.committed_facing == 1, "dash warning points toward the initial player position")
		if warned and ai.state == "tell" and not crossed:
			player.position.x = pac.position.x - 180.0
			crossed = true
		if command.special:
			fired = true
			check(command.lock_facing and ai.committed_facing == 1, "crossing behind the tell cannot redirect the dash")
		pac.tick(DT, command, player)
		player.tick(DT, {}, pac)
		if fired:
			check(pac.facing == 1, "fighter movement honors the committed dash direction")
			break
	check(warned and crossed and fired, "direction test reaches a charged dash after crossing behind")
	pac.queue_free()
	player.queue_free()
	await process_frame

func test_platform_pursuit() -> void:
	var pac = spawn("pac_man", 2, Vector2(380, 599))
	var player = spawn("orange", 1, Vector2(570, 410))
	for frame in range(12):
		await physics_frame
		pac.tick(DT, {}, player)
	check(pac.is_on_floor(), "pursuit fixture settles on the arena floor")
	var ai = PacAI.new()
	ai.reset()
	ai.state = "approach"
	ai.current_pattern = "bite"
	var first_command: Dictionary = ai.read_input(DT, pac, player)
	check(first_command.jump, "an elevated nearby opponent triggers a pursuit jump")
	check(ai.jump_wait >= 1.2, "pursuit jumps set a meaningful repeat delay")
	var second_command: Dictionary = ai.read_input(DT, pac, player)
	check(not second_command.jump, "the pursuit jump cannot repeat on the next physics frame")
	pac.queue_free()
	player.queue_free()
	await process_frame

func test_aerial_chomp_contact() -> void:
	var pac = spawn("pac_man", 2, Vector2(400, 599))
	var player = spawn("orange", 1, Vector2(560, 599))
	var ai = PacAI.new()
	ai.reset()
	ai.pattern_index = 3
	ai.time_left = 0.0
	var saw_takeoff := false
	var connected := false
	var contact_height := 0.0
	for frame in range(270):
		await physics_frame
		var command: Dictionary = ai.read_input(DT, pac, player)
		if ai.current_pattern == "leap_chomp" and ai.state == "leaping" and command.jump:
			saw_takeoff = true
		pac.tick(DT, command, player)
		player.tick(DT, {}, pac)
		if pac.try_hit(player):
			connected = true
			contact_height = pac.position.y
			break
	check(saw_takeoff, "aerial chomp starts with a visible jump")
	check(connected, "the descending chomp can connect with a grounded target")
	check(not connected or contact_height < 590.0, "the aerial chomp connects while airborne")
	pac.queue_free()
	player.queue_free()
	await process_frame
