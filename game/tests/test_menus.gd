extends SceneTree
## Scene-level menu regression tests. No native UI automation or combat simulation.
## Run: Godot --headless --fixed-fps 60 --path game --script res://tests/test_menus.gd
const DT = 1.0 / 60.0
const CONFIG_PATH = "user://settings.cfg"
const SAVED_PROPERTIES = ["master_volume", "music_volume", "sfx_volume", "reduced_motion", "hold_to_attack", "selected_fighter", "celebration_style", "arcade_wins", "_bindings", "_controllers", "_active_devices"]
var game
var settings
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

func all_buttons(node: Node) -> Array[BaseButton]:
	var found: Array[BaseButton] = []
	if node is BaseButton: found.append(node)
	for child in node.get_children(): found.append_array(all_buttons(child))
	return found

func button(caption: String, parent: Node = null) -> BaseButton:
	for candidate in all_buttons(game.ui if parent == null else parent):
		if candidate.text == caption: return candidate
	return null

func press(caption: String, parent: Node = null) -> bool:
	var control = button(caption, parent)
	check(is_instance_valid(control), "visible button exists: " + caption)
	if not is_instance_valid(control): return false
	control.pressed.emit()
	return true

func fighter_card(id: String) -> BaseButton:
	var name_text: String = root.get_node("Data").fighter(id).name
	for candidate in all_buttons(game.ui):
		if candidate.text != "": continue
		for child in candidate.get_children():
			if child is Label and child.text.to_lower().begins_with(name_text.to_lower()): return candidate
	return null

func choose(id: String) -> void:
	var card = fighter_card(id)
	check(is_instance_valid(card), id + " is available as a selectable card")
	if card: card.pressed.emit()
	await process_frame

func focus_is(caption: String) -> bool:
	var owner = root.gui_get_focus_owner()
	return owner is BaseButton and owner.text == caption

func physical_key(key: int, down: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = down
	Input.parse_input_event(event)

func tap_key(key: int) -> void:
	physical_key(key, true)
	await process_frame
	physical_key(key, false)
	await process_frame

func tap_action(action: String) -> void:
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	await process_frame # Main depends on Data and Settings autoload initialization.
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
	settings.selected_fighter = "green"
	settings.reduced_motion = true
	settings.hold_to_attack = true
	var packed = load("res://scenes/main.tscn")
	check(packed != null and packed.can_instantiate(), "main scene compiles after autoloads")
	if packed == null or not packed.can_instantiate():
		await finish()
		return
	game = packed.instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	await process_frame
	await test_title_and_selection()
	await test_settings_modality()
	await test_key_capture_and_persistence()
	await test_comfort_and_prompts()
	await test_result_navigation()
	await finish()

func test_title_and_selection() -> void:
	check(game.state == "title" and focus_is("Story Mode"), "title opens with Story Mode keyboard focus")
	check(all_buttons(game.ui).map(func(b): return b.text) == ["Story Mode","Quick Match","2P Battle","Doodle Rally","Settings","Quit"],"title has exactly the six requested choices")
	check(all_buttons(game.ui).all(func(b): return b.global_position.y >= 660),"title choices leave poster character descriptions unobscured")
	check(game.selected == ["green", "blue"], "title restores saved player fighter and default opponent")
	await tap_action("ui_accept")
	check(game.state == "journal", "Story Mode opens the saved story journal")
	press("New journey  >")
	await process_frame
	check(game.state=="select" and game.mode=="arcade", "New journey offers fighter selection")
	check(game.difficulty_level == 0, "new game defaults to the existing Easy balance")
	press("Spicy Scribbles · Medium")
	await process_frame
	press("LET'S RUMBLE  >")
	await process_frame
	check(game.first.definition.id == "green" and game.second.definition.id == "blue", "title Play instantiates saved fighter against first opponent Blue")
	check(game.ai.difficulty_level == 1 and root.get_node("Chronicle").difficulty_level == 1, "story level configures AI and is checkpointed")
	game.show_story_hub()
	game.difficulty_level = 0
	game.resume_story()
	check(game.difficulty_level == 1 and game.state == "select", "Continue Story restores its selected level")
	game.show_title()
	await process_frame
	press("Story Mode")
	await process_frame
	press("New journey")
	await process_frame
	check(game.state == "select" and game.mode == "arcade" and game.arcade_stage == 0 and focus_is("LET'S RUMBLE  >"), "title fighter selection opens a fresh journey with start focus")
	for id in ["orange", "red", "green", "blue", "purple", "yellow"]:
		await choose(id)
		check(game.selected[0] == id and settings.selected_fighter == id, id + " card selects and persists player one")
	await choose("blue") # Keep the existing quick-match/opponent isolation checks stable.
	check(button("Opponent: Blue") == null and game.selecting_player == 0, "journey selection keeps its ordered opponent automatic")
	press("Back")
	await process_frame
	press("Quick Match")
	await process_frame
	check(game.mode == "solo" and button("Opponent: Blue") != null,"Quick match retains freely selectable easy opponents")
	press("Opponent: Blue")
	await process_frame
	await choose("red")
	check(game.selected == ["blue", "red"] and settings.selected_fighter == "blue", "opponent selector changes only opponent")
	press("Doodle Mayhem · Hard")
	await process_frame
	check(game.difficulty_level == 2, "Quick Match selects the hard AI pace")
	check(button("Block Quarry") == null, "fighter choice no longer squeezes in arena thumbnails")
	press("Choose stage  >")
	await process_frame
	check(game.state == "stage_select" and game.mode == "solo", "Quick Match has a separate stage page")
	press("Block Quarry")
	await process_frame
	press("LET'S RUMBLE  >")
	await process_frame
	check(game.first.definition.id == "blue" and game.second.definition.id == "red" and game.arena_kind == "quarry", "selection start uses selected fighters and arena")
	check(game.ai.difficulty_level == 2 and game.rules.remaining == 60, "chosen difficulty reaches live opponent and timer starts at 60")
	game.show_title()
	await process_frame
	press("2P Battle")
	await process_frame
	press("Player 2: Red")
	await process_frame
	await choose("green")
	press("Player 1: Blue")
	await process_frame
	await choose("orange")
	press("Choose stage  >")
	await process_frame
	check(game.state == "stage_select" and game.mode == "local", "2P battle also uses the large stage page")
	press("Paper Canopy")
	await tap_key(KEY_ESCAPE)
	check(game.state == "select" and game.selected == ["orange","green"] and game.arena_kind == "canopy", "stage Back preserves both fighters and chosen arena")
	press("Choose stage  >")
	await process_frame
	press("LET'S RUMBLE  >")
	await process_frame
	check(game.mode == "local" and game.first.definition.id == "orange" and game.second.definition.id == "green", "local selectors feed independent player slots")
	check(game._combat_difficulty() == 0, "2P does not inherit hidden hard AI/hazard settings")
	check(game.prompts[0].text.begins_with("P1") and game.prompts[1].text.begins_with("P2"), "local HUD identifies both playable controls")
	game.show_title()
	await process_frame
	check(button("Training") == null and button("PLAY  >") == null and button("Choose fighters") == null,"title contains only the requested six options")
	game.open_selection("training")
	await process_frame
	check(game.mode == "training" and button("Opponent: Green") != null, "training selection exposes practice opponent")
	press("Back")
	await process_frame
	check(game.state == "title" and focus_is("Story Mode"), "selection Back restores title and Play focus")
	press("Story Mode")
	await process_frame
	press("New journey")
	await process_frame
	check(game.mode == "arcade" and game.arcade_stage == 0 and game.selecting_player == 0 and button("Opponent: Green") == null, "new journey selection resets stage and keeps opponent roster automatic")
	await tap_key(KEY_ESCAPE)
	check(game.state == "title", "Escape backs out of fighter selection")
	print("PASS group: title journey, six fighters, retained quick-match/local selectors, menu return")

func test_settings_modality() -> void:
	for screen in ["title", "select", "stage_select", "paused"]:
		if screen == "title": game.show_title()
		elif screen == "select": game.open_selection("solo")
		elif screen == "stage_select": game.open_selection("solo"); game.open_stage_selection()
		else:
			game.start_match()
			game.pause_game()
		await process_frame
		var was_paused: bool = paused
		var previous: Array[BaseButton] = all_buttons(game.ui)
		game.open_settings()
		await process_frame
		var panel = game.ui.get_child(game.ui.get_child_count() - 1)
		check(game.settings_open and focus_is("Done"), screen + " settings opens with Done focus")
		var isolated = true
		for control in previous: isolated = isolated and control.focus_mode == Control.FOCUS_NONE
		check(isolated, screen + " background controls are excluded from keyboard focus")
		var focused: Control = root.gui_get_focus_owner()
		var traversal_inside = true
		for i in range(50):
			focused = focused.find_next_valid_focus()
			traversal_inside = traversal_inside and panel.is_ancestor_of(focused)
		check(traversal_inside, screen + " Tab traversal remains inside settings for multiple loops")
		await tap_action("ui_accept")
		check(not game.settings_open and game.state == screen, screen + " Done closes settings without activating background")
		check(paused == was_paused, screen + " settings preserves underlying pause state")
		check(focus_is("Keep playing  >" if screen == "paused" else "Story Mode" if screen == "title" else "Choose stage  >" if screen == "select" else "LET'S RUMBLE  >"), screen + " close rebuilds parent with its primary focus")
		game.open_settings()
		await process_frame
		await tap_key(KEY_ESCAPE)
		check(not game.settings_open and game.state == screen and paused == was_paused, screen + " Escape closes only settings")
	check(game.state == "paused" and paused, "settings close leaves battle frozen")
	await tap_action("ui_accept")
	check(game.state == "playing" and not paused, "restored Keep playing focus resumes normally")
	print("PASS group: modal focus isolation, Done/Escape close, pause state restoration")

func test_key_capture_and_persistence() -> void:
	game.show_title()
	game.open_settings()
	await process_frame
	var panel = game.ui.get_child(game.ui.get_child_count() - 1)
	panel._binding_buttons["p1_attack"].pressed.emit()
	await tap_key(KEY_K)
	check(panel._capture_action == "p1_attack" and panel._message.text.contains("already uses"), "capture rejects a key used by player two with visible conflict")
	check(settings.binding_label("p1_attack") == "F" and settings.binding_label("p2_attack") == "K", "conflict leaves both bindings intact")
	await tap_key(KEY_F11)
	check(panel._capture_action == "p1_attack" and panel._message.text.contains("reserved"), "capture reserves F11 for fullscreen")
	await tap_key(KEY_SHIFT)
	check(panel._capture_action == "p1_attack" and panel._message.text.contains("ordinary key"), "capture rejects a bare modifier")
	await tap_key(KEY_ESCAPE)
	check(panel._capture_action == "" and game.settings_open and settings.binding_label("p1_attack") == "F", "Escape cancels capture while keeping settings open")
	panel._binding_buttons["p1_attack"].pressed.emit()
	await tap_key(KEY_H)
	check(panel._capture_action == "" and panel._binding_buttons["p1_attack"].text == "H", "new attack key applies to capture button immediately")
	check(InputMap.action_has_event("p1_attack", key_event(KEY_H)) and not InputMap.action_has_event("p1_attack", key_event(KEY_F)), "successful remap replaces live physical input map")
	panel._binding_buttons["p2_attack"].pressed.emit()
	await tap_key(KEY_F)
	check(settings.binding_label("p2_attack") == "F", "freed player-one key can be reassigned to player two")
	panel._binding_buttons["pause"].pressed.emit()
	await tap_key(KEY_P)
	check(settings.binding_label("pause") == "P", "pause can be remapped")
	await tap_key(KEY_ESCAPE)
	check(not game.settings_open and game.state == "title", "Escape remains a menu-close fallback after pause remap")
	game.open_selection("solo")
	game.open_stage_selection()
	await tap_key(KEY_ESCAPE)
	check(game.state == "select", "Escape still returns from stages after Pause is remapped")
	game.show_title()
	var expected: Dictionary = settings._bindings.duplicate(true)
	settings._bindings = settings._default_bindings()
	settings._load_settings()
	settings._rebuild_input_map()
	check(settings._bindings == expected, "saved key migration between players survives complete binding reload")
	var config = ConfigFile.new()
	check(config.load(CONFIG_PATH) == OK and config.get_value("controls", "p1_attack") == [KEY_H] and config.get_value("controls", "p2_attack") == [KEY_F], "settings file stores actual remaps")
	game._process(DT)
	check(game._control_prompt(0).contains("H hit"), "gameplay control prompt reflects remapped attack")
	game.open_settings()
	await process_frame
	panel = game.ui.get_child(game.ui.get_child_count() - 1)
	press("Reset keys", panel)
	check(settings._bindings == settings._default_bindings() and panel._binding_buttons["pause"].text == "Esc", "Reset keys restores defaults and panel labels")
	press("Done", panel)
	await process_frame
	print("PASS group: remap conflicts, reserved keys, cancel/reset, persistence and labels")

func key_event(key: int) -> InputEventKey:
	var event = InputEventKey.new()
	event.physical_keycode = key
	return event

func test_comfort_and_prompts() -> void:
	settings.reduced_motion = false
	settings.hold_to_attack = true
	game.mode = "local"
	game.start_match()
	game.pause_game()
	game.open_settings()
	await process_frame
	var panel = game.ui.get_child(game.ui.get_child_count() - 1)
	var reduced: CheckBox = button("Reduced motion", panel)
	var hold: CheckBox = button("Hold attack to repeat", panel)
	reduced.button_pressed = true
	hold.button_pressed = false
	press("Done", panel)
	await process_frame
	game._process(DT)
	check(settings.reduced_motion and not settings.hold_to_attack, "comfort checkboxes update actual saved gameplay settings")
	check(game.arena.reduced_motion and game.juice.reduced_motion and game.first.reduced_motion and game.second.reduced_motion, "reduced motion reaches arena, effects and both fighters")
	game.resume_game()
	game.shake = 5
	game._process(DT)
	check(game.camera.offset == Vector2.ZERO, "reduced motion suppresses camera shake")
	game._update_hud()
	check(game.hint_label.text.begins_with("Press attack"), "HUD explains press behavior when hold attack is disabled")
	settings.hold_to_attack = true
	game._update_hud()
	check(game.hint_label.text.begins_with("Hold attack"), "HUD explains repeated attack when hold is enabled")
	settings.rebind("p2_special", KEY_I)
	game._update_hud()
	check(game.prompts[1].text.contains("I special") and game.prompts[0].text.contains("G special"), "local HUD prompts update only the corresponding remapped player")
	settings._controllers[1] = 7
	settings._active_devices[1] = "controller"
	game._update_hud()
	check(game.prompts[1].text.contains("Stick / D-pad") and game.prompts[0].text.contains("A/D"), "device prompts distinguish player-two controller from player-one keyboard")
	settings._controllers[1] = -1
	settings._active_devices[1] = "keyboard"
	settings.reset_bindings()
	game.open_selection("solo")
	await process_frame
	var previews_reduced = true
	var preview_count = 0
	for candidate in all_buttons(game.ui):
		for child in candidate.get_children():
			if child.is_in_group("selection_cards"):
				preview_count += 1
				var before = child.elapsed
				child._process(0.25)
				previews_reduced = previews_reduced and is_equal_approx(child.elapsed,before) and child.texture != null
	check(preview_count == 6 and previews_reduced, "all six illustrated action cards load artwork and freeze motion with reduced motion")
	print("PASS group: comfort settings, camera motion and player-specific control prompts")

func result_focus(primary: String) -> void:
	check(focus_is(primary), primary + " receives initial result focus")
	var focused: Control = root.gui_get_focus_owner()
	var next: Control = focused.find_next_valid_focus()
	check(next is BaseButton and next.text == "Change fighters", primary + " reaches Change fighters with forward focus navigation")
	next.grab_focus()
	var previous: Control = next.find_prev_valid_focus()
	check(previous is BaseButton and previous.text == primary, "reverse focus returns to " + primary)
	previous.grab_focus()

func test_result_navigation() -> void:
	game.mode = "local"
	game.start_match()
	game.rules.tick(DT, 100, 0)
	game._finish_round()
	await process_frame
	result_focus("Next round  >")
	await tap_action("ui_accept")
	check(game.state == "playing" and game.rules.round_number == 2, "focused Next round accepts keyboard activation")
	game.rules.tick(DT, 100, 0)
	game._finish_round()
	await process_frame
	result_focus("Rematch  >")
	await tap_action("ui_accept")
	check(game.state == "playing" and game.rules.scores == [0, 0], "focused Rematch accepts keyboard activation")
	game.start_arcade()
	game.rules.scores = [2, 0]
	game.rules.last_winner = 0
	game.rules.finished = true
	game._finish_round()
	await process_frame
	result_focus("Next match  >")
	await tap_action("ui_accept")
	check(game.arcade_stage == 1 and game.selected[1] == "red", "focused journey Next match advances Blue to Red")
	# Earn the next stage, then change fighters before continuing.
	game.rules.scores = [2, 0]
	game.rules.last_winner = 0
	game.rules.finished = true
	game._finish_round()
	await process_frame
	press("Change fighters")
	await process_frame
	check(game.state == "select" and game.arcade_stage == 1 and game.journey_stage_won,"changing fighters after a win retains the earned stage and its result")
	await choose("blue")
	press("LET'S RUMBLE  >")
	await process_frame
	check(game.arcade_stage == 2 and game.first.definition.id == "blue" and game.second.definition.id == "green","starting after a fighter change continues to the next earned journey opponent")
	# A loss exposes Retry and changing fighters must retry that same earned stage.
	game.rules.scores = [0, 2]
	game.rules.last_winner = 1
	game.rules.finished = true
	game._finish_round()
	await process_frame
	result_focus("Retry stage  >")
	await tap_action("ui_accept")
	check(game.arcade_stage == 2 and game.selected[1] == "green" and game.rules.scores == [0,0],"focused journey Retry preserves stage and resets scores")
	game.rules.scores = [0, 2]
	game.rules.last_winner = 1
	game.rules.finished = true
	game._finish_round()
	await process_frame
	press("Change fighters")
	await process_frame
	check(game.arcade_stage == 2 and not game.journey_stage_won,"fighter selection after a loss preserves current stage without earning a skip")
	await choose("red")
	press("LET'S RUMBLE  >")
	await process_frame
	check(game.arcade_stage == 2 and game.first.definition.id == "red" and game.second.definition.id == "green","changed fighter retries Green without restarting or skipping the journey")
	game.arcade_stage = 3
	game.start_match()
	game.rules.scores = [2, 0]
	game.rules.last_winner = 0
	game.rules.finished = true
	game._finish_round()
	await process_frame
	result_focus("Next match  >")
	await tap_action("ui_accept")
	check(game.arcade_stage == 4 and game.second.definition.id == "h4ck3r","Pac-Man result continues to H4CK3R")
	game.rules.scores = [2,0]
	game.rules.last_winner = 0
	game.rules.finished = true
	game._finish_round()
	await process_frame
	press("Next match  >")
	check(game.arcade_stage == 5 and game.second.definition.id == "dark_lord","H4CK3R result continues to final Dark lord")
	game.start_match()
	game.rules.scores = [2, 0]
	game.rules.last_winner = 0
	game.rules.finished = true
	game._finish_round()
	await process_frame
	result_focus("New journey  >")
	await tap_action("ui_accept")
	check(game.arcade_stage == 0 and game.state == "select" and not game.journey_rewarded, "focused New journey returns to fighter choice at chapter one")
	press("LET'S RUMBLE  >")
	await process_frame
	check(game.state=="playing" and game.second.definition.id=="blue", "new journey starts against Blue")
	print("PASS group: result focus, journey continuation, retries, fighter changes and final restart")

func finish() -> void:
	paused = false
	for action in settings.ACTIONS: Input.action_release(action)
	for action in ["ui_accept", "ui_focus_next", "ui_focus_prev"]: Input.action_release(action)
	if is_instance_valid(game): game.queue_free()
	await process_frame
	for property in SAVED_PROPERTIES: settings.set(property, original[property])
	settings._rebuild_input_map()
	root.get_node("Sound").apply_settings()
	if config_existed:
		var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
		file.store_buffer(config_bytes)
		file.close()
		check(FileAccess.get_file_as_bytes(CONFIG_PATH) == config_bytes, "test restores original settings file byte-for-byte")
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
		check(not FileAccess.file_exists(CONFIG_PATH), "test restores absent original settings file")
	var restored = true
	for property in SAVED_PROPERTIES: restored = restored and settings.get(property) == original[property]
	check(restored, "test restores every changed Settings autoload value")
	root.get_node("Sound").shutdown()
	print("MENU_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: print("  " + failure)
	call_deferred("quit", 0 if failures.is_empty() else 1)
