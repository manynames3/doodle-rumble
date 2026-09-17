extends Control
## Full-screen sketchbook editor. Configure after adding it to the race screen.
signal race_requested(course: Dictionary)
signal exit_requested
signal saved(course: Dictionary)

const RallyLibrary = preload("res://scripts/rally_library.gd")
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const INK := Color("26384b")
const PAPER := Color("fff9e9")
const CREAM := Color("f5eacb")
const MUTED := Color("657889")
const ORANGE := Color("f59736")
const SKY := Color("dcebf1")
const ROAD := Color("e0d9c7")
const SAFE_RECT := Rect2(130, 220, 1020, 330)
const THEMES := ["desk", "castle", "sky"]
const STAMPS := ["ramp", "boost", "puddle", "gate", "wind"]

var library: RefCounted
var course: Dictionary = {}
var editor_points: Array = []
var editor_stamps: Array = []
var course_theme: String = "desk"
var edit_mode: String = "dots"
var stamp_kind: String = "ramp"
var status: String = "Join 6–20 dots. Drag one to move it."
var _name: LineEdit
var _status_label: Label
var _mode_button: Button
var _kind_button: Button
var _theme_button: Button
var _drag_index: int = -1
var _history: Array[Dictionary] = []
var _curve: Curve2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2
	_build_ui()
	queue_redraw()

func configure(data_library: RefCounted, existing: Dictionary = {}) -> void:
	library = data_library
	course = existing.duplicate(true)
	editor_points = course.get("points", []).duplicate(true)
	editor_stamps = course.get("stamps", []).duplicate(true)
	course_theme = str(course.get("theme", "desk"))
	if not THEMES.has(course_theme):
		course_theme = "desk"
	_drag_index = -1
	_history.clear()
	_rebuild_curve()
	if is_instance_valid(_name):
		if bool(course.get("preset", false)):
			_name.text = (str(course.get("title", "Course")) + " Remix").left(32)
			status = "A new copy of this world. Give it your own twist."
		else:
			_name.text = str(course.get("title", "")) if not course.is_empty() else "My little loop"
			status = "Join 6–20 dots. Drag one to move it."
		_theme_button.text = "World: " + course_theme.capitalize()
		_mode_button.text = "Tool: Dots"
		_kind_button.text = "Stamp: Ramp"
	_update_status()
	queue_redraw()

func _box(color: Color, radius: int = 13, border: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	return box

func _label(caption: String, where: Vector2, dimensions: Vector2, size_px: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = caption
	label.position = where
	label.size = dimensions
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(caption: String, where: Vector2, dimensions: Vector2, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = where
	button.size = dimensions
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _box(ORANGE if primary else PAPER))
	button.add_theme_stylebox_override("hover", _box(Color("ffe2a3")))
	button.add_theme_stylebox_override("pressed", _box(Color("f6c478")))
	var focus := _box(Color.TRANSPARENT, 13, 4)
	focus.border_color = Color("579eb5")
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	add_child(button)
	return button

func _build_ui() -> void:
	_label("DOODLE RALLY  /  COURSE MAKER", Vector2(47, 21), Vector2(900, 28), 17, MUTED)
	_label("Make your own little world", Vector2(46, 51), Vector2(870, 60), 38)
	_button("Garage", Vector2(1088, 49), Vector2(150, 52), func(): exit_requested.emit())
	_label("Name", Vector2(49, 123), Vector2(68, 28), 18)
	_name = LineEdit.new()
	_name.position = Vector2(105, 116)
	_name.size = Vector2(350, 42)
	_name.max_length = 32
	_name.text = "My little loop"
	_name.add_theme_font_override("font", FONT)
	_name.add_theme_font_size_override("font_size", 18)
	_name.add_theme_color_override("font_color", INK)
	_name.add_theme_stylebox_override("normal", _box(Color.WHITE, 9))
	_name.add_theme_stylebox_override("focus", _box(Color("e8f2f3"), 9, 3))
	add_child(_name)
	_theme_button = _button("World: Desk", Vector2(470, 116), Vector2(175, 42), _cycle_theme)
	_mode_button = _button("Tool: Dots", Vector2(662, 116), Vector2(166, 42), _cycle_mode)
	_kind_button = _button("Stamp: Ramp", Vector2(845, 116), Vector2(193, 42), _cycle_stamp)
	_label("Place dots to draw a loop  ·  Drag dots to shape it  ·  Use stamps to add surprises", Vector2(75, 178), Vector2(1100, 31), 17, MUTED)
	_status_label = _label("", Vector2(47, 580), Vector2(1155, 33), 19)
	_button("Undo", Vector2(48, 640), Vector2(118, 52), _undo)
	_button("Clear", Vector2(179, 640), Vector2(118, 52), _clear)
	_label("Right click a dot or stamp to erase it", Vector2(315, 649), Vector2(450, 29), 17, MUTED)
	_button("Save course", Vector2(801, 636), Vector2(189, 57), _save, false)
	_button("Save & race  >", Vector2(1005, 636), Vector2(231, 57), _save_and_race, true)
	_update_status()

func _cycle_theme() -> void:
	course_theme = THEMES[(THEMES.find(course_theme) + 1) % THEMES.size()]
	_theme_button.text = "World: " + course_theme.capitalize()
	queue_redraw()

func _cycle_mode() -> void:
	edit_mode = "stamps" if edit_mode == "dots" else "dots"
	_mode_button.text = "Tool: " + ("Stamps" if edit_mode == "stamps" else "Dots")
	_update_status()

func _cycle_stamp() -> void:
	stamp_kind = STAMPS[(STAMPS.find(stamp_kind) + 1) % STAMPS.size()]
	_kind_button.text = "Stamp: " + stamp_kind.capitalize()
	_update_status()

func _snapshot() -> void:
	_history.append({"points":editor_points.duplicate(true), "stamps":editor_stamps.duplicate(true)})
	if _history.size() > 50:
		_history.pop_front()

func _undo() -> void:
	if _history.is_empty():
		status = "Nothing to undo yet."
		_update_status()
		return
	var state: Dictionary = _history.pop_back()
	editor_points = state.points
	editor_stamps = state.stamps
	_rebuild_curve()
	status = "Last mark undone."
	_update_status()
	queue_redraw()

func _clear() -> void:
	if editor_points.is_empty() and editor_stamps.is_empty():
		return
	_snapshot()
	editor_points.clear()
	editor_stamps.clear()
	_rebuild_curve()
	status = "A fresh sheet of paper."
	_update_status()
	queue_redraw()

func _rebuild_curve() -> void:
	_curve = RallyLibrary.build_curve({"points":editor_points}) if editor_points.size() >= 3 else null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drag_index = -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and SAFE_RECT.has_point(event.position):
				if edit_mode == "dots":
					_handle_dot_press(event.position)
				else:
					_place_stamp(event.position)
				accept_event()
			elif not event.pressed:
				_drag_index = -1
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and SAFE_RECT.has_point(event.position):
			_erase_nearest(event.position)
			accept_event()
	elif event is InputEventMouseMotion and _drag_index >= 0:
		var point: Vector2 = event.position.clamp(SAFE_RECT.position, SAFE_RECT.end - Vector2.ONE)
		editor_points[_drag_index] = point
		_rebuild_curve()
		queue_redraw()
		accept_event()

func _handle_dot_press(point: Vector2) -> void:
	for i in range(editor_points.size()):
		if editor_points[i].distance_to(point) < 19.0:
			_snapshot()
			_drag_index = i
			status = "Drag this dot to reshape the road."
			_update_status()
			return
	if editor_points.size() >= 20:
		status = "20 dots fills this page. Move or erase one."
	elif not editor_points.is_empty() and editor_points[-1].distance_to(point) < 40.0:
		status = "Give the next dot a car length of room."
	else:
		_snapshot()
		editor_points.append(point)
		_rebuild_curve()
		status = "A new bend!"
	queue_redraw()
	_update_status()

func _nearest_on_curve(point: Vector2) -> Dictionary:
	if _curve == null:
		return {}
	var length: float = _curve.get_baked_length()
	if length <= 0.0:
		return {}
	var best_distance := INF
	var best_offset := 0.0
	var best_lane := 0.0
	for i in range(300):
		var offset: float = length * float(i) / 300.0
		var center: Vector2 = _curve.sample_baked(offset, true)
		var tangent: Vector2 = (_curve.sample_baked(fposmod(offset + 3.0, length), true) - _curve.sample_baked(fposmod(offset - 3.0, length), true)).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var lane: float = clampf((point - center).dot(normal), -30.0, 30.0)
		var distance: float = point.distance_to(center + normal * lane)
		if distance < best_distance:
			best_distance = distance
			best_offset = offset
			best_lane = lane
	return {"u":best_offset / length, "lane":best_lane, "distance":best_distance}

func _place_stamp(point: Vector2) -> void:
	if editor_points.size() < 6:
		status = "Draw the loop before adding course stamps."
	elif editor_stamps.size() >= 32:
		status = "This page already has 32 stamps."
	else:
		var nearest := _nearest_on_curve(point)
		if nearest.is_empty() or nearest.distance > 28.0:
			status = "Put the stamp on the road."
		elif nearest.u < 0.025 or nearest.u > 0.975:
			status = "Leave the starting line clear for a safe race."
		else:
			_snapshot()
			editor_stamps.append({"kind":stamp_kind, "u":nearest.u, "lane":nearest.lane})
			status = "%s added to your road." % stamp_kind.capitalize()
	queue_redraw()
	_update_status()

func _erase_nearest(point: Vector2) -> void:
	if edit_mode == "dots":
		for i in range(editor_points.size()):
			if editor_points[i].distance_to(point) < 20.0:
				_snapshot()
				editor_points.remove_at(i)
				_rebuild_curve()
				status = "Dot erased."
				_update_status()
				queue_redraw()
				return
	else:
		for i in range(editor_stamps.size()):
			if _stamp_position(editor_stamps[i]).distance_to(point) < 22.0:
				_snapshot()
				editor_stamps.remove_at(i)
				status = "Stamp erased."
				_update_status()
				queue_redraw()
				return

func _candidate() -> Dictionary:
	var candidate := course.duplicate(true)
	if candidate.is_empty() or bool(candidate.get("preset", false)):
		candidate = library.make_course(_name.text, course_theme, editor_points, editor_stamps)
	candidate.title = _name.text.strip_edges()
	candidate.theme = course_theme
	candidate.points = editor_points.duplicate(true)
	candidate.stamps = editor_stamps.duplicate(true)
	return candidate

func _save() -> Dictionary:
	if library == null:
		status = "The course library is still opening."
		_update_status()
		return {}
	var candidate := _candidate()
	var error: String = RallyLibrary.validate_course(candidate)
	if not error.is_empty():
		status = error
		_update_status()
		return {}
	var result: Dictionary = library.save_course(candidate)
	if result.is_empty():
		status = library.last_error if not library.last_error.is_empty() else "Could not save this course."
		_update_status()
		return {}
	course = result.duplicate(true)
	status = "Saved! You can reopen this course from the garage."
	_update_status()
	saved.emit(result.duplicate(true))
	return result

func _save_and_race() -> void:
	var result := _save()
	if not result.is_empty():
		race_requested.emit(result.duplicate(true))

func _update_status() -> void:
	if is_instance_valid(_status_label):
		_status_label.text = "%d / 20 dots  ·  %d stamps     %s" % [editor_points.size(), editor_stamps.size(), status]

func _stamp_position(stamp: Dictionary) -> Vector2:
	if _curve == null:
		return Vector2.ZERO
	var length: float = _curve.get_baked_length()
	var offset: float = clampf(float(stamp.get("u", 0.0)), 0.0, 0.999) * length
	var center: Vector2 = _curve.sample_baked(offset, true)
	var tangent: Vector2 = (_curve.sample_baked(fposmod(offset + 3.0, length), true) - _curve.sample_baked(fposmod(offset - 3.0, length), true)).normalized()
	return center + Vector2(-tangent.y, tangent.x) * float(stamp.get("lane", 0.0))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), PAPER)
	for y in range(12, 720, 24):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.38, 0.48, 0.55, 0.055), 1.0)
	draw_style_box(_box(SKY if course_theme == "sky" else (Color("ece8dd") if course_theme == "castle" else Color("eff0e6")), 20, 2), Rect2(68, 207, 1144, 355))
	for x in range(130, 1151, 34):
		for y in range(220, 551, 30):
			draw_circle(Vector2(x, y), 1.5, Color(0.38, 0.48, 0.55, 0.18))
	for side in [[SAFE_RECT.position, Vector2(SAFE_RECT.end.x, SAFE_RECT.position.y)], [SAFE_RECT.end, Vector2(SAFE_RECT.position.x, SAFE_RECT.end.y)], [SAFE_RECT.position, Vector2(SAFE_RECT.position.x, SAFE_RECT.end.y)], [SAFE_RECT.end, Vector2(SAFE_RECT.end.x, SAFE_RECT.position.y)]]:
		draw_dashed_line(side[0], side[1], MUTED, 1.5, 9.0, true)
	if editor_points.size() >= 3 and _curve != null:
		var baked: PackedVector2Array = _curve.get_baked_points()
		draw_polyline(baked, INK, 52.0, true)
		draw_polyline(baked, ROAD, 46.0, true)
		draw_polyline(baked, CREAM, 4.0, true)
	elif editor_points.size() == 2:
		draw_line(editor_points[0], editor_points[1], ROAD, 18.0, true)
	for stamp in editor_stamps:
		var at := _stamp_position(stamp)
		if at == Vector2.ZERO:
			continue
		var color := _stamp_color(str(stamp.get("kind", "")))
		draw_circle(at, 13.0, INK)
		draw_circle(at, 11.0, color)
		draw_string(FONT, at + Vector2(-7, 6), str(stamp.get("kind", "?")).left(1).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 14, 17, INK)
	for i in range(editor_points.size()):
		var point: Vector2 = editor_points[i]
		draw_circle(point, 11.0, ORANGE if i == 0 else INK)
		draw_circle(point, 5.0, PAPER)
		draw_string(FONT, point + Vector2(12, -9), "START" if i == 0 else str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	if editor_points.is_empty():
		draw_string(FONT, Vector2(392, 404), "A big loop begins with one little dot.", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, MUTED)

func _stamp_color(kind: String) -> Color:
	match kind:
		"ramp": return Color("f9b35a")
		"boost": return Color("a9d79c")
		"puddle": return Color("8ec5df")
		"gate": return Color("e2a2c3")
		"wind": return Color("c2b7ee")
	return PAPER
