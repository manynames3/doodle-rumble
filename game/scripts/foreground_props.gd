extends Node2D
## Close-up props that crop into the bottom of the arena without masking combat.
const INK = Color("171424")

var arena_kind = "desktop"
var reduced_motion = false
var focus_x = 640.0
var elapsed = 0.0

func _ready() -> void:
	z_index = 12
	queue_redraw()

func _process(delta: float) -> void:
	if not reduced_motion: elapsed += delta
	queue_redraw()

func _draw() -> void:
	match arena_kind:
		"canopy","arcade","network": _draw_story_foreground()
		"quarry": _draw_quarry_foreground()
		"glitch": _draw_glitch_foreground()
		_: _draw_desktop_foreground()

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result = points.duplicate()
	if not result.is_empty(): result.append(result[0])
	return result

func _ink_shape(points: PackedVector2Array, fill: Color, width: float = 3.0) -> void:
	draw_colored_polygon(points,fill)
	draw_polyline(_closed(points),Color(INK,0.48),width+3.5,true)
	draw_polyline(_closed(points),INK,width,true)

func _rough_line(a: Vector2, b: Vector2, color: Color, width: float, seed: float, steps: int = 8) -> void:
	var points = PackedVector2Array()
	var direction = b-a
	var normal = Vector2(-direction.y,direction.x).normalized()
	for i in range(steps+1):
		var t = float(i)/steps
		var wobble = 0.0 if i in [0,steps] else sin(seed+i*2.41)*1.05+sin(seed+i*5.2)*0.3
		points.append(a+direction*t+normal*wobble)
	draw_polyline(points,color,width,true)

func _draw_desktop_foreground() -> void:
	var shift = clampf((focus_x-640.0)*0.006,-2.0,2.0) if not reduced_motion else 0.0
	# Mug at the extreme edge: close enough to camera to crop, clear of spawn space.
	var mug = PackedVector2Array([Vector2(-13+shift,611),Vector2(67+shift,601),Vector2(83+shift,618),Vector2(77+shift,690),Vector2(2+shift,696)])
	_ink_shape(mug,Color("6b5478"),3.7)
	_draw_ink_ellipse(Vector2(34+shift,610),Vector2(42,11),Color("c98d77"),INK)
	draw_arc(Vector2(78+shift,644),29,-1.3,1.35,20,INK,8.0,true)
	draw_arc(Vector2(78+shift,644),25,-1.25,1.28,20,Color("b37b77"),4.0,true)
	for i in range(3):
		var sway = 0.0 if reduced_motion else sin(elapsed*1.3+i)*3.0
		_rough_line(Vector2(20+i*15+shift,601),Vector2(25+i*14+shift+sway,590+i*3),Color("ead5cf",0.34),1.5,float(i+2),5)

	# Cropped keyboard, safely below the fighters' feet.
	var keyboard = PackedVector2Array([Vector2(318,681),Vector2(933,674),Vector2(980,720),Vector2(278,720)])
	_ink_shape(keyboard,Color("45435c"),3.6)
	for row in range(2):
		for col in range(14):
			var x = 337+col*42+row*8
			var y = 690+row*17
			draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+29,y-1),Vector2(x+32,y+9),Vector2(x+2,y+10)]),Color("777087") if (row+col)%4 else Color("b7838b"))
			draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+29,y-1),Vector2(x+32,y+9)]),Color(INK,0.72),1.1,true)

	# Sketchbooks and loose notes frame the right side and bottom crop.
	for i in range(3):
		var y = 651+i*19
		var book = PackedVector2Array([Vector2(1040-i*7,y),Vector2(1264+i*5,y-5),Vector2(1276,y+13),Vector2(1039-i*8,y+20)])
		_ink_shape(book,[Color("855771"),Color("4c6c7e"),Color("927452")][i],2.4)
		_rough_line(Vector2(1064-i*7,y+7),Vector2(1228,y+2),Color("eadbc0",0.65),1.1,float(12+i),10)
	var note = PackedVector2Array([Vector2(1047,628),Vector2(1127,621),Vector2(1138,665),Vector2(1054,671)])
	_ink_shape(note,Color("e8d9b9"),2.3)
	_rough_line(Vector2(1064,640),Vector2(1115,635),Color("806779"),1.2,18.0,6)
	_rough_line(Vector2(1066,650),Vector2(1105,647),Color("806779"),1.2,19.0,5)
	for i in range(4):
		var x = 112+i*43
		var scrap = PackedVector2Array([Vector2(x,697-(i%2)*5),Vector2(x+36,694),Vector2(x+41,720),Vector2(x-3,720)])
		_ink_shape(scrap,Color("d7c7ad"),1.7)

func _draw_ink_ellipse(center: Vector2, radius: Vector2, fill: Color, edge: Color) -> void:
	var points = PackedVector2Array()
	for i in range(25):
		var angle = TAU*float(i)/24.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,fill)
	draw_polyline(_closed(points),edge,2.8,true)

func _draw_quarry_foreground() -> void:
	# Soft-edged stone silhouettes crop only the outer corners and bottom lip.
	var left = PackedVector2Array([Vector2(-18,720),Vector2(-12,622),Vector2(14,596),Vector2(48,590),Vector2(79,606),Vector2(101,647),Vector2(124,720)])
	_ink_shape(left,Color("4d4249"),4.0)
	var right = PackedVector2Array([Vector2(1151,720),Vector2(1168,650),Vector2(1181,611),Vector2(1215,592),Vector2(1258,601),Vector2(1294,632),Vector2(1298,720)])
	_ink_shape(right,Color("564548"),4.0)
	for i in range(7):
		var x = 16+i*18
		_rough_line(Vector2(x,665),Vector2(x-7+sin(i)*8,632-(i%3)*12),Color("cfad52"),2.0,float(i),4)
	for i in range(8):
		var x = 1118+i*23
		_rough_line(Vector2(x,700),Vector2(x+sin(i+2)*9,665-(i%4)*8),Color("b69b4a"),2.0,float(i+9),4)
	for i in range(9):
		var x = 210+i*112
		var chunk = PackedVector2Array([Vector2(x,704),Vector2(x+12,691-(i%3)*4),Vector2(x+34,696),Vector2(x+45,720),Vector2(x-8,720)])
		_ink_shape(chunk,Color("514854"),2.2)

func _draw_glitch_foreground() -> void:
	# Edge terminals and cable loops give the lab depth while the center remains readable.
	var left_box = PackedVector2Array([Vector2(-11,720),Vector2(-5,610),Vector2(62,594),Vector2(101,618),Vector2(108,720)])
	_ink_shape(left_box,Color("171a35"),4.0)
	draw_rect(Rect2(11,618,65,37),Color("242957"))
	draw_polyline(_closed(PackedVector2Array([Vector2(11,618),Vector2(76,618),Vector2(76,655),Vector2(11,655)])),Color("d45eff"),2.2,true)
	for i in range(5): draw_rect(Rect2(18+i*11,628+(i%2)*10,6,5),Color("6ce5ff",0.85))
	var right_box = PackedVector2Array([Vector2(1171,720),Vector2(1180,624),Vector2(1212,600),Vector2(1288,613),Vector2(1295,720)])
	_ink_shape(right_box,Color("171a35"),4.0)
	for i in range(3):
		draw_arc(Vector2(1218+i*19,650),20+i*5,0.25,PI*1.78,20,Color("d65bff",0.7),2.2,true)
	for i in range(5):
		var center = Vector2(300+i*170,716)
		draw_arc(center,70+(i%2)*18,PI*1.08,PI*1.92,22,Color(INK,0.72),7.0,true)
		draw_arc(center,70+(i%2)*18,PI*1.08,PI*1.92,22,Color("744cc0",0.68),2.2,true)
	if not reduced_motion:
		for i in range(4):
			var x = 145+i*287+sin(elapsed*2.0+i)*3.0
			draw_rect(Rect2(x,682-(i%2)*12,5+(i%3)*3,4),Color("df6fff",0.62))

func _draw_story_foreground() -> void:
	# Small cropped sketches bring the painted story worlds into the same
	# tabletop plane. Every mark starts below the 600 px collision floor.
	match arena_kind:
		"canopy":
			for side in [-1,1]:
				var anchor = Vector2(98 if side < 0 else 1182,724)
				var stem = anchor+Vector2(-side*36,-72)
				_rough_line(anchor,stem,Color("25392c"),4.2,float(side+36),9)
				for j in range(4):
					var p = anchor.lerp(stem,(j+1)*0.2)
					var leaf = PackedVector2Array([p,p+Vector2(side*(21+j*3),-17),p+Vector2(side*(31+j*2),-7),p+Vector2(side*8,3)])
					_ink_shape(leaf,Color("627752",0.9),1.7)
					_rough_line(p,p+Vector2(side*(20+j*2),-7),Color("d8c390",0.55),1.0,float(j+side*13),4)
		"arcade":
			var ticket = PackedVector2Array([Vector2(6,671),Vector2(100,657),Vector2(119,720),Vector2(4,720)])
			_ink_shape(ticket,Color("d692be"),2.4)
			_rough_line(Vector2(24,682),Vector2(86,675),Color("fff1bd",0.8),1.6,71.0,7)
			for j in range(5):
				draw_circle(Vector2(30+j*15,696-j%2*2),2.4,Color("4e345e"))
			var dial = Vector2(1225,693)
			draw_circle(dial,43,Color(INK,0.8))
			draw_circle(dial,36,Color("624276"))
			draw_arc(dial,32,-2.7,-0.4,16,Color("f4a8d4"),3.0,true)
			draw_circle(dial,10,Color("f5d394"))
		"network":
			for j in range(4):
				var base = Vector2(13+j*51,716)
				_rough_line(base,base+Vector2(25,-49-(j%2)*8),Color("253747"),5.0,float(j+94),7)
				_rough_line(base+Vector2(1,-1),base+Vector2(24,-47-(j%2)*8),Color("73cbd5",0.65),1.6,float(j+96),7)
			var plug = PackedVector2Array([Vector2(1136,686),Vector2(1257,679),Vector2(1265,720),Vector2(1128,720)])
			_ink_shape(plug,Color("263b4e"),2.8)
			for j in range(5):
				draw_rect(Rect2(1150+j*21,689+j%2*3,11,7),Color("d6b183",0.88))
