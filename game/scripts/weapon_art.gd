extends Node2D
## Reusable exaggerated tools. The hand pivot is the local origin; tools point right.
var kind: String = "pitchfork"
var accent: Color = Color("f39232")
var glowing: bool = false
var draw_progress: float = 0.0
var arrow_visible: bool = true
const INK = Color("070913")
const PAPER = Color("f4f5ff")
const WORKSHOP_BONE: Texture2D = preload("res://assets/workshop/weapons/dinosaur_bone_v2.png")
const WORKSHOP_BAT: Texture2D = preload("res://assets/workshop/weapons/baseball_bat_v2.png")
const WORKSHOP_PICKAXE: Texture2D = preload("res://assets/workshop/weapons/pixel_pickaxe_v2.png")
const WORKSHOP_BALL: Texture2D = preload("res://assets/workshop/weapons/soccer_ball_v2.png")
const WORKSHOP_CHICKEN: Texture2D = preload("res://assets/workshop/weapons/rubber_chicken_v1.png")
const WORKSHOP_CRAYON: Texture2D = preload("res://assets/workshop/weapons/giant_crayon_v1.png")

func _draw_pivoted_sprite(texture: Texture2D, source_pivot: Vector2, pixel_scale: float, source_angle: float = 0.0) -> void:
	# Keep the hand anchor independent of transparent canvas padding. Sprite scale
	# only affects this art; the shared combat hitboxes stay game-owned.
	if glowing:
		var glow_scale := pixel_scale * 1.10
		var glow_color := Color(accent.lightened(0.55),0.18+sin(clampf(draw_progress,0.0,1.0)*PI)*0.10)
		draw_set_transform(Vector2.ZERO,source_angle,Vector2.ONE*glow_scale)
		draw_texture(texture,-source_pivot,glow_color)
	draw_set_transform(Vector2.ZERO, source_angle, Vector2.ONE * pixel_scale)
	draw_texture(texture, -source_pivot)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func configure(weapon_kind: String, fighter_color: Color) -> void:
	kind = weapon_kind
	accent = fighter_color
	queue_redraw()

func _stroke(points: Array, color: Color, width: float = 4.0) -> void:
	var path := PackedVector2Array(points)
	draw_polyline(path, Color(accent,0.08), width + 14.0, true)
	draw_polyline(path, Color(accent,0.20), width + 7.0, true)
	draw_polyline(path, INK, width + 3.0, true)
	draw_polyline(path, color, width, true)
	draw_polyline(path, INK, maxf(1.0,width-3.2), true)
	for i in range(path.size()-1):
		var start: Vector2 = path[i]
		var finish: Vector2 = path[i+1]
		var axis: Vector2 = (finish-start).normalized()
		var side: Vector2 = axis.orthogonal()
		# Little changing highlights and cross-grain keep a long straight tool
		# from reading as a stock vector line when the arm swings.
		draw_line(start.lerp(finish,0.08)-side*(width*0.54),start.lerp(finish,0.47)-side*(width*0.58),Color(color.lightened(0.72),0.82),1.1,true)
		draw_line(start.lerp(finish,0.61)-side*(width*0.55),start.lerp(finish,0.91)-side*(width*0.40),Color(color.lightened(0.65),0.56),0.9,true)
		for t in [0.28,0.69]:
			var nick: Vector2 = start.lerp(finish,t)
			draw_line(nick-side*(width*0.32),nick+side*(width*0.30)+axis*2.0,Color(INK,0.67),1.1,true)

func _shape(points: Array, fill: Color, width: float = 2.5) -> void:
	var polygon := PackedVector2Array(points)
	var edge := polygon.duplicate()
	edge.append(edge[0])
	draw_polyline(edge,Color(accent,0.10 if glowing else 0.05),width+15.0,true)
	draw_polyline(edge,Color(accent,0.28 if glowing else 0.15),width+6.0,true)
	draw_colored_polygon(polygon, fill)
	polygon.append(polygon[0])
	draw_polyline(polygon, INK, width+2.5, true)
	draw_polyline(polygon, accent.lightened(0.30 if glowing else 0.03), width, true)
	# A second, broken ink contour is stable across frames: no jitter or flashing.
	for i in range(polygon.size()-1):
		if i%2 == 0:
			var a := polygon[i]
			var b := polygon[i+1]
			var offset := (b-a).normalized().orthogonal()*2.8
			draw_line(a.lerp(b,0.12)+offset,b+offset*0.65,Color(INK,0.9),1.0,true)

func _edge(points: Array, width: float = 1.5) -> void:
	draw_polyline(PackedVector2Array(points),accent.lightened(0.78),width,true)

func _draw() -> void:
	var metal := accent.lightened(0.32)
	match kind:
		"cursor_wand":
			# A compact handheld camera/tablet, like the prop in the title art.
			var slab := PackedVector2Array([Vector2(-11,-14),Vector2(14,-12),Vector2(17,12),Vector2(-9,14)])
			draw_polyline(slab,Color(accent,0.09),9.0,true)
			draw_colored_polygon(slab,Color("11171d"))
			slab.append(slab[0])
			draw_polyline(slab,INK,4.0,true)
			draw_polyline(slab,Color("d0d9d8"),1.2,true)
			var display := PackedVector2Array([Vector2(-6,-9),Vector2(9,-8),Vector2(11,7),Vector2(-5,8)])
			draw_colored_polygon(display,Color("05141b"))
			display.append(display[0])
			draw_polyline(display,Color(accent,0.88),0.8,true)
			draw_circle(Vector2(2,-1),3.4,Color("203c45"))
			draw_circle(Vector2(2,-1),1.7,Color("d8ffff"))
			draw_circle(Vector2(13,-10),1.0,Color("f2e6a4"))
			draw_line(Vector2(-6,11),Vector2(8,10),Color(accent,0.68),0.9,true)
			if glowing:
				# The large cursor exists only for the attack frame; idle remains
				# the small device, while the pointed light carries the hit direction.
				var tip: float = 72.0+sin(clampf(draw_progress,0.0,1.0)*PI)*24.0
				var blade := PackedVector2Array([Vector2(15,-4),Vector2(tip,-11),Vector2(tip-20,-1),Vector2(tip-13,8),Vector2(tip-25,10),Vector2(tip-31,1),Vector2(15,5)])
				draw_polyline(blade,Color(accent,0.08),15.0,true)
				draw_colored_polygon(blade,Color("d9f9f6"))
				blade.append(blade[0])
				draw_polyline(blade,INK,3.8,true)
				draw_polyline(PackedVector2Array([Vector2(19,-2),Vector2(tip-3,-10),Vector2(tip-22,-1)]),Color(accent,0.90),1.5,true)
				for i in range(4):
					var pixel: Vector2 = Vector2(27+float(i)*13,-12+float(i%2)*20)
					draw_rect(Rect2(pixel,Vector2(2.5,2.5)),Color(accent,0.66),true)
		"bow":
			# The hand holds the bow's center; the string bends toward the drawing hand.
			var bow := [Vector2(-20,-38),Vector2(-12,-31),Vector2(-2,-22),Vector2(5,-10),Vector2(7,0),Vector2(4,13),Vector2(-5,25),Vector2(-20,38)]
			_stroke(bow,accent,5.0)
			var nock := Vector2(-22-draw_progress*18.0,0)
			var string := PackedVector2Array([Vector2(-20,-38),nock,Vector2(-20,38)])
			draw_polyline(string,Color(accent,0.20),5.0,true)
			draw_polyline(string,accent.lightened(0.62),1.3,true)
			_shape([Vector2(-1,-8),Vector2(11,-6),Vector2(10,7),Vector2(-2,9)],accent.darkened(0.60),1.8)
			if arrow_visible:
				var tip := Vector2(61-draw_progress*7,0)
				draw_line(nock,tip,INK,4.2,true)
				draw_line(nock,tip,accent.lightened(0.45),1.6,true)
				_shape([tip+Vector2(-12,-6),tip+Vector2(8,0),tip+Vector2(-12,6),tip+Vector2(-6,0)],accent.lightened(0.45),1.5)
				for offset in [-1.0,1.0]:
					draw_polyline(PackedVector2Array([nock+Vector2(1,0),nock+Vector2(-7,offset*5),nock+Vector2(-1,offset*5),nock+Vector2(8,0)]),accent,1.4,true)
			if glowing:
				draw_arc(Vector2(27,0),16,-1.2,1.2,15,Color(accent,0.65),1.4,true)
		"staff", "swarm_staff":
			_stroke([Vector2(-14,1),Vector2(55,-1)],accent,5.8)
			for i in range(4):
				draw_line(Vector2(-2+i*9,-2),Vector2(1+i*9,3),accent.lightened(0.40),1.2,true)
			var crown := [Vector2(47,-9),Vector2(55,-9),Vector2(60,-17),Vector2(65,-7),Vector2(75,-8),Vector2(69,0),Vector2(73,9),Vector2(62,6),Vector2(56,13),Vector2(55,4),Vector2(47,3)]
			_shape(crown,accent.darkened(0.59),2.1)
			draw_circle(Vector2(61,-1),4.6,accent.lightened(0.48))
			draw_circle(Vector2(60,-2),1.8,PAPER)
			if glowing:
				draw_arc(Vector2(61,-1),21,0.2,2.6,18,Color(accent,0.55),1.4,true)
				draw_arc(Vector2(61,-1),24,3.3,5.6,18,Color(accent,0.40),1.2,true)
				for point in [Vector2(47,-24),Vector2(84,-3),Vector2(65,22)]:
					draw_line(point-Vector2(3,0),point+Vector2(3,0),accent.lightened(0.65),1.2,true)
					draw_line(point-Vector2(0,3),point+Vector2(0,3),accent.lightened(0.65),1.2,true)
		"dark_blade":
			# A long crooked ink pole and a cut-out hook. At the resting angle it
			# rises beside the crown like the scythe in the battle illustration.
			var pole := PackedVector2Array([Vector2(-17,2),Vector2(12,-2),Vector2(51,-1),Vector2(87,-7),Vector2(117,-5)])
			draw_polyline(pole,Color(accent,0.13),13.0,true)
			draw_polyline(pole,INK,8.0,true)
			draw_polyline(pole,Color("100b1b"),5.6,true)
			draw_polyline(PackedVector2Array([Vector2(-13,0),Vector2(12,-3),Vector2(47,-2),Vector2(86,-9),Vector2(114,-7)]),Color(accent,0.52),1.0,true)
			for i in range(7):
				var grip := Vector2(-8+float(i)*15,-2-float(i%2))
				draw_line(grip+Vector2(-2,-4),grip+Vector2(3,4),INK,2.0,true)
				draw_line(grip+Vector2(0,-3),grip+Vector2(3,2),Color(accent,0.54),0.9,true)
			var thorn := PackedVector2Array([Vector2(111,-17),Vector2(121,-20),Vector2(130,-10),Vector2(137,-20),Vector2(130,-5),Vector2(122,2),Vector2(118,12),Vector2(108,8)])
			draw_colored_polygon(thorn,INK)
			thorn.append(thorn[0])
			draw_polyline(thorn,Color(accent,0.56),1.6,true)
			# Scythe edge: hooked stepped pixels, with black mass and restrained
			# purple cuts instead of a smooth, solid-colored fantasy sword.
			var hook := PackedVector2Array([Vector2(122,-14),Vector2(137,-26),Vector2(145,-31),Vector2(145,-42),Vector2(152,-42),Vector2(152,-51),Vector2(164,-51),Vector2(167,-60),Vector2(184,-63),Vector2(178,-52),Vector2(171,-45),Vector2(166,-33),Vector2(156,-24),Vector2(152,-13),Vector2(137,-4),Vector2(124,-3)])
			draw_polyline(hook,Color(accent,0.11),10.0,true)
			draw_colored_polygon(hook,Color("070711"))
			hook.append(hook[0])
			draw_polyline(hook,INK,4.0,true)
			draw_polyline(PackedVector2Array([Vector2(127,-11),Vector2(142,-21),Vector2(153,-35),Vector2(164,-46),Vector2(178,-58)]),Color(accent,0.75),1.7,true)
			draw_polyline(PackedVector2Array([Vector2(132,-5),Vector2(150,-18),Vector2(155,-28)]),Color(accent,0.35),0.8,true)
			for offset in [Vector2(143,-28),Vector2(156,-46),Vector2(173,-59)]:
				draw_line(offset,offset+Vector2(8,-7),INK,2.4,true)
		"hammer":
			_stroke([Vector2(-13, 1), Vector2(58, -1)], Color("c69662"), 7.0)
			# Heavy forged block: oversized, irregular, with hot red bevels.
			_shape([Vector2(48,-33),Vector2(82,-37),Vector2(98,-27),Vector2(96,32),Vector2(80,40),Vector2(46,32)], Color("d9c3bd"), 3.5)
			_shape([Vector2(82,-37),Vector2(98,-27),Vector2(96,32),Vector2(80,40)], accent.darkened(0.55),2.3)
			_edge([Vector2(48,-29),Vector2(78,-33),Vector2(89,-27)],1.8)
			draw_line(Vector2(52,25),Vector2(72,29),accent,2.0,true)
			var fissure := PackedVector2Array([Vector2(63,-28),Vector2(67,-12),Vector2(61,-4),Vector2(69,10),Vector2(63,24)])
			draw_polyline(fissure,Color(INK,0.60),1.4,true)
			for i in range(7):
				var scratch := Vector2(51+(i%3)*11,-21+i*7)
				draw_line(scratch,scratch+Vector2(3,-2),Color(INK,0.58),1.1,true)
				draw_line(scratch+Vector2(1,4),scratch+Vector2(4,2),Color(accent,0.35),0.9,true)
			for rivet in [Vector2(53,-21),Vector2(76,-24),Vector2(53,22),Vector2(76,25)]:
				draw_circle(rivet,2.0,accent.darkened(0.25))
			for i in range(5):
				draw_line(Vector2(-3+i*8,-3),Vector2(1+i*8,3),accent.darkened(0.10),1.5,true)
		"sword", "pixel_sword":
			_stroke([Vector2(-14,0),Vector2(17,0)],accent,8.0)
			_shape([Vector2(14,-20),Vector2(23,-20),Vector2(23,-10),Vector2(32,-10),Vector2(32,10),Vector2(23,10),Vector2(23,20),Vector2(14,20)],accent.darkened(0.67))
			# Stepped outline directly echoes the giant sword in the drawing.
			_shape([Vector2(29,-8),Vector2(45,-8),Vector2(45,-15),Vector2(62,-15),Vector2(62,-21),Vector2(78,-21),Vector2(78,-27),Vector2(98,-27),Vector2(98,-17),Vector2(108,-17),Vector2(108,-7),Vector2(95,-7),Vector2(95,0),Vector2(78,0),Vector2(78,7),Vector2(61,7),Vector2(61,14),Vector2(44,14),Vector2(44,9),Vector2(29,9)],accent.lightened(0.54),3.0)
			_edge([Vector2(31,-8),Vector2(45,-8),Vector2(45,-15),Vector2(62,-15),Vector2(62,-21),Vector2(78,-21),Vector2(78,-27),Vector2(96,-27)],1.6)
			draw_polyline(PackedVector2Array([Vector2(38,3),Vector2(54,3),Vector2(54,-3),Vector2(71,-3),Vector2(71,-9),Vector2(94,-9)]),accent,2.0,false)
			_shape([Vector2(-19,-7),Vector2(-10,-7),Vector2(-10,7),Vector2(-19,7)],accent)
		"pickaxe":
			_stroke([Vector2(-16,1),Vector2(68,-1)],accent,7.0)
			_shape([Vector2(58,-37),Vector2(73,-31),Vector2(81,-18),Vector2(83,1),Vector2(77,22),Vector2(63,37),Vector2(68,15),Vector2(67,-9),Vector2(56,-23)],metal,3.5)
			_shape([Vector2(61,-9),Vector2(74,-9),Vector2(76,5),Vector2(61,7)],accent.darkened(0.65))
			_edge([Vector2(59,-36),Vector2(72,-30),Vector2(80,-17),Vector2(82,0),Vector2(76,20),Vector2(64,35)],1.6)
			draw_line(Vector2(72,10),Vector2(68,26),accent,2,true)
			for i in range(5):
				draw_line(Vector2(-2+i*8,-3),Vector2(1+i*8,3),accent.darkened(0.08),1.5,true)
		"custom_pick":
			# This image is painted with the handle about 52 degrees below its tip;
			# rotate it around the grip so the shared swing pose starts rightward.
			_draw_pivoted_sprite(WORKSHOP_PICKAXE,Vector2(610,780),0.085,deg_to_rad(52.0))
		"custom_bone":
			_draw_pivoted_sprite(WORKSHOP_BONE,Vector2(320,690),0.075)
		"custom_bat":
			_draw_pivoted_sprite(WORKSHOP_BAT,Vector2(260,660),0.075)
		"custom_ball":
			draw_circle(Vector2.ZERO,25.0,Color(accent,0.12))
			_draw_pivoted_sprite(WORKSHOP_BALL,Vector2(627,627),0.036)
		"custom_chicken":
			_draw_pivoted_sprite(WORKSHOP_CHICKEN,Vector2(280,790),0.075,deg_to_rad(24.0))
		"custom_crayon":
			_draw_pivoted_sprite(WORKSHOP_CRAYON,Vector2(285,765),0.070,deg_to_rad(27.0))
		_:
			_stroke([Vector2(-18,1),Vector2(66,-1)],accent,6.0)
			_shape([Vector2(56,-22),Vector2(80,-23),Vector2(92,-33),Vector2(91,-21),Vector2(83,-12),Vector2(68,-10),Vector2(68,-3),Vector2(91,-4),Vector2(103,-14),Vector2(99,-1),Vector2(91,8),Vector2(68,9),Vector2(69,17),Vector2(86,18),Vector2(98,8),Vector2(95,22),Vector2(86,28),Vector2(58,27)],accent.lightened(0.15),3.0)
			_edge([Vector2(59,-20),Vector2(80,-21),Vector2(90,-29)],1.4)
			_edge([Vector2(70,-1),Vector2(92,-2),Vector2(100,-11)],1.4)
			_edge([Vector2(71,20),Vector2(86,21),Vector2(95,12)],1.4)
			for i in range(5):
				draw_line(Vector2(-6+i*9,-2),Vector2(-3+i*9,3),accent.lightened(0.25),1.3,true)
