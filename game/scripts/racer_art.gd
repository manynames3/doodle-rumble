extends Node2D
## Original top-down toy cars. Local +X is forward; heading rotates the whole doodle.
const INK := Color("26384b")
const PAPER := Color("fff9e9")
var style: int = 0
var paint := Color("f59736")
var heading: float = 0.0:
	set(value):
		heading = value
		rotation = value
var hop: float = 0.0
var boosting: bool = false
var is_player: bool = false
var drift: float = 0.0
var speed: float = 0.0
var motion_time: float = 0.0
var reduced_motion: bool = false
var sticker := "plain"
var turn_lean := 0.0

func configure(new_style: int, new_paint: Color) -> void:
	style = clampi(new_style, 0, 2)
	paint = new_paint
	queue_redraw()

func _polygon(points: PackedVector2Array, color: Color, width: float = 2.0) -> void:
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, INK, width, true)

func _oval(at: Vector2, radii: Vector2, color: Color, border: bool = true) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		points.append(at + Vector2(cos(i * TAU / 24.0), sin(i * TAU / 24.0)) * radii)
	if border:
		_polygon(points, color)
	else:
		draw_colored_polygon(points, color)

func _draw() -> void:
	# A chunky sketchbook car: intentionally bigger than the earlier toy icons.
	_oval(Vector2(-2, 7), Vector2(31, 19), Color(0.15, 0.22, 0.29, 0.18), false)
	var lift := clampf(hop, 0.0, 1.0) * 12.0
	var lean := 0.0 if reduced_motion else turn_lean * (0.07 + drift * 0.17)
	var bounce := 0.0 if reduced_motion else sin(motion_time * 17.0 + position.x * 0.03) * minf(speed / 520.0, 1.0) * 1.7
	draw_set_transform(Vector2(0, -lift + bounce), lean, Vector2.ONE * (1.15 + lift * 0.014))
	if boosting:
		for row in [-1.0,0.0,1.0]:
			_polygon(PackedVector2Array([Vector2(-22,row*8-4),Vector2(-51,row*8-2),Vector2(-34,row*8+2),Vector2(-48,row*8+7),Vector2(-22,row*8+5)]), Color("ffc84e").lightened(absf(row)*0.1))
	for x in [-13, 12]:
		for y in [-15, 15]:
			_oval(Vector2(x,y), Vector2(7,5), INK)
	if style == 0:
		# Broad dragon bonnet, hollow eyes and pencil-sharp fins from the drawing.
		for x in [-16, -4, 8]:
			_polygon(PackedVector2Array([Vector2(x-5,-11),Vector2(x,-23),Vector2(x+6,-11)]), paint.lightened(0.2))
			_polygon(PackedVector2Array([Vector2(x-5,11),Vector2(x,23),Vector2(x+6,11)]), paint.lightened(0.2))
		_polygon(PackedVector2Array([Vector2(-24,-10),Vector2(9,-14),Vector2(26,-8),Vector2(29,0),Vector2(25,11),Vector2(-21,12)]),paint)
		_oval(Vector2(-7,0), Vector2(9,8), PAPER)
		for y in [-7,7]:
			_oval(Vector2(16,y),Vector2(6,5),PAPER)
			_oval(Vector2(17,y),Vector2(2.2,2.8),INK,false)
		draw_line(Vector2(25,-3),Vector2(28,-2),INK,2,true)
	elif style == 1:
		_polygon(PackedVector2Array([Vector2(-22,-6),Vector2(-28,-21),Vector2(-10,-13),Vector2(5,-12),Vector2(29,0),Vector2(4,13),Vector2(-10,13),Vector2(-28,21),Vector2(-22,6)]),paint)
		_oval(Vector2(-2,0),Vector2(11,9),PAPER)
		for y in [-4,4]:
			_oval(Vector2(14,y),Vector2(4,3),PAPER)
			_oval(Vector2(15,y),Vector2(1.4,1.7),INK,false)
		draw_line(Vector2(-7,-14),Vector2(2,-25),INK,2,true)
		draw_circle(Vector2(2,-25),3,Color("e884a0"))
	else:
		_polygon(PackedVector2Array([Vector2(-24,-9),Vector2(-18,-17),Vector2(-5,-16),Vector2(3,-20),Vector2(17,-16),Vector2(18,-10),Vector2(28,-6),Vector2(28,8),Vector2(16,16),Vector2(3,15),Vector2(-6,19),Vector2(-21,13)]),paint)
		_oval(Vector2(-6,0),Vector2(10,9),PAPER)
		for y in [-7,7]:
			_oval(Vector2(16,y),Vector2(5,4),PAPER)
			_oval(Vector2(17,y),Vector2(1.8,2.3),INK,false)
		draw_arc(Vector2(21,0),4,-PI/2,PI/2,8,INK,1.7,true)
	draw_set_transform(Vector2.ZERO)
	if is_player:
		draw_arc(Vector2.ZERO,37,0,TAU,36,Color("f59736"),2.7,true)
	if sticker == "star":
		_draw_sticker(Vector2(2,-3),Color("ffd55d"),false)
	elif sticker == "lightning":
		_draw_sticker(Vector2(3,-3),Color("8de8ff"),true)
	if absf(drift) > 0.12 and not reduced_motion:
		for y in [-12.0,12.0]:
			draw_line(Vector2(-18,y),Vector2(-42,y-drift*8),Color(0.15,0.22,0.29,0.34),2.0,true)

func _draw_sticker(at: Vector2, color: Color, lightning: bool) -> void:
	if lightning:
		var bolt := PackedVector2Array([at+Vector2(-3,-9),at+Vector2(5,-9),at+Vector2(0,-1),at+Vector2(7,-1),at+Vector2(-5,10),at+Vector2(-1,2),at+Vector2(-8,2)])
		draw_colored_polygon(bolt,color); bolt.append(bolt[0]); draw_polyline(bolt,INK,1.2,true)
		return
	var points := PackedVector2Array()
	for i in range(10):
		points.append(at+Vector2(cos(i*PI/5.0-PI/2),sin(i*PI/5.0-PI/2))*(8.0 if i%2==0 else 3.8))
	draw_colored_polygon(points,color);points.append(points[0]);draw_polyline(points,INK,1.2,true)
