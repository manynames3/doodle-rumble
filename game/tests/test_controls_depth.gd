extends SceneTree
## Run on a copy with a unique project name to isolate user:// from a live game.
## Godot --headless --fixed-fps 60 --path game --script res://tests/test_controls_depth.gd
const DT = 1.0 / 60.0
const CONFIG_PATH = "user://settings.cfg"
const SAVED_PROPERTIES = ["master_volume", "music_volume", "sfx_volume", "reduced_motion", "hold_to_attack", "selected_fighter", "celebration_style", "arcade_wins", "_bindings", "_controllers", "_active_devices"]
var settings
var game
var checks := 0
var failures: Array[String] = []
var original: Dictionary = {}
var original_config_exists := false
var original_config_bytes := PackedByteArray()

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)

func key_event(key: int, down: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = down
	Input.parse_input_event(event)

func pad_button(device: int, down: bool) -> void:
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_LEFT_SHOULDER
	event.pressed = down
	Input.parse_input_event(event)

func release_inputs() -> void:
	for action in settings.ACTIONS: Input.action_release(action)

func step_game(frames: int = 1) -> void:
	for frame in range(frames):
		await physics_frame
		game._physics_process(DT)

func tap_game(action: String) -> void:
	Input.action_press(action)
	await step_game()
	Input.action_release(action)

func wait_for_hit(expected_health: int, limit: int = 100) -> bool:
	for frame in range(limit):
		await step_game()
		if game.second.health == expected_health: return true
	return false

func run() -> void:
	await process_frame
	settings = root.get_node("Settings")
	original_config_exists = FileAccess.file_exists(CONFIG_PATH)
	if original_config_exists: original_config_bytes = FileAccess.get_file_as_bytes(CONFIG_PATH)
	for property in SAVED_PROPERTIES:
		var value = settings.get(property)
		original[property] = value.duplicate(true) if value is Array or value is Dictionary else value
	settings._controllers.assign([-1,-1])
	settings._active_devices.assign(["keyboard","keyboard"])
	settings._bindings = settings._default_bindings()
	settings._rebuild_input_map()
	settings.reduced_motion = true
	settings.hold_to_attack = false
	var packed = load("res://scenes/main.tscn")
	check(packed != null and packed.can_instantiate(), "main scene compiles with dodge controls")
	if packed == null or not packed.can_instantiate():
		await finish()
		return
	game = packed.instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	await process_frame
	await test_legacy_migration_and_saved_rebinds()
	await test_default_keyboard_and_controller_edges()
	await test_local_game_and_counter_arrow()
	await finish()

func test_legacy_migration_and_saved_rebinds() -> void:
	var legacy = ConfigFile.new()
	var prior = settings._default_bindings()
	prior["p1_attack"] = [KEY_E]
	prior["p2_attack"] = [KEY_J]
	for action in settings.ACTIONS:
		if action.ends_with("_dodge"): continue
		legacy.set_value("controls",action,prior[action])
	check(legacy.save(CONFIG_PATH) == OK, "isolated old settings fixture saves")
	settings._bindings = settings._default_bindings()
	settings._load_settings()
	settings._rebuild_input_map()
	check(settings._bindings["p1_attack"] == [KEY_E] and settings._bindings["p2_attack"] == [KEY_J], "old E/J attack choices survive adding dodge")
	check(settings._bindings["p1_dodge"] == [KEY_Q] and settings._bindings["p2_dodge"] == [KEY_U], "migration chooses unused dodge keys for each player")
	check(settings._bindings["p1_dodge"] != settings._bindings["p1_attack"] and settings._bindings["p2_dodge"] != settings._bindings["p2_attack"], "new dodge keys do not silently steal an old attack")
	game.open_settings()
	await process_frame
	var panel = game.ui.get_child(game.ui.get_child_count()-1)
	check(game.settings_open and is_instance_valid(panel) and root.gui_get_focus_owner().text == "Done", "expanded settings remains modal with Done focus")
	var rows_ok = panel._binding_buttons.size() == 13
	for slot in range(2):
		var prefix = "p%d_" % (slot+1)
		var previous_bottom := 0.0
		for suffix in ["move_left","move_right","jump","attack","special","dodge"]:
			var button: BaseButton = panel._binding_buttons.get(prefix+suffix)
			if not is_instance_valid(button):
				rows_ok = false
				continue
			var rect := Rect2(button.global_position,button.size)
			rows_ok = rows_ok and button.visible and button.focus_mode != Control.FOCUS_NONE and rect.position.y >= previous_bottom and rect.end.y <= 485.0
			previous_bottom = rect.end.y
			button.grab_focus()
			rows_ok = rows_ok and root.gui_get_focus_owner() == button
	check(rows_ok, "both six-row key lists fit above Pause and every binding accepts focus")
	panel._binding_buttons["p1_dodge"].pressed.emit()
	await process_frame
	key_event(KEY_T,true)
	await process_frame
	key_event(KEY_T,false)
	await process_frame
	check(settings._bindings["p1_dodge"] == [KEY_T] and panel._binding_buttons["p1_dodge"].text == "T", "player-one Dodge capture updates live label")
	panel._binding_buttons["p2_dodge"].pressed.emit()
	await process_frame
	key_event(KEY_H,true)
	await process_frame
	key_event(KEY_H,false)
	await process_frame
	check(settings._bindings["p2_dodge"] == [KEY_H] and panel._binding_buttons["p2_dodge"].text == "H", "player-two Dodge capture updates live label")
	var expected = settings._bindings.duplicate(true)
	settings._bindings = settings._default_bindings()
	settings._load_settings()
	settings._rebuild_input_map()
	check(settings._bindings == expected, "both Dodge rebinds and migrated attacks reload from saved settings")
	check(game._control_prompt(0).contains("E hit") and game._control_prompt(0).contains("T dodge") and game._control_prompt(1).contains("J hit") and game._control_prompt(1).contains("H dodge"), "each prompt reflects that player's saved hit and dodge keys")
	var file = ConfigFile.new()
	check(file.load(CONFIG_PATH) == OK and file.get_value("controls","p1_dodge") == [KEY_T] and file.get_value("controls","p2_dodge") == [KEY_H], "both Dodge rebinds persist in isolated settings file")
	panel._binding_buttons["p2_dodge"].grab_focus()
	check(root.gui_get_focus_owner() == panel._binding_buttons["p2_dodge"], "last control row remains keyboard reachable")
	panel._close()
	await process_frame
	check(not game.settings_open, "settings closes cleanly after expanded controls")
	print("PASS group: legacy E/J migration, six-row modal, both dodge captures and persisted prompts")

func test_default_keyboard_and_controller_edges() -> void:
	settings.reset_bindings()
	check(settings.binding_label("p1_dodge") == "E" and settings.binding_label("p2_dodge") == "J", "new default dodge keys are E and J")
	key_event(KEY_E,true)
	await physics_frame
	check(settings.read_player(0).dodge and not settings.read_player(1).dodge, "E dodge press reaches only player one")
	await physics_frame
	check(not settings.read_player(0).dodge, "held E does not retrigger dodge")
	key_event(KEY_E,false)
	await physics_frame
	key_event(KEY_J,true)
	await physics_frame
	check(settings.read_player(1).dodge and not settings.read_player(0).dodge, "J dodge press reaches only player two")
	await physics_frame
	check(not settings.read_player(1).dodge, "held J does not retrigger dodge")
	key_event(KEY_J,false)
	await physics_frame
	settings._controllers.assign([21,22])
	settings._active_devices.assign(["controller","controller"])
	settings._rebuild_input_map()
	check(game._control_prompt(0).contains("LB dodge") and game._control_prompt(1).contains("LB dodge"), "assigned controller prompts show left shoulder dodge")
	pad_button(21,true)
	await physics_frame
	check(settings.read_player(0).dodge and not settings.read_player(1).dodge, "player-one controller LB reaches only player one")
	await physics_frame
	check(not settings.read_player(0).dodge, "held player-one LB is edge-triggered")
	pad_button(21,false)
	await physics_frame
	pad_button(22,true)
	await physics_frame
	check(settings.read_player(1).dodge and not settings.read_player(0).dodge, "player-two controller LB reaches only player two")
	await physics_frame
	check(not settings.read_player(1).dodge, "held player-two LB is edge-triggered")
	pad_button(22,false)
	await physics_frame
	settings._controllers.assign([-1,-1])
	settings._active_devices.assign(["keyboard","keyboard"])
	settings._rebuild_input_map()
	print("PASS group: default E/J and independent controller LB edge commands")

func test_local_game_and_counter_arrow() -> void:
	release_inputs()
	game.mode = "local"
	game.selected = ["purple","red"]
	game.arena_kind = "desktop"
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0
	game.first.reset_at(Vector2(500,599))
	game.second.reset_at(Vector2(585,599))
	await process_frame
	await step_game(5)
	check(game.prompts[0].text.contains("E dodge") and game.prompts[1].text.contains("J dodge"), "local HUD displays independent dodge commands")
	var perfects: Array[int] = [0]
	var released: Array[String] = []
	game.first.perfect_dodged.connect(func(_fighter): perfects[0] += 1)
	game.first.released.connect(func(_fighter,kind): released.append(kind))
	check(game.second.start_attack(false), "incoming Red hammer begins its real windup")
	await step_game(10)
	await tap_game("p1_dodge")
	check(game.first.dodge_time >= 0 and game.second.dodge_time < 0, "local player-one input reaches Purple dodge only")
	for frame in range(20):
		await step_game()
		if perfects[0] > 0: break
	check(perfects[0] == 1 and game.first.health == 100 and game.first.counter_time > 0, "real Red hammer contact gives Purple one perfect dodge and timed counter")
	var ready_before_pause: float = game.first.counter_time
	game.pause_game()
	await step_game(25)
	check(is_equal_approx(game.first.counter_time,ready_before_pause), "counter timer freezes while match is paused")
	game.resume_game()
	while game.first.dodge_time >= 0: await step_game()
	check(game.first.counter_time < ready_before_pause and game.first.counter_time > 0, "counter timer resumes after pause")
	await tap_game("p1_special")
	check(game.first.is_special and not bool(game.first.attack_spec.get("counter",false)), "Purple signal special remains unboosted")
	check(await wait_for_hit(76), "signal projectile keeps its original 24 damage")
	check(game.first.counter_time > 0 and game.first.total_damage == 24, "signal hit does not consume counter reward")
	while game.first.attack_time >= 0 or game.second.invulnerable > 0: await step_game()
	await tap_game("p1_attack")
	check(not game.first.is_special and int(game.first.attack_spec.projectile_damage) == 15 and game.first.counter_time == 0, "next basic arrow consumes counter for 15 damage")
	check(await wait_for_hit(61), "one boosted arrow hits for exactly 15")
	while game.first.attack_time >= 0 or game.second.invulnerable > 0: await step_game()
	await tap_game("p1_attack")
	check(int(game.first.attack_spec.projectile_damage) == 12 and not bool(game.first.attack_spec.get("counter",false)), "following arrow returns to 12 damage")
	check(await wait_for_hit(49), "following ordinary arrow hits for exactly 12")
	check(released == ["signal","arrow","arrow"] and game.first.total_damage == 51 and perfects[0] == 1, "release kinds, single reward, and total projectile damage stay coherent")
	# An independent second-player press cannot restart Purple's dodge.
	while game.second.hurt_time > 0: await step_game()
	await tap_game("p2_dodge")
	check(game.second.dodge_time >= 0 and game.first.dodge_time < 0, "local player-two dodge reaches Red only")
	print("PASS group: local dodge, real perfect contact, pause-safe counter, unchanged signal, single boosted arrow")

func finish() -> void:
	paused = false
	release_inputs()
	if is_instance_valid(game): game.queue_free()
	await process_frame
	for property in SAVED_PROPERTIES: settings.set(property,original[property])
	settings._rebuild_input_map()
	root.get_node("Sound").apply_settings()
	if original_config_exists:
		var file = FileAccess.open(CONFIG_PATH,FileAccess.WRITE)
		file.store_buffer(original_config_bytes)
		file.close()
		check(FileAccess.get_file_as_bytes(CONFIG_PATH) == original_config_bytes, "isolated original settings bytes restored")
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
		check(not FileAccess.file_exists(CONFIG_PATH), "isolated original settings absence restored")
	var restored := true
	for property in SAVED_PROPERTIES: restored = restored and settings.get(property) == original[property]
	check(restored, "all Settings autoload values restored")
	root.get_node("Sound").shutdown()
	print("CONTROLS_DEPTH_TEST_RESULT checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("  "+failure)
	call_deferred("quit",0 if failures.is_empty() else 1)
