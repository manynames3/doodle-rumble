extends StyleBox
## Scalable imperfect paper/ink shape shared by menus, pause and results.
var fill := Color("12172b")
var edge := Color("807099")
var thickness := 2.0
func _draw(canvas: RID, rect: Rect2) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0: return
	if minf(rect.size.x,rect.size.y) < 16:
		RenderingServer.canvas_item_add_rect(canvas,rect,fill)
		return
	var p := rect.position
	var s := rect.size
	var points := PackedVector2Array([p+Vector2(5,3),p+Vector2(s.x*0.31,0),p+Vector2(s.x*0.7,3),p+Vector2(s.x-3,1),p+Vector2(s.x,s.y*0.55),p+Vector2(s.x-5,s.y-1),p+Vector2(s.x*0.62,s.y-3),p+Vector2(s.x*0.22,s.y),p+Vector2(1,s.y-4),p+Vector2(3,s.y*0.4)])
	RenderingServer.canvas_item_add_polygon(canvas,points,PackedColorArray([fill]))
	points.append(points[0])
	RenderingServer.canvas_item_add_polyline(canvas,points,PackedColorArray([edge]),thickness,true)
	if rect.size.x > 150:
		RenderingServer.canvas_item_add_line(canvas,p+Vector2(12,7),p+Vector2(minf(68,s.x*0.3),5),Color(edge,0.4),1,true)

static func make(color: Color, border: Color = Color("807099"), width: float = 2.0) -> StyleBox:
	var box = load("res://scripts/ink_style.gd").new()
	box.fill = color
	box.edge = border
	box.thickness = width
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box
