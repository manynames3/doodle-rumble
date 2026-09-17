extends Control
## Self-contained modal. open_panel(callback) closes/frees itself before callback.

const INK := Color("1d3046")
const CREAM := Color("fffaf0")
const PALE := Color("dceaf3")
const ORANGE := Color("f59736")
const MUTED := Color("667789")
const CONTROL_ROWS := [["move_left", "Move left"], ["move_right", "Move right"], ["jump", "Jump"], ["attack", "Attack"], ["special", "Special"], ["dodge", "Dodge"]]

var _on_close: Callable
var _binding_buttons: Dictionary = {}
var _controller_options: Array[OptionButton] = []
var _controller_ids: Array[int] = []
var _capture_action: String = ""
var _message: Label
var _closed: bool = false
var _cosmetics: OptionButton
var _background_focus: Array[Dictionary] = []
var _previous_focus: WeakRef


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	Input.joy_connection_changed.connect(_on_controller_connection)


func open_panel(on_close: Callable) -> void:
	_on_close = on_close
	_closed = false
	var focused := get_viewport().gui_get_focus_owner()
	_previous_focus = weakref(focused) if focused != null else null
	_block_background_focus(get_parent())
	_build()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_binding_buttons.clear()
	_controller_options.clear()
	var shade := ColorRect.new()
	shade.color = Color(0.07, 0.12, 0.19, 0.76)
	shade.position = Vector2.ZERO
	shade.size = Vector2(1280, 720)
	add_child(shade)
	var paper := Panel.new()
	paper.position = Vector2(85, 25)
	paper.size = Vector2(1110, 670)
	paper.add_theme_stylebox_override("panel", _box(CREAM, 24, 3))
	add_child(paper)
	_label("MAKE IT YOURS", Vector2(120, 48), Vector2(760, 20), 13, MUTED)
	_label("Settings", Vector2(119, 72), Vector2(780, 45), 35)
	_label("A few little tweaks for your perfect rumble.", Vector2(122, 120), Vector2(850, 25), 16, MUTED)
	var done := _button("Done", Vector2(1050, 73), Vector2(108, 44), _close, true)
	var line := ColorRect.new()
	line.color = PALE
	line.position = Vector2(516, 168)
	line.size = Vector2(2, 426)
	add_child(line)
	_label("Sound & comfort", Vector2(121, 164), Vector2(350, 32), 23)
	_volume("Master", "master_volume", 210)
	_volume("Music", "music_volume", 270)
	_volume("Sound effects", "sfx_volume", 330)
	_checkbox("Reduced motion", Settings.reduced_motion, Vector2(117, 390), func(value: bool):
		Settings.reduced_motion = value
		_settings_changed())
	_checkbox("Hold attack to repeat", Settings.hold_to_attack, Vector2(117, 430), func(value: bool):
		Settings.hold_to_attack = value
		_settings_changed())
	_label("Victory confetti", Vector2(122, 484), Vector2(300, 23), 17)
	_cosmetics = OptionButton.new()
	_cosmetics.position = Vector2(122, 514)
	_cosmetics.size = Vector2(346, 38)
	_style_option(_cosmetics)
	for caption in ["Classic", "Rainbow", "Sparkle"]:
		_cosmetics.add_item(caption)
	var unlocked: bool = Settings.arcade_wins > 0
	_cosmetics.set_item_disabled(1, not unlocked)
	_cosmetics.set_item_disabled(2, not unlocked)
	_cosmetics.select(["classic", "rainbow", "sparkle"].find(Settings.celebration_style))
	_cosmetics.item_selected.connect(func(index: int):
		Settings.celebration_style = ["classic", "rainbow", "sparkle"][index]
		_settings_changed())
	add_child(_cosmetics)
	_label("Unlocked! Pick your celebration." if unlocked else "Finish Story Mode to unlock Rainbow & Sparkle.", Vector2(122, 560), Vector2(366, 34), 13, MUTED)
	_label("Keyboard controls", Vector2(548, 164), Vector2(580, 32), 23)
	_label("Click a key, then press its replacement.", Vector2(550, 200), Vector2(585, 24), 14, MUTED)
	for slot in range(2):
		var x: float = 550 + slot * 307
		_label("PLAYER %d" % (slot + 1), Vector2(x, 237), Vector2(275, 22), 14, MUTED)
		for row in range(CONTROL_ROWS.size()):
			var action := "p%d_%s" % [slot + 1, CONTROL_ROWS[row][0]]
			var y: float = 266 + row * 35
			_label(CONTROL_ROWS[row][1], Vector2(x, y + 7), Vector2(140, 25), 16)
			var button := _button(Settings.binding_label(action), Vector2(x + 143, y), Vector2(117, 34), func(): _begin_capture(action))
			_binding_buttons[action] = button
	_label("Pause", Vector2(550, 492), Vector2(138, 25), 16)
	_binding_buttons["pause"] = _button(Settings.binding_label("pause"), Vector2(693, 486), Vector2(117, 34), func(): _begin_capture("pause"))
	_button("Reset keys", Vector2(857, 486), Vector2(260, 34), func():
		_capture_action = ""
		Settings.reset_bindings()
		_refresh_bindings()
		_feedback("Original keyboard controls restored.")
		Sound.play("ui"))
	_message = _label("Escape cancels a key change. Every fighter uses the same controls.", Vector2(550, 527), Vector2(570, 47), 13, MUTED)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Controllers", Vector2(122, 606), Vector2(148, 27), 19)
	for slot in range(2):
		var option := OptionButton.new()
		option.position = Vector2(281 + slot * 329, 599)
		option.size = Vector2(305, 37)
		_style_option(option)
		option.item_selected.connect(func(index: int):
			Settings.assign_controller(slot, _controller_ids[index])
			_refresh_controllers()
			Sound.play("ui"))
		add_child(option)
		_controller_options.append(option)
	_refresh_controllers()
	_label("Gamepad: left stick / D-pad move · Bottom button jump · Left button attack · Right button special · Left shoulder dodge · Start pause", Vector2(122, 653), Vector2(1039, 26), 12, MUTED)
	done.grab_focus()


func _block_background_focus(node: Node) -> void:
	# The backdrop blocks pointers; this also keeps Tab and gamepad navigation modal.
	if node == self:
		return
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		_background_focus.append({"control": weakref(node), "mode": node.focus_mode})
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_block_background_focus(child)


func _restore_background_focus() -> void:
	for saved in _background_focus:
		var control: Variant = saved.control.get_ref()
		if is_instance_valid(control):
			control.focus_mode = saved.mode
	_background_focus.clear()


func _exit_tree() -> void:
	_restore_background_focus()


func _volume(caption: String, property: String, y: float) -> void:
	_label(caption, Vector2(122, y), Vector2(240, 24), 16)
	var value: float = Settings.get(property)
	var percentage := _label("%d%%" % roundi(value * 100), Vector2(407, y), Vector2(61, 24), 15, MUTED)
	percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var slider := HSlider.new()
	slider.position = Vector2(122, y + 24)
	slider.size = Vector2(346, 25)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.add_theme_stylebox_override("slider", _slider_track(PALE))
	slider.add_theme_stylebox_override("grabber_area", _slider_track(ORANGE))
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_track(ORANGE.lightened(0.12)))
	var thumb := _icon('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><circle cx="10" cy="10" r="8" fill="#f59736" stroke="#1d3046" stroke-width="2"/></svg>')
	slider.add_theme_icon_override("grabber", thumb)
	slider.add_theme_icon_override("grabber_highlight", thumb)
	slider.value_changed.connect(func(amount: float):
		Settings.set(property, amount)
		percentage.text = "%d%%" % roundi(amount * 100)
		_settings_changed(false))
	slider.drag_ended.connect(func(_changed: bool): Settings.save_settings())
	add_child(slider)


func _checkbox(caption: String, value: bool, where: Vector2, callback: Callable) -> CheckBox:
	var control := CheckBox.new()
	control.text = caption
	control.position = where
	control.size = Vector2(363, 38)
	control.button_pressed = value
	control.add_theme_color_override("font_color", INK)
	control.add_theme_color_override("font_hover_color", INK)
	control.add_theme_color_override("font_pressed_color", INK)
	control.add_theme_font_size_override("font_size", 17)
	control.add_theme_icon_override("unchecked", _icon('<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22"><rect x="2" y="2" width="18" height="18" rx="4" fill="#dceaf3" stroke="#1d3046" stroke-width="2"/></svg>'))
	control.add_theme_icon_override("checked", _icon('<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22"><rect x="2" y="2" width="18" height="18" rx="4" fill="#f59736" stroke="#1d3046" stroke-width="2"/><path d="M6 11 L10 15 L16 7" stroke="#1d3046" stroke-width="2.4" fill="none"/></svg>'))
	control.toggled.connect(callback)
	add_child(control)
	return control


func _settings_changed(save: bool = true) -> void:
	Sound.apply_settings()
	if save:
		Settings.save_settings()


func _begin_capture(action: String) -> void:
	_capture_action = action
	_refresh_bindings()
	_binding_buttons[action].text = "Press key…"
	_feedback("Press a new key for %s. %s" % [Settings.ACTION_NAMES[action], "Escape restores Esc." if action == "pause" else "Escape cancels."])
	Sound.play("ui")


func _input(event: InputEvent) -> void:
	if _closed:
		return
	if not _capture_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if key == KEY_ESCAPE and _capture_action != "pause":
				_capture_action = ""
				_refresh_bindings()
				_feedback("Key change canceled.")
				return
			var action := _capture_action
			var error: String = Settings.rebind(action, key)
			if not error.is_empty():
				_feedback(error, true)
				return
			_capture_action = ""
			_refresh_bindings()
			_feedback("%s now uses %s." % [Settings.ACTION_NAMES[action], Settings.binding_label(action)])
			Sound.play("ui")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


func _refresh_bindings() -> void:
	for action in _binding_buttons:
		_binding_buttons[action].text = Settings.binding_label(action)


func _feedback(message: String, error: bool = false) -> void:
	_message.text = message
	_message.add_theme_color_override("font_color", Color("b64136") if error else MUTED)


func _refresh_controllers() -> void:
	_controller_ids = [-1]
	for device in Input.get_connected_joypads():
		_controller_ids.append(device)
	for slot in range(_controller_options.size()):
		var option: OptionButton = _controller_options[slot]
		option.clear()
		option.add_item("P%d · Keyboard" % (slot + 1))
		for device in Input.get_connected_joypads():
			option.add_item("P%d · Pad %d: %s" % [slot + 1, device + 1, Input.get_joy_name(device).left(18)])
		option.select(maxi(0, _controller_ids.find(Settings.controller_for(slot))))


func _on_controller_connection(_device: int, _connected: bool) -> void:
	call_deferred("_refresh_controllers")


func _close() -> void:
	if _closed:
		return
	_closed = true
	Settings.save_settings()
	Sound.apply_settings()
	Sound.play("ui")
	_restore_background_focus()
	# Restore before the callback: rebuilt parent screens choose their own new focus.
	var previous: Variant = _previous_focus.get_ref() if _previous_focus != null else null
	if is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree():
		previous.grab_focus()
	queue_free()
	if _on_close.is_valid():
		_on_close.call()


func _label(caption: String, where: Vector2, dimensions: Vector2, font_size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = caption
	label.position = where
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	if font_size >= 19: label.add_theme_font_override("font",preload("res://assets/fonts/Kalam-Bold.ttf"))
	add_child(label)
	return label


func _button(caption: String, where: Vector2, dimensions: Vector2, callback: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = where
	button.size = dimensions
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _box(ORANGE if accent else PALE, 8, 1))
	button.add_theme_stylebox_override("hover", _box(ORANGE.lightened(0.2), 8, 2))
	button.add_theme_stylebox_override("pressed", _box(ORANGE.darkened(0.07), 8, 2))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 8, 3))
	button.pressed.connect(callback)
	add_child(button)
	return button


func _style_option(option: OptionButton) -> void:
	option.add_theme_color_override("font_color", INK)
	option.add_theme_color_override("font_hover_color", INK)
	option.add_theme_color_override("font_pressed_color", INK)
	option.add_theme_font_size_override("font_size", 14)
	option.add_theme_stylebox_override("normal", _box(PALE, 8, 1))
	option.add_theme_stylebox_override("hover", _box(ORANGE.lightened(0.2), 8, 2))
	option.add_theme_stylebox_override("pressed", _box(PALE, 8, 2))
	option.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 8, 3))


func _box(fill: Color, _radius: int, border: int) -> StyleBox:
	return load("res://scripts/ink_style.gd").make(fill,INK,border)

func _slider_track(fill: Color) -> StyleBox:
	var track := _box(fill,4,0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	return track


func _icon(svg: String) -> Texture2D:
	var bitmap := Image.new()
	bitmap.load_svg_from_string(svg)
	return ImageTexture.create_from_image(bitmap)
