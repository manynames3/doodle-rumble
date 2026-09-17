extends Button
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const Library = preload("res://scripts/rally_library.gd")
var course: Dictionary = {}
var chosen := false
var clock := 0.0
var personal_best := 0.0

func _ready() -> void:
	for state in ["normal","hover","pressed","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	if course.is_empty(): return
	var ink := Color("233d4c")
	var accent: Color = {"desk":Color("ec9942"),"castle":Color("bb78aa"),"sky":Color("4aabbf")}.get(course.theme,Color("ec9942"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("ffefbe") if chosen else Color("fffaf0")
	box.border_color = accent if chosen or is_hovered() or has_focus() else Color("b5b9a4")
	box.set_border_width_all(4 if chosen or has_focus() else 2)
	box.set_corner_radius_all(15)
	draw_style_box(box,Rect2(Vector2.ZERO,size))
	draw_string(FONT,Vector2(16,35),str(course.title),HORIZONTAL_ALIGNMENT_LEFT,size.x-30,24,ink)
	var curve: Curve2D = Library.build_curve(course)
	var points := PackedVector2Array()
	for p in curve.get_baked_points():
		points.append(Vector2(21+(p.x-120)/1050*(size.x-42),66+(p.y-210)/360*76))
	if points.size()>1:
		draw_polyline(points,ink,16,true)
		draw_polyline(points,Color("e5dcbf"),12,true)
		draw_polyline(points,Color("fff9e3"),2,true)
	for stamp in course.get("stamps",[]):
		var point: Vector2 = curve.sample_baked(float(stamp.u)*curve.get_baked_length())
		point = Vector2(21+(point.x-120)/1050*(size.x-42),66+(point.y-210)/360*76)
		draw_circle(point,4,accent)
	var themes := {"desk":"RULER RAMPS + INK PUDDLES","castle":"CARDBOARD GATES + TURBO","sky":"CLOUD HOPS + WIND GUSTS"}
	draw_string(ThemeDB.fallback_font,Vector2(16,size.y-43),str(themes.get(course.theme,"YOUR IDEAS. YOUR ROAD.")),HORIZONTAL_ALIGNMENT_LEFT,size.x-26,12,ink)
	draw_string(FONT,Vector2(16,size.y-15),"BEST %.1fs"%personal_best if personal_best>0 else "LET'S GO!" if chosen else "Pick this playground",HORIZONTAL_ALIGNMENT_LEFT,size.x-26,19,accent)
