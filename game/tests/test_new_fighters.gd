extends SceneTree
## Six-fighter selection plus independent Purple/Yellow projectile integration.
## Run: Godot --headless --fixed-fps 60 --path game --script res://tests/test_new_fighters.gd
const DT = 1.0 / 60.0
const IDS = ["orange", "red", "green", "blue", "purple", "yellow"]
const SHOTS = [
	{"fighter":"purple", "kind":"arrow", "special":false, "damage":12},
	{"fighter":"purple", "kind":"signal", "special":true, "damage":24},
	{"fighter":"yellow", "kind":"swarm", "special":true, "damage":22}
]
const CONFIG_PATH = "user://settings.cfg"
const SAVED_PROPERTIES = ["master_volume", "music_volume", "sfx_volume", "reduced_motion", "hold_to_attack", "selected_fighter", "celebration_style", "arcade_wins", "_bindings", "_controllers", "_active_devices"]
var game
var settings
var effect_script: GDScript
var checks = 0
var failures: Array[String] = []
var original: Dictionary = {}
var config_existed = false
var config_bytes = PackedByteArray()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func buttons(node: Node) -> Array[BaseButton]:
	var found: Array[BaseButton] = []
	if node is BaseButton: found.append(node)
	for child in node.get_children(): found.append_array(buttons(child))
	return found

func button(caption: String) -> BaseButton:
	for candidate in buttons(game.ui):
		if candidate.text == caption: return candidate
	return null

func press(caption: String) -> void:
	var control = button(caption)
	check(is_instance_valid(control), "menu button exists: " + caption)
	if control: control.pressed.emit()
	await process_frame

func choose(id: String) -> void:
	var display: String = root.get_node("Data").fighter(id).name.to_lower()
	var card: BaseButton = null
	for candidate in buttons(game.ui):
		if candidate.text != "": continue
		for child in candidate.get_children():
			if child is Label and child.text.to_lower().begins_with(display): card = candidate
	check(is_instance_valid(card), "selectable fighter card exists: " + id)
	if card: card.pressed.emit()
	await process_frame

func release_inputs() -> void:
	for action in settings.ACTIONS: Input.action_release(action)

func attack(special: bool) -> void:
	Input.action_press("p1_special" if special else "p1_attack")
	await step()
	release_inputs()

func step(frames: int = 1) -> void:
	for frame in range(frames):
		await physics_frame
		game._physics_process(DT)

func begin(id: String, owner_x: float = 300, target_x: float = 640) -> void:
	release_inputs()
	game.mode = "local"
	game.selected = [id, "orange"]
	game.arena_kind = "desktop"
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0
	game.first.reset_at(Vector2(owner_x, 599))
	game.second.reset_at(Vector2(target_x, 599))
	await process_frame
	await step(5)

func run() -> void:
	await process_frame
	settings = root.get_node("Settings")
	config_existed = FileAccess.file_exists(CONFIG_PATH)
	if config_existed: config_bytes = FileAccess.get_file_as_bytes(CONFIG_PATH)
	for property in SAVED_PROPERTIES:
		var value = settings.get(property)
		original[property] = value.duplicate(true) if value is Array or value is Dictionary else value
	settings._bindings = settings._default_bindings()
	settings._controllers.assign([-1, -1])
	settings._active_devices.assign(["keyboard", "keyboard"])
	settings._rebuild_input_map()
	settings.reduced_motion = true
	settings.hold_to_attack = true
	effect_script = load("res://scripts/attack_effect.gd")
	var packed = load("res://scenes/main.tscn")
	check(packed != null and packed.can_instantiate(), "expanded-roster main scene compiles")
	if packed == null or not packed.can_instantiate():
		await finish()
		return
	game = packed.instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	await process_frame
	await test_six_player_choices()
	await test_integrated_attacks()
	await test_projectile_rates_and_consumption()
	await test_projectile_misses()
	await test_cooldowns_pause_and_cleanup()
	await test_recovery_controls()
	await finish()

func test_six_player_choices() -> void:
	check(root.get_node("Data").ORDER == IDS, "exactly six ordinary fighters are selectable, with bosses outside the roster")
	game.selected = ["orange", "blue"]
	game.open_selection("local")
	await process_frame
	for slot in range(2):
		await press("Player %d: %s" % [slot + 1, root.get_node("Data").fighter(game.selected[slot]).name])
		var other: String = game.selected[1 - slot]
		for id in IDS:
			await choose(id)
			check(game.selected[slot] == id and game.selected[1 - slot] == other, "player %d independently selects %s" % [slot + 1, id])
	await press("Player 1: Yellow")
	await choose("purple")
	await press("Player 2: Yellow")
	await choose("yellow")
	await press("Choose stage  >")
	check(game.state == "stage_select", "expanded roster proceeds to stage choice before local battle")
	await press("LET'S RUMBLE  >")
	check(game.mode == "local" and game.first.definition.id == "purple" and game.second.definition.id == "yellow", "local match instantiates Purple and Yellow in separate player slots")
	check(game.prompts[0].text.begins_with("P1") and game.prompts[1].text.begins_with("P2"), "new fighters retain the same independent control prompts")
	for id in ["purple", "yellow"]:
		game.new_journey_selection()
		await process_frame
		await choose(id)
		settings.selected_fighter = "orange"
		settings._load_settings()
		check(settings.selected_fighter == id, id + " remains selected after reloading saved preferences")
		await press("LET'S RUMBLE  >")
		check(game.mode == "arcade" and game.arcade_stage == 0 and game.first.definition.id == id and game.second.definition.id == "blue", id + " can begin the complete journey from Blue")
	var opponents: Array[String] = []
	for stage in range(game.Journey.STAGES.size()): opponents.append(game.journey_stage_data(stage).opponent)
	check(opponents == ["blue", "red", "green", "pac_man", "h4ck3r", "dark_lord"], "expanding the playable roster preserves the six-stage journey order")
	print("PASS group: six selectable fighters for both players, Purple/Yellow persistence and journey entry")

func test_integrated_attacks() -> void:
	for shot in SHOTS:
		for direction in [-1, 1]:
			await begin(shot.fighter, 970 if direction < 0 else 300, 630 if direction < 0 else 640)
			var released: Array[String] = []
			game.first.released.connect(func(_fighter, kind): released.append(kind))
			await attack(shot.special)
			var saw_projectile = false
			var correct_direction = true
			var empty_melee = true
			var maximum_projectiles = 0
			for frame in range(110):
				await step()
				maximum_projectiles = maxi(maximum_projectiles, game.projectiles.size())
				if game.first.is_active(): empty_melee = empty_melee and not game.first.hitbox().has_area()
				for projectile in game.projectiles:
					saw_projectile = true
					correct_direction = correct_direction and projectile.kind == shot.kind and signf(projectile.velocity.x) == direction
			var context: String = "%s direction %d" % [shot.kind, direction]
			check(released == [shot.kind], context + " releases exactly one physical projectile from fighter input")
			check(saw_projectile and correct_direction and maximum_projectiles == 1, context + " uses one correctly directed projectile group")
			check(empty_melee, context + " never adds an invisible melee hitbox")
			check(game.second.health == 100 - shot.damage and game.first.total_damage == shot.damage, context + " deals the advertised damage once")
			check(game.projectiles.is_empty() and game.first.attack_time < 0, context + " projectile and attack both clean up")
			if shot.special:
				check(game.first.cooldown > 0 and not game.first.start_attack(true), context + " cannot bypass the six-second special cooldown")
			else:
				check(game.first.cooldown == 0, "Purple basic arrow does not consume special cooldown")
	for direction in [-1, 1]:
		await begin("yellow", 700 if direction < 0 else 300, 625 if direction < 0 else 375)
		await attack(false)
		await step(90)
		check(game.second.health == 88 and game.first.total_damage == 12, "Yellow staff basic hits once facing " + str(direction))
		check(game.projectiles.is_empty() and game.first.attack_time < 0, "Yellow basic remains a recovered melee swing")
	print("PASS group: Purple arrows/signal and Yellow staff/swarm through actual input in both directions")

func make_projectile(kind: String, direction: int = 1):
	var projectile = effect_script.new()
	game.world.add_child(projectile)
	projectile.configure(game.first, kind, direction)
	return projectile

func test_projectile_rates_and_consumption() -> void:
	for shot in SHOTS:
		var damages: Array[int] = []
		for delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
			await begin(shot.fighter, 300, 500)
			var projectile = make_projectile(shot.kind)
			var done = false
			for frame in range(240):
				await physics_frame
				if projectile.tick(delta, game.second):
					done = true
					break
			var damage: int = 100 - game.second.health
			damages.append(damage)
			check(done and damage == shot.damage, "%s direct hit resolves at delta %.5f" % [shot.kind, delta])
			game.second.invulnerable = 0
			for repeat in range(6): projectile.tick(delta, game.second)
			check(100 - game.second.health == damage and game.first.total_damage == damage, shot.kind + " consumed hit cannot repeat even if victim protection is disabled")
			if shot.kind == "swarm": check(projectile.hitbox().size.is_equal_approx(Vector2(70, 60) * game.first.BODY_SCALE), "Yellow's three helpers share one damage hitbox")
			projectile.queue_free()
			await process_frame
		check(damages == [shot.damage, shot.damage, shot.damage], shot.kind + " damage is unchanged at 30/60/120 Hz")
		await begin(shot.fighter, 500, 570)
		game.second.invulnerable = 1.0
		var blocked = make_projectile(shot.kind)
		var consumed: bool = blocked.tick(DT, game.second)
		check(consumed and game.second.health == 100, shot.kind + " contact respects victim recovery protection")
		game.second.invulnerable = 0.0
		blocked.tick(DT, game.second)
		check(game.second.health == 100, shot.kind + " blocked contact cannot become a delayed unavoidable hit")
		blocked.queue_free()
		await process_frame
	print("PASS group: projectile rate independence, one-hit consumption and protected contact")

func test_projectile_misses() -> void:
	for shot in SHOTS:
		for miss in ["behind", "above"]:
			await begin(shot.fighter, 650, 250 if miss == "behind" else 900)
			if miss == "above": game.second.position.y = 330
			var projectile = make_projectile(shot.kind)
			var done = false
			for frame in range(130):
				await physics_frame
				if projectile.tick(DT, game.second):
					done = true
					break
			check(done and game.second.health == 100 and game.first.total_damage == 0, shot.kind + " can miss a target " + miss + " and expires without damage")
			projectile.queue_free()
			await process_frame
	await begin("purple", 200, 1100)
	var arrow = make_projectile("arrow")
	for frame in range(90):
		await physics_frame
		if arrow.tick(DT, game.second): break
	check(game.second.health == 100 and arrow.elapsed <= 0.62, "Purple basic arrow has a finite short range rather than crossing the whole arena")
	arrow.queue_free()
	await process_frame
	print("PASS group: projectile misses, jump clearance, finite range and expiry")

func test_cooldowns_pause_and_cleanup() -> void:
	for shot in SHOTS:
		for cleanup in ["next_round", "rematch"]:
			await begin(shot.fighter, 250, 1000)
			await attack(shot.special)
			await step(20)
			check(game.projectiles.size() == 1, shot.kind + " remains active before " + cleanup)
			if game.projectiles.is_empty(): continue
			var projectile = game.projectiles[0]
			var where: Vector2 = projectile.position
			var elapsed: float = projectile.elapsed
			var cooldown: float = game.first.cooldown
			game.pause_game()
			await step(30)
			check(projectile.position == where and projectile.elapsed == elapsed and game.first.cooldown == cooldown, shot.kind + " projectile and cooldown freeze when paused")
			game.resume_game()
			await step()
			check(projectile.elapsed > elapsed, shot.kind + " resumes from the same active projectile")
			game.call(cleanup)
			await process_frame
			check(game.projectiles.is_empty() and not is_instance_valid(projectile), shot.kind + " is removed by " + cleanup)
			check(game.first.cooldown == 0 and game.first.health == 100 and game.second.health == 100, cleanup + " resets new-fighter health and cooldown")
	for id in ["purple", "yellow"]:
		await begin(id)
		await attack(true)
		await step(75)
		check(game.first.cooldown > 0 and not game.first.start_attack(true), id + " special is still locked after its visual effect ends")
		await step(300)
		check(game.first.cooldown == 0, id + " special refills after six seconds of real ticks")
		await attack(true)
		check(game.first.cooldown > 5.9, id + " can activate the special again after refill")
	print("PASS group: new-projectile pause/resume, round/rematch cleanup and six-second reuse")

func test_recovery_controls() -> void:
	await begin("purple", 400, 600)
	Input.action_press("p1_attack")
	var frames = 0
	while game.second.health == 100 and frames < 90:
		await step()
		frames += 1
	check(game.second.health == 88 and game.second.invulnerable > 0, "first held-arrow hit starts normal recovery protection")
	var health: int = game.second.health
	Input.action_press("p2_move_left")
	await step(30)
	check(game.second.hurt_time == 0 and game.second.invulnerable > 0 and game.second.velocity.x < -150, "victim regains deliberate movement against knockback before protection expires")
	check(game.second.health == health, "holding Purple attack cannot chain repeated damage during victim escape window")
	release_inputs()
	print("PASS group: projectile victim can move and escape during recovery protection")

func finish() -> void:
	paused = false
	release_inputs()
	if is_instance_valid(game): game.queue_free()
	await process_frame
	for property in SAVED_PROPERTIES: settings.set(property, original[property])
	settings._rebuild_input_map()
	root.get_node("Sound").apply_settings()
	if config_existed:
		var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
		file.store_buffer(config_bytes)
		file.close()
		check(FileAccess.get_file_as_bytes(CONFIG_PATH) == config_bytes, "new-fighter suite restores original settings bytes")
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
		check(not FileAccess.file_exists(CONFIG_PATH), "new-fighter suite restores original settings-file absence")
	var restored = true
	for property in SAVED_PROPERTIES: restored = restored and settings.get(property) == original[property]
	check(restored, "new-fighter suite restores every changed Settings autoload value")
	root.get_node("Sound").shutdown()
	print("NEW_FIGHTERS_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: print("  " + failure)
	call_deferred("quit", 0 if failures.is_empty() else 1)
