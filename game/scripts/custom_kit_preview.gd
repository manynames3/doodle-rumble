extends Node2D
## A non-combat illustration of each kit's special, shared by both menus.
const WORKSHOP_BONE: Texture2D = preload("res://assets/workshop/weapons/dinosaur_bone_v2.png")
const WORKSHOP_BALL: Texture2D = preload("res://assets/workshop/weapons/soccer_ball_v2.png")
var kit := "pixel_pick"
var phase := 0.0
var reduced := false
var origin := Vector2(30,-65)
var active := false

func present(kit_id: String, progress: float, hand: Vector2, still: bool) -> void:
	kit=kit_id
	origin=hand
	reduced=still
	active=progress>=0.0
	phase=0.55 if still else clampf((progress-0.27)/0.65,0,1)
	queue_redraw()

func _draw() -> void:
	if not active or phase<=0 or phase>=1: return
	var ink := Color("101727")
	var shine := Color("fff0bd")
	match kit:
		"pixel_pick":
			for i in range(3):
				var pulse := 0.75 if reduced else maxf(0,1.0-absf(phase-(0.24+i*0.22))*4.5)
				var base := Vector2(40+i*43,0)
				_draw_oval(base,Vector2(20,4),Color("64e7f2",0.32))
				var crystal := PackedVector2Array([base+Vector2(-10,0),base+Vector2(-8,-24*pulse),base+Vector2(2,-49*pulse),base+Vector2(12,-29*pulse),base+Vector2(14,0)])
				draw_colored_polygon(crystal,Color("70d5dc"))
				crystal.append(crystal[0])
				draw_polyline(crystal,ink,2.3,true)
				draw_line(base,base+Vector2(2,-42*pulse),shine,1.5,true)
		"bone":
			var flight := sin(phase*PI)
			var at := origin+Vector2(flight*116,-sin(phase*PI)*27)
			draw_arc(origin+Vector2(54,-3),58,PI*1.05,TAU,24,Color(shine,0.3),1.3,true)
			draw_set_transform(at,phase*TAU*2.0,Vector2.ONE*0.05)
			draw_texture(WORKSHOP_BONE,-Vector2(WORKSHOP_BONE.get_size())*0.5)
			draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		"ball":
			var at := Vector2(28+128*phase,-10-absf(sin(phase*TAU))*53)
			for i in range(4):
				draw_circle(at+Vector2(-i*9,i*2),6-i,Color("96edff",0.30-i*0.05))
			draw_set_transform(at,phase*TAU,Vector2.ONE*0.035)
			draw_texture(WORKSHOP_BALL,-Vector2(WORKSHOP_BALL.get_size())*0.5)
			draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		"bat":
			for i in range(7):
				var angle := -1.15+i*0.22
				var at := origin+Vector2.from_angle(angle)*67
				draw_line(at,at+Vector2.from_angle(angle)*(12+phase*16),Color("ffe279",1.0-phase*0.6),2.5,true)
		"rubber_chicken":
			# A close-range squeakquake pulses away in both directions.
			var radius := 20.0+phase*104.0
			for direction in [-1.0,1.0]:
				draw_arc(origin+Vector2(direction*12,23),radius,PI*0.16,PI*0.84,18,Color("fff1b5",0.8),4.0,true)
				draw_arc(origin+Vector2(direction*12,23),radius*0.75,PI*0.18,PI*0.82,18,Color("ffb13d",0.84),3.0,true)
			for i in range(3):
				var feather := Vector2(25+i*27,-8-i*8)*Vector2(1.0 if i%2==0 else -1.0,1.0)
				draw_line(feather,feather+Vector2(9,-13),Color("fff4cf",0.9),3.0,true)
				draw_line(feather+Vector2(3,-4),feather+Vector2(13,-5),Color("f3a33c",0.85),2.0,true)
		"giant_crayon":
			var palette := [Color("ff5369"),Color("ffaf35"),Color("f6ec52"),Color("5cda81"),Color("44c9f4"),Color("ad68ec")]
			var count := maxi(2,ceili(16.0*phase))
			for i in palette.size():
				var path := PackedVector2Array()
				for point in range(count):
					var t := float(point)/15.0
					var direction := -1.0 if reduced else 1.0
					var x := origin.x+direction*(26.0+296.0*t)
					var y := origin.y+27.0-36.0*sin(t*TAU*2.15+i*0.12)+float(i)*1.6
					path.append(Vector2(x,y))
				draw_polyline(path,Color(palette[i],0.83),3.4,true)
			for i in range(4):
				var star := origin+Vector2(76+i*59,-28-(i%2)*29)
				draw_line(star+Vector2(-4,0),star+Vector2(4,0),Color("fff5c9",0.9),2.0,true)
				draw_line(star+Vector2(0,-4),star+Vector2(0,4),Color("fff5c9",0.9),2.0,true)

func _draw_oval(at: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24: points.append(at+Vector2(cos(i*TAU/24.0),sin(i*TAU/24.0))*radius)
	draw_colored_polygon(points,color)
