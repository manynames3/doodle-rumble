extends Control
## 512-unit drawing sheet shared by sketch and paper-photo editing.

const SIDE := 512.0
const PARTS := ["head", "body", "left_arm", "right_arm", "left_leg", "right_leg"]
const INK := Color("26384b")
const TEAL := Color("327c86")
const JOINTS := ["head", "shoulder", "hip", "back_elbow", "back_hand", "front_elbow", "front_hand", "left_knee", "left_foot", "right_knee", "right_foot"]

var editor
var mode := "draw"
var texture: Texture2D
var show_ghost := true
var active := false
var moving_joint := ""
var moving_corner := -1
var moving_vertex := -1
var stroke_index := -1
var cursor_pos := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _to_unit(point: Vector2) -> Vector2:
	return Vector2(clampf(point.x / maxf(1.0,size.x) * SIDE,0.0,SIDE),clampf(point.y / maxf(1.0,size.y) * SIDE,0.0,SIDE))

func _to_view(point: Vector2) -> Vector2:
	return Vector2(point.x / SIDE * size.x,point.y / SIDE * size.y)

func _array_point(value) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _draw() -> void:
	var cell := size.x / 16.0
	for y in 16:
		for x in 16:
			draw_rect(Rect2(Vector2(x,y)*cell,Vector2.ONE*cell),Color("fffdf5") if (x+y)%2 == 0 else Color("e3e8e6"))
	if texture != null:
		draw_texture_rect(texture,Rect2(Vector2.ZERO,size),false)
	var rec: Dictionary = editor.record if editor != null else {}
	if rec.is_empty(): return
	if str(rec.get("photo_path","")) == "" or mode == "draw":
		if show_ghost:
			_draw_ghost()
		for stroke in rec.get("strokes",[]):
			var pts: Array = stroke.get("points",[])
			if pts.is_empty(): continue
			var color := Color(str(stroke.get("color","#29364b")))
			var thick: float = float(stroke.get("width",8)) / SIDE * size.x
			if pts.size() == 1:
				draw_circle(_to_view(_array_point(pts[0])),maxf(1.0,thick*0.5),color)
			else:
				var path := PackedVector2Array()
				for point in pts: path.append(_to_view(_array_point(point)))
				draw_polyline(path,color,thick,true)
	if mode == "corners":
		var corners: Array = rec.get("photo_settings",{}).get("corners",[])
		if corners.size() == 4:
			for i in 4:
				var a := _to_view(_array_point(corners[i]))
				var b := _to_view(_array_point(corners[(i+1)%4]))
				draw_line(a,b,Color("ffb14d"),3.0,true)
				draw_circle(a,11.0,Color("fff4d4"))
				draw_arc(a,11.0,0,TAU,24,INK,2.0,true)
				draw_string(ThemeDB.fallback_font,a+Vector2(13,-8),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	if mode in ["polygon","joints","view"] and not str(rec.get("photo_path","")).is_empty():
		var polygons: Dictionary = rec.get("photo_parts",{})
		for part in PARTS:
			if not polygons.has(part): continue
			var poly: Array = polygons[part]
			var points := PackedVector2Array()
			for point in poly: points.append(_to_view(_array_point(point)))
			if points.size() >= 3:
				draw_colored_polygon(points,Color("f5b43b",0.11) if part == editor.selected_part else Color("4a8c97",0.08))
			if points.size() >= 2:
				draw_polyline(points,Color("e2843d") if part == editor.selected_part else Color("327c86"),2.5,true)
				draw_line(points[-1],points[0],Color("e2843d") if part == editor.selected_part else Color("327c86"),2.0,true)
			if part == editor.selected_part and mode == "polygon":
				for point in points: draw_circle(point,5.0,Color("fff1bd"))
	if mode == "joints":
		var joints: Dictionary = rec.get("joints",{})
		for key in JOINTS:
			if not joints.has(key): continue
			var point := _to_view(_array_point(joints[key]))
			draw_circle(point,7.0,Color("fff3ce"))
			draw_arc(point,7.0,0,TAU,18,INK,2.0,true)
			if key == editor.selected_joint: draw_string(ThemeDB.fallback_font,point+Vector2(12,-10),key.replace("_"," "),HORIZONTAL_ALIGNMENT_LEFT,-1,16,INK)
	if mode in ["keep","erase"]:
		var label := "KEEP" if mode == "keep" else "ERASE"
		draw_string(ThemeDB.fallback_font,Vector2(15,26),label,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("327c86") if mode == "keep" else Color("c95d58"))
	if mode == "erase_stroke" and active:
		draw_arc(_to_view(cursor_pos),float(editor.eraser_width) / SIDE * size.x,0,TAU,32,Color("c95d58"),2.5,true)
	draw_rect(Rect2(Vector2.ZERO,size),INK,false,3.0)

func _draw_ghost() -> void:
	var j: Dictionary = editor.record.get("joints",{})
	if not j.has("head"): return
	var ghost := Color("778ca0",0.32)
	var center := _to_view(_array_point(j["head"]))
	draw_arc(center,31.0,0,TAU,40,ghost,2.0,true)
	for pair in [["head","shoulder"],["shoulder","hip"],["shoulder","back_elbow"],["back_elbow","back_hand"],["shoulder","front_elbow"],["front_elbow","front_hand"],["hip","left_knee"],["left_knee","left_foot"],["hip","right_knee"],["right_knee","right_foot"]]:
		if j.has(pair[0]) and j.has(pair[1]): draw_line(_to_view(_array_point(j[pair[0]])),_to_view(_array_point(j[pair[1]])),ghost,2.0,true)

func _gui_input(event: InputEvent) -> void:
	if editor == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := _to_unit(event.position)
		if event.pressed:
			_start_at(pos)
		else:
			_finish()
		accept_event()
	elif event is InputEventMouseMotion and active:
		_move_to(_to_unit(event.position))
		accept_event()

func _start_at(pos: Vector2) -> void:
	var rec: Dictionary = editor.record
	if mode == "view": return
	if mode == "joints":
		var nearest := ""
		var distance := 27.0
		for key in JOINTS:
			if not rec.get("joints",{}).has(key): continue
			var d := pos.distance_to(_array_point(rec["joints"][key]))
			if d < distance:
				nearest = key
				distance = d
		if nearest.is_empty(): nearest = editor.selected_joint
		if nearest.is_empty(): return
		editor._snapshot()
		editor.selected_joint = nearest
		moving_joint = nearest
		active = true
		_move_to(pos)
	elif mode == "corners":
		var corners: Array = rec.get("photo_settings",{}).get("corners",[])
		var closest := 0
		var distance := 1.0e20
		for i in corners.size():
			var d := pos.distance_to(_array_point(corners[i]))
			if d < distance:
				closest = i
				distance = d
		if distance > 42.0: return
		editor._snapshot()
		moving_corner = closest
		active = true
		_move_to(pos)
	elif mode == "polygon":
		var polygons: Dictionary = rec.get("photo_parts",{})
		var poly: Array = polygons.get(editor.selected_part,[])
		moving_vertex = -1
		for i in poly.size():
			if pos.distance_to(_array_point(poly[i])) < 16.0:
				moving_vertex = i
				break
		editor._snapshot()
		if moving_vertex < 0:
			poly.append([roundi(pos.x),roundi(pos.y)])
			moving_vertex = poly.size()-1
		polygons[editor.selected_part] = poly
		rec["photo_parts"] = polygons
		active = true
		queue_redraw()
	elif mode == "draw":
		editor._snapshot()
		var strokes: Array = rec.get("strokes",[])
		strokes.append({"part":editor.selected_part,"color":"#" + editor.selected_color.to_html(false),"width":editor.pen_width,"points":[[roundi(pos.x),roundi(pos.y)]],"detail":editor.details_on})
		rec["strokes"] = strokes
		stroke_index = strokes.size()-1
		active = true
		queue_redraw()
	elif mode == "erase_stroke":
		editor._snapshot()
		active = true
		_erase_at(pos)
	elif mode in ["keep","erase"]:
		editor._snapshot()
		var settings: Dictionary = rec.get("photo_settings",{})
		var field := "keep_strokes" if mode == "keep" else "erase_strokes"
		var brush: Array = settings.get(field,[])
		brush.append({"width":editor.brush_width,"points":[[roundi(pos.x),roundi(pos.y)]]})
		settings[field] = brush
		rec["photo_settings"] = settings
		stroke_index = brush.size()-1
		active = true
		queue_redraw()

func _move_to(pos: Vector2) -> void:
	if not active: return
	var rec: Dictionary = editor.record
	var point := [roundi(pos.x),roundi(pos.y)]
	if mode == "joints" and not moving_joint.is_empty():
		rec["joints"][moving_joint] = point
	elif mode == "corners" and moving_corner >= 0:
		rec["photo_settings"]["corners"][moving_corner] = point
	elif mode == "polygon" and moving_vertex >= 0:
		rec["photo_parts"][editor.selected_part][moving_vertex] = point
	elif mode == "draw" and stroke_index >= 0:
		var pts: Array = rec["strokes"][stroke_index]["points"]
		if _array_point(pts[-1]).distance_to(pos) > 2.5: pts.append(point)
	elif mode == "erase_stroke":
		_erase_at(pos)
	elif mode in ["keep","erase"] and stroke_index >= 0:
		var field := "keep_strokes" if mode == "keep" else "erase_strokes"
		var pts: Array = rec["photo_settings"][field][stroke_index]["points"]
		if _array_point(pts[-1]).distance_to(pos) > 3.5: pts.append(point)
	queue_redraw()

func _point_segment_distance(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var length2: float = start.distance_squared_to(finish)
	if length2 < 0.01: return point.distance_to(start)
	var t: float = clampf((point-start).dot(finish-start)/length2,0.0,1.0)
	return point.distance_to(start.lerp(finish,t))

func _erase_at(pos: Vector2) -> void:
	cursor_pos = pos
	var revised: Array = []
	for original in editor.record.get("strokes",[]):
		var points: Array = original.get("points",[])
		if points.is_empty(): continue
		var radius: float = float(editor.eraser_width) + float(original.get("width",8))*0.5
		var touches := pos.distance_to(_array_point(points[0])) <= radius
		for i in range(1,points.size()):
			if _point_segment_distance(pos,_array_point(points[i-1]),_array_point(points[i])) <= radius:
				touches = true
				break
		if not touches:
			revised.append(original)
			continue
		var run: Array = []
		var sampled: Array = []
		if points.size() == 1:
			sampled.append(_array_point(points[0]))
		else:
			for i in range(1,points.size()):
				var a := _array_point(points[i-1])
				var b := _array_point(points[i])
				var steps: int = maxi(1,int(ceil(a.distance_to(b)/3.0)))
				for n in steps+1:
					if i > 1 and n == 0: continue
					sampled.append(a.lerp(b,float(n)/float(steps)))
		for sample in sampled:
			if sample.distance_to(pos) <= radius:
				if not run.is_empty():
					var piece: Dictionary = original.duplicate(true)
					piece["points"] = run
					revised.append(piece)
					run = []
			else:
				run.append([roundi(sample.x),roundi(sample.y)])
		if not run.is_empty():
			var piece: Dictionary = original.duplicate(true)
			piece["points"] = run
			revised.append(piece)
	editor.record["strokes"] = revised
	queue_redraw()

func _finish() -> void:
	if not active: return
	active = false
	moving_joint = ""
	moving_corner = -1
	moving_vertex = -1
	stroke_index = -1
	editor._changed(mode in ["corners","keep","erase"])
