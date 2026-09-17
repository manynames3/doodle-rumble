extends Node
## Physical keyboard bindings and explicitly assigned, independent gamepads.

signal device_changed(slot: int, label: String)
signal controller_lost(slot: int)

const SAVE_PATH := "user://settings.cfg"
const ACTIONS := ["p1_move_left", "p1_move_right", "p1_jump", "p1_attack", "p1_special", "p1_dodge", "p2_move_left", "p2_move_right", "p2_jump", "p2_attack", "p2_special", "p2_dodge", "pause"]
const ACTION_NAMES := {
	"p1_move_left": "Player 1 left", "p1_move_right": "Player 1 right",
	"p1_jump": "Player 1 jump", "p1_attack": "Player 1 attack", "p1_special": "Player 1 special", "p1_dodge": "Player 1 dodge",
	"p2_move_left": "Player 2 left", "p2_move_right": "Player 2 right",
	"p2_jump": "Player 2 jump", "p2_attack": "Player 2 attack", "p2_special": "Player 2 special", "p2_dodge": "Player 2 dodge", "pause": "Pause"
}

var master_volume: float = 0.7
var music_volume: float = 0.2
var sfx_volume: float = 0.8
var reduced_motion: bool = false
var hold_to_attack: bool = true
var selected_fighter: String = "orange"
var celebration_style: String = "classic"
var arcade_wins: int = 0
var _bindings: Dictionary = {}
var _controllers: Array[int] = [-1, -1]
var _active_devices: Array[String] = ["keyboard", "keyboard"]


func _ready() -> void:
	# Automated native-app smoke tests must never load or save the family's profile.
	if "--isolated-qa" in OS.get_cmdline_user_args():
		ProjectSettings.set_setting("application/config/use_custom_user_dir",true)
		var profile_id := str(OS.get_process_id())
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--qa-profile="): profile_id = argument.trim_prefix("--qa-profile=").validate_filename()
		ProjectSettings.set_setting("application/config/custom_user_dir_name","DoodleRumbleQA/"+profile_id)
		DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bindings = _default_bindings()
	_load_settings()
	var connected := Input.get_connected_joypads()
	for slot in range(mini(connected.size(), 2)):
		_controllers[slot] = connected[slot]
	_rebuild_input_map()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _default_bindings() -> Dictionary:
	return {
		"p1_move_left": [KEY_A], "p1_move_right": [KEY_D], "p1_jump": [KEY_W, KEY_SPACE],
		"p1_attack": [KEY_F], "p1_special": [KEY_G], "p1_dodge": [KEY_E],
		"p2_move_left": [KEY_LEFT], "p2_move_right": [KEY_RIGHT], "p2_jump": [KEY_UP],
		"p2_attack": [KEY_K], "p2_special": [KEY_L], "p2_dodge": [KEY_J], "pause": [KEY_ESCAPE]
	}


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("play", "reduced_motion", reduced_motion)
	config.set_value("play", "hold_to_attack", hold_to_attack)
	config.set_value("play", "selected_fighter", selected_fighter)
	config.set_value("play", "celebration_style", celebration_style)
	config.set_value("play", "arcade_wins", arcade_wins)
	for action in ACTIONS:
		config.set_value("controls", action, _bindings[action])
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Settings could not be saved (%s). This session still works." % error)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", 0.7)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", 0.2)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 0.8)), 0.0, 1.0)
	reduced_motion = bool(config.get_value("play", "reduced_motion", false))
	hold_to_attack = bool(config.get_value("play", "hold_to_attack", true))
	selected_fighter = str(config.get_value("play", "selected_fighter", "orange"))
	arcade_wins = maxi(0, int(config.get_value("play", "arcade_wins", 0)))
	celebration_style = str(config.get_value("play", "celebration_style", "classic"))
	if celebration_style not in ["classic", "rainbow", "sparkle"] or arcade_wins == 0:
		celebration_style = "classic"
	if selected_fighter not in Data.ORDER:
		selected_fighter = "orange"
	# Validate the saved set together, so moving a key between actions survives reload.
	var candidate := _default_bindings()
	var seen: Dictionary = {}
	for action in ACTIONS:
		if action.ends_with("_dodge") and not config.has_section_key("controls",action):
			continue # Load the old bindings first, before choosing an unused new key.
		var saved: Variant = config.get_value("controls", action, candidate[action])
		if not saved is Array or saved.is_empty():
			return
		var keys: Array[int] = []
		for value in saved:
			if not value is int or value <= 0 or seen.has(value):
				return
			keys.append(value)
			seen[value] = true
		candidate[action] = keys
	for action in ["p1_dodge","p2_dodge"]:
		if config.has_section_key("controls",action): continue
		var choices = [KEY_E,KEY_Q,KEY_R,KEY_T,KEY_C,KEY_V,KEY_Z] if action == "p1_dodge" else [KEY_J,KEY_U,KEY_I,KEY_O,KEY_M,KEY_N,KEY_H]
		for key in choices:
			if not seen.has(key):
				candidate[action] = [key]
				seen[key] = true
				break
	_bindings = candidate


func reset_bindings() -> void:
	_bindings = _default_bindings()
	_rebuild_input_map()
	save_settings()
	for slot in range(2):
		device_changed.emit(slot, device_label(slot))


func rebind(action: String, keycode: int) -> String:
	if not ACTIONS.has(action):
		return "That control cannot be changed."
	if keycode <= 0 or keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]:
		return "Choose a letter, number, arrow, or another ordinary key."
	if keycode == KEY_F11:
		return "F11 is reserved for switching fullscreen. Choose a different key."
	if action != "pause" and keycode == KEY_ESCAPE:
		return "Escape is reserved for pause and closing menus."
	for other in ACTIONS:
		if other != action and _bindings[other].has(keycode):
			return "%s already uses %s. Choose a different key." % [ACTION_NAMES[other], _key_label(keycode)]
	_bindings[action] = [keycode]
	_rebuild_input_map()
	save_settings()
	for slot in range(2):
		device_changed.emit(slot, device_label(slot))
	return ""


func binding_label(action: String) -> String:
	var labels: PackedStringArray = []
	for key in _bindings.get(action, []):
		labels.append(_key_label(int(key)))
	return " / ".join(labels)


func _key_label(keycode: int) -> String:
	if keycode == KEY_ESCAPE:
		return "Esc"
	if DisplayServer.get_name() == "headless":
		return OS.get_keycode_string(keycode)
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(keycode))


func read_player(slot: int) -> Dictionary:
	var prefix := "p%d_" % (clampi(slot, 0, 1) + 1)
	return {
		"move": Input.get_axis(prefix + "move_left", prefix + "move_right"),
		"jump": Input.is_action_just_pressed(prefix + "jump"),
		"attack": Input.is_action_pressed(prefix + "attack") if hold_to_attack else Input.is_action_just_pressed(prefix + "attack"),
		"special": Input.is_action_just_pressed(prefix + "special"),
		"dodge": Input.is_action_just_pressed(prefix + "dodge")
	}


func device_label(slot: int) -> String:
	if slot < 0 or slot > 1:
		return "Keyboard"
	if _active_devices[slot] == "controller" and _controllers[slot] >= 0:
		return "Controller %d" % (_controllers[slot] + 1)
	return "Keyboard"


func controller_for(slot: int) -> int:
	return _controllers[slot] if slot >= 0 and slot < 2 else -1


func assign_controller(slot: int, device: int) -> void:
	if slot < 0 or slot > 1:
		return
	if device >= 0 and not Input.get_connected_joypads().has(device):
		return
	for other in range(2):
		if other != slot and _controllers[other] == device and device >= 0:
			_controllers[other] = -1
			_active_devices[other] = "keyboard"
			device_changed.emit(other, device_label(other))
	_controllers[slot] = device
	_active_devices[slot] = "controller" if device >= 0 else "keyboard"
	_rebuild_input_map()
	device_changed.emit(slot, device_label(slot))


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		for slot in range(2):
			if _controllers[slot] < 0:
				assign_controller(slot, device)
				return
	else:
		for slot in range(2):
			if _controllers[slot] == device:
				_controllers[slot] = -1
				_active_devices[slot] = "keyboard"
				_rebuild_input_map()
				device_changed.emit(slot, device_label(slot))
				controller_lost.emit(slot)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		for slot in range(2):
			var prefix := "p%d_" % (slot + 1)
			for action in ACTIONS:
				if action.begins_with(prefix) and _bindings[action].has(event.physical_keycode):
					_set_active_device(slot, "keyboard")
	elif (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		for slot in range(2):
			if event.device == _controllers[slot]:
				_set_active_device(slot, "controller")


func _set_active_device(slot: int, device_type: String) -> void:
	if _active_devices[slot] != device_type:
		_active_devices[slot] = device_type
		device_changed.emit(slot, device_label(slot))


func _rebuild_input_map() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		InputMap.action_set_deadzone(action, 0.25)
		InputMap.action_erase_events(action)
		for key in _bindings[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = key
			InputMap.action_add_event(action, key_event)
	for slot in range(2):
		var device := _controllers[slot]
		if device < 0:
			continue
		var prefix := "p%d_" % (slot + 1)
		_add_pad_button(prefix + "move_left", device, JOY_BUTTON_DPAD_LEFT)
		_add_pad_button(prefix + "move_right", device, JOY_BUTTON_DPAD_RIGHT)
		_add_pad_button(prefix + "jump", device, JOY_BUTTON_A)
		_add_pad_button(prefix + "attack", device, JOY_BUTTON_X)
		_add_pad_button(prefix + "special", device, JOY_BUTTON_B)
		_add_pad_button(prefix + "dodge", device, JOY_BUTTON_LEFT_SHOULDER)
		_add_pad_button("pause", device, JOY_BUTTON_START)
		for direction in [-1, 1]:
			var motion := InputEventJoypadMotion.new()
			motion.device = device
			motion.axis = JOY_AXIS_LEFT_X
			motion.axis_value = float(direction)
			InputMap.action_add_event(prefix + ("move_left" if direction < 0 else "move_right"), motion)


func _add_pad_button(action: String, device: int, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	InputMap.action_add_event(action, event)
