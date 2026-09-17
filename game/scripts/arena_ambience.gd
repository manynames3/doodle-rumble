extends RefCounted
## Distant scenery animation only. It never drives collision or damage.
const HandFont = preload("res://assets/fonts/Kalam-Bold.ttf")

func paint(canvas: Node2D, kind: String, time: float) -> void:
	match kind:
		"canopy":
			_paint_canopy(canvas,time)
		"arcade":
			_paint_arcade(canvas,time)
		"network":
			for row in range(3):
				var y = 210.0 + row * 75
				canvas.draw_line(Vector2(55, y), Vector2(1225, y), Color("62d2d8", 0.10), 1, true)
				for i in range(4):
					var x = 55 + fposmod(i * 305.0 + time * (25 + row * 13), 1170)
					canvas.draw_line(Vector2(x - 17, y), Vector2(x, y), Color("a4f8ef", 0.4), 3, true)
		"desktop":
			_paint_desktop(canvas,time)
		"quarry":
			_paint_quarry(canvas,time)
		"glitch":
			_paint_glitch(canvas,time)


func _paint_arcade(canvas: Node2D, time: float) -> void:
	## The toy crane watches the round: tiny prizes bob, blink and lean toward
	## the action while the machine's bulbs chase in the distance.
	var machine_glow := 0.12 + 0.05 * sin(time * 2.0)
	for i in range(9):
		var x := 22.0 + float(i) * 26.0
		var blink := 0.34 + 0.35 * maxf(0.0,sin(time * 3.1 + float(i) * 0.85))
		canvas.draw_circle(Vector2(x,102),4.0,Color("ffd37d",blink))
		canvas.draw_circle(Vector2(x,102),1.4,Color("fff0bc",blink + 0.2))
	# Four little plush doodles are deliberately small enough to stay behind the
	# fighters and read as prizes through the glass at the left of the scene.
	var toy_data = [
		[Vector2(62,245),Color("f6a85c"),0.92],
		[Vector2(111,224),Color("80c9ef"),1.02],
		[Vector2(157,260),Color("f18bbb"),0.86],
		[Vector2(204,215),Color("9ddf8c"),0.78]
	]
	for i in range(toy_data.size()):
		var item = toy_data[i]
		var phase := time * (0.85 + float(i) * 0.07) + float(i) * 1.9
		var bob := sin(phase) * (3.0 + float(i % 2) * 1.8)
		var sway := sin(phase * 0.72 + 0.6) * (0.045 + float(i) * 0.006)
		var blink := sin(time * (2.15 + i * 0.19) + i * 2.5) > 0.88
		_draw_arcade_toy(canvas,item[0] + Vector2(0,bob),float(item[2]),item[1],blink,sway)
	# A slow claw pass makes the glass box feel inhabited without touching play.
	var claw_x := 113.0 + sin(time * 0.33) * 59.0
	var claw_y := 129.0 + (0.5 + 0.5 * sin(time * 0.21 + 1.2)) * 54.0
	canvas.draw_line(Vector2(claw_x,77),Vector2(claw_x,claw_y),Color("f5dca6",0.35),2.0,true)
	canvas.draw_circle(Vector2(claw_x,claw_y),4.0,Color("e9c27d",0.44))
	for side in [-1,1]:
		canvas.draw_polyline(PackedVector2Array([
			Vector2(claw_x,claw_y),Vector2(claw_x + side * 7.0,claw_y + 9.0),
			Vector2(claw_x + side * 3.0,claw_y + 14.0)]),Color("e9c27d",0.42),1.6,true)
	# The big wheel in the distance keeps a quiet rotating rhythm.
	var center := Vector2(1014,228)
	for i in range(10):
		var angle := time * 0.08 + float(i) * TAU / 10.0
		var p := center + Vector2.from_angle(angle) * 69.0
		canvas.draw_line(center,p,Color("bd88b8",0.12),1.0,true)
		canvas.draw_circle(p,3.0,Color("ffbd7c",0.42))
	for i in range(8):
		var p := Vector2(fposmod(float(i) * 163.0 + time * 28.0,1160.0) + 60.0,174.0 + float(i % 2) * 130.0)
		canvas.draw_arc(p,5.0,0,TAU,12,Color("ffe080",0.30),2.0,true)
	canvas.draw_rect(Rect2(18,121,218,188),Color("d8b7d8",machine_glow * 0.20),false,1.0,true)


func _draw_arcade_toy(canvas: Node2D, center: Vector2, scale: float, tint: Color, blink: bool, sway: float) -> void:
	var head := center + Vector2(0,-16.0 * scale)
	var body := center + Vector2(0,7.0 * scale)
	var r := 13.0 * scale
	var outline := Color("171424",0.84)
	canvas.draw_circle(head,r + 3.0,Color(outline,0.55))
	canvas.draw_circle(head,r,Color(tint,0.78))
	canvas.draw_arc(head,r,0,TAU,18,outline,1.8,true)
	canvas.draw_line(head + Vector2(-r * 0.75,10.0 * scale),body + Vector2(-9.0 * scale,2.0),outline,3.2,true)
	canvas.draw_line(head + Vector2(r * 0.75,10.0 * scale),body + Vector2(9.0 * scale,2.0),outline,3.2,true)
	canvas.draw_line(body + Vector2(-8.0 * scale,2.0),body + Vector2(-12.0 * scale,20.0),outline,3.0,true)
	canvas.draw_line(body + Vector2(8.0 * scale,2.0),body + Vector2(12.0 * scale,20.0),outline,3.0,true)
	if blink:
		canvas.draw_line(head + Vector2(-7.0 * scale,-1.0),head + Vector2(-2.0 * scale,-1.0),outline,1.6,true)
		canvas.draw_line(head + Vector2(2.0 * scale,-1.0),head + Vector2(7.0 * scale,-1.0),outline,1.6,true)
	else:
		canvas.draw_circle(head + Vector2(-5.0 * scale,-1.5),1.8 * scale,Color("fff1c7",0.85))
		canvas.draw_circle(head + Vector2(5.0 * scale,-1.5),1.8 * scale,Color("fff1c7",0.85))
	canvas.draw_arc(head + Vector2(0,4.0 * scale),4.0 * scale,0.18,PI-0.18,8,outline,1.2,true)
	# A tiny lean makes the plushies feel like they are peeking at the players.
	if absf(sway) > 0.001:
		canvas.draw_line(center + Vector2(-15.0 * scale,10),center + Vector2(-19.0 * scale,7) + Vector2(sway * 20.0,0),Color(tint,0.5),2.0,true)


func _paint_desktop(canvas: Node2D, time: float) -> void:
	## The two monitors run a tiny drawing program: type a line, sketch a
	## doodle, blink the caret, then start over. It is all cosmetic scenery.
	var left := Rect2(47,111,360,301)
	var right := Rect2(1041,116,212,290)
	_draw_typed_screen(canvas,left,["HELLO, DESKTOP!","DRAW / FIGHT / REPEAT","save_star.tmp"],time,0.0,Color("8fd0ff"))
	_draw_typed_screen(canvas,right,["ink.exe","typing...",":)"],time,1.7,Color("f2c690"))
	var paths = [
		PackedVector2Array([Vector2(102,324),Vector2(121,294),Vector2(139,326),Vector2(157,290),Vector2(174,324)]),
		PackedVector2Array([Vector2(1100,316),Vector2(1118,289),Vector2(1142,312),Vector2(1162,284),Vector2(1190,319)]),
	]
	for i in range(paths.size()):
		var path: PackedVector2Array = paths[i]
		var progress := fposmod(time * 0.24 + float(i) * 0.43,1.0)
		var count := clampi(2 + int(progress * float(path.size()-1)),2,path.size())
		var visible := PackedVector2Array()
		for p in range(count): visible.append(path[p])
		canvas.draw_polyline(visible,Color("edb77d",0.62),1.8,true)
		if not visible.is_empty():
			canvas.draw_circle(visible[visible.size()-1],2.4,Color("fff1bf",0.7))
	# A loose sheet glides past the window every few seconds.
	var paper := Vector2(fposmod(time * 18.0,1120.0) + 80.0,244.0 + sin(time * 0.25) * 35.0)
	canvas.draw_colored_polygon(PackedVector2Array([paper,paper + Vector2(-27,-10),paper + Vector2(-19,8)]),Color("f1dfcf",0.4))
	canvas.draw_line(paper,paper + Vector2(-19,2),Color("756a8a",0.35),1.0,true)


func _draw_typed_screen(canvas: Node2D, rect: Rect2, lines: Array, time: float, phase: float, tint: Color) -> void:
	canvas.draw_rect(rect,Color("16213a",0.10),true)
	var line_index := int(fposmod(time * 0.55 + phase, float(lines.size())))
	var char_count := int(fposmod(time * 8.0 + phase * 5.0, float(str(lines[line_index]).length() + 1)))
	for i in range(lines.size()):
		var text := str(lines[(line_index + i) % lines.size()])
		var reveal := text.length() if i != 0 else char_count
		var visible := text.substr(0,reveal)
		var at := rect.position + Vector2(20.0,47.0 + i * 25.0)
		canvas.draw_string(HandFont,at,visible,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(tint,0.72 if i == 0 else 0.40))
		if i == 0 and fmod(time + phase,1.0) < 0.56:
			var cursor_x := at.x + 3.0 + float(visible.length()) * 7.1
			canvas.draw_line(Vector2(cursor_x,at.y-13),Vector2(cursor_x,at.y+2),Color(tint,0.78),1.6,true)
	# A few scanlines keep the monitor alive without competing with the fighters.
	for i in range(5):
		var y := rect.position.y + 12.0 + float(i) * 51.0 + sin(time * 1.3 + i) * 2.0
		canvas.draw_line(Vector2(rect.position.x+8,y),Vector2(rect.end.x-9,y),Color(tint,0.10),1.0,true)


func _paint_quarry(canvas: Node2D, time: float) -> void:
	## The crane cycles a gentle lift and sway. Birds cross the open sky, perch
	## for a beat, then launch again so the quarry never feels like a still card.
	var arm_a := Vector2(1004,83)
	var arm_b := Vector2(1228,38)
	var trolley := Vector2(1138 + sin(time * 0.38) * 51.0,96.0)
	canvas.draw_line(arm_a,arm_b,Color("2d2737",0.42),5.0,true)
	canvas.draw_line(arm_a + Vector2(0,7),arm_b + Vector2(0,7),Color("efb968",0.36),1.6,true)
	canvas.draw_circle(trolley,7.0,Color("3b303c",0.85))
	var load_y := 154.0 + (0.5 + 0.5 * sin(time * 0.52 + 0.6)) * 42.0
	canvas.draw_line(Vector2(trolley.x,101),Vector2(trolley.x,load_y-4),Color("292535",0.76),2.0,true)
	var cargo := PackedVector2Array([Vector2(trolley.x-27,load_y),Vector2(trolley.x+27,load_y+2),Vector2(trolley.x+23,load_y+34),Vector2(trolley.x-23,load_y+32)])
	canvas.draw_colored_polygon(cargo,Color("8b7884",0.68))
	canvas.draw_polyline(PackedVector2Array([cargo[0],cargo[1],cargo[2],cargo[3],cargo[0]]),Color("292535",0.72),2.0,true)
	canvas.draw_line(Vector2(trolley.x-19,load_y+10),Vector2(trolley.x+17,load_y+11),Color("ffd880",0.42),1.4,true)
	var hook := Vector2(trolley.x,load_y+38)
	canvas.draw_arc(hook + Vector2(0,3),7.0,0,PI,10,Color("292535",0.78),2.0,true)
	for i in range(3):
		var cycle := fposmod(time * 0.22 + float(i) * 3.65,12.0)
		var p := Vector2.ZERO
		var resting := false
		if cycle < 6.2:
			p = Vector2(fposmod(cycle * (74.0 + i * 8.0) + float(i) * 270.0,1160.0) + 44.0,116.0 + float(i % 2) * 44.0 + sin(time * 1.1 + i) * 12.0)
		elif cycle < 8.7:
			resting = true
			p = Vector2(173.0 + float(i) * 390.0,178.0 + float(i % 2) * 20.0)
		else:
			var depart := (cycle-8.7)/3.3
			p = Vector2(173.0 + float(i) * 390.0 + depart * 270.0,178.0 - depart * 94.0)
		_draw_quarry_bird(canvas,p,time * 2.2 + float(i) * 1.8,resting)
	for i in range(10):
		var p := Vector2(624.0 + sin(i * 2.1) * 17.0,310.0 + fposmod(i * 23.0 + time * 40.0,180.0))
		canvas.draw_line(p,p + Vector2(-1,11),Color("e2e4fc",0.18),1.4,true)


func _draw_quarry_bird(canvas: Node2D, p: Vector2, phase: float, resting: bool) -> void:
	var ink := Color("2a2635",0.68)
	if resting:
		canvas.draw_circle(p + Vector2(0,2),4.0,Color("5b5366",0.68))
		canvas.draw_polyline(PackedVector2Array([p + Vector2(-9,5),p + Vector2(0,1),p + Vector2(9,5)]),ink,2.0,true)
		canvas.draw_line(p + Vector2(0,5),p + Vector2(-1,11),ink,1.2,true)
		return
	var flap := sin(phase) * 6.0
	canvas.draw_polyline(PackedVector2Array([p + Vector2(-13,-flap),p,p + Vector2(13,-flap)]),Color("e5d9bc",0.62),2.0,true)
	canvas.draw_circle(p,2.3,Color("2a2635",0.68))


func _paint_glitch(canvas: Node2D, time: float) -> void:
	## The core's monitors are intentionally imperfect: scan bars jump, neon
	## labels lose a letter, and the portal pulses behind the boss arena.
	var screen := Rect2(438,108,407,285)
	canvas.draw_rect(screen,Color("071327",0.18),true)
	var flicker := 0.5 + 0.5 * sin(time * 6.7)
	canvas.draw_string(HandFont,Vector2(499,167),"// SAVE STAR //",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("d88cff",0.42 + flicker * 0.25))
	canvas.draw_string(HandFont,Vector2(510,200),"SYSTEM_FAIL",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("67e4ff",0.42 + (1.0-flicker) * 0.22))
	canvas.draw_string(HandFont,Vector2(507,231),"H4CK3R ONLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f2b5ff",0.36 + flicker * 0.25))
	for i in range(15):
		var gate := sin(time * (2.8 + i * 0.11) + i * 1.7)
		if gate < -0.22: continue
		var y := screen.position.y + 28.0 + float(i) * 16.0 + sin(time * 3.0 + i) * 4.0
		var x := screen.position.x + 12.0 + fposmod(float(i) * 53.0 + time * (18.0 + i),362.0)
		var width := 13.0 + fposmod(float(i) * 29.0 + time * 41.0,67.0)
		canvas.draw_rect(Rect2(x,y,minf(width,screen.end.x-x-8),3.0),Color("a66bff",0.22 + gate * 0.18),true)
		if i % 4 == 0:
			canvas.draw_rect(Rect2(x-7,y+5,8,4),Color("56dfff",0.52),true)
	# A neon sign on the right flickers like a stubborn arcade marquee.
	var sign := Rect2(949,124,193,61)
	var sign_alpha := 0.22 + 0.16 * maxf(0.0,sin(time * 4.7 + 0.8))
	canvas.draw_rect(sign,Color("241640",0.58),true)
	canvas.draw_polyline(PackedVector2Array([Vector2(sign.position.x-4,sign.position.y),Vector2(sign.end.x+4,sign.position.y),Vector2(sign.end.x+1,sign.end.y),Vector2(sign.position.x-3,sign.end.y),Vector2(sign.position.x-4,sign.position.y)]),Color("e28bff",sign_alpha + 0.22),2.4,true)
	var sign_text := "GLITCH" if sin(time * 5.3) > -0.45 else "GL1TCH"
	canvas.draw_string(HandFont,Vector2(sign.position.x+28,sign.position.y+39),sign_text,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e28bff",sign_alpha + 0.35))
	for i in range(16):
		var p := Vector2(905 + cos(i * TAU / 16.0 + time * 0.15) * 97.0,259 + sin(i * TAU / 16.0 + time * 0.15) * 88.0)
		canvas.draw_rect(Rect2(p,Vector2(4,3)),Color("c48bff",0.28),true)


func _paint_canopy(canvas: Node2D, time: float) -> void:
	## Lanterns breathe, paper cranes flap, and a short gust rolls through the
	## leaves every few seconds. These marks stay above the arena floor.
	var gust := pow(maxf(0.0,sin(time * 0.43 + 0.7)),6.0)
	_draw_canopy_jar(canvas,Vector2(83,115),0.95,time * 1.4)
	_draw_canopy_jar(canvas,Vector2(1193,129),0.82,time * 1.1 + 1.8)
	var crane_positions = [Vector2(808,126),Vector2(932,93),Vector2(1049,169)]
	for i in range(crane_positions.size()):
		var base: Vector2 = crane_positions[i]
		var p := base + Vector2(sin(time * 0.42 + i) * 10.0,cos(time * 0.55 + i * 1.3) * 5.0)
		_draw_paper_crane(canvas,p,time * 2.3 + i * 1.4)
	# Top leaves and the side plants lean only during the passing gust.
	for i in range(12):
		var x := 40.0 + float(i) * 106.0
		var y := 28.0 + float(i % 3) * 22.0
		var lean := sin(time * 0.72 + i * 0.8) * (2.0 + gust * 12.0)
		_draw_leaf(canvas,Vector2(x,y),Vector2(20.0 + (i % 3) * 5.0,38.0 + (i % 2) * 7.0),lean,Color("6d9d63",0.53))
	for i in range(7):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := 44.0 if side < 0 else 1233.0
		var y := 340.0 + float(i) * 33.0
		var lean := side * (sin(time * 0.65 + i) * 3.0 + gust * 12.0)
		_draw_leaf(canvas,Vector2(x,y),Vector2(15.0,28.0),lean,Color("7da56b",0.45))
	for i in range(5):
		var from := Vector2(205.0 + i * 185.0,195.0 + (i % 2) * 30.0)
		var drift := Vector2(32.0 + gust * 28.0,4.0 * sin(time * 1.2 + i))
		canvas.draw_line(from,from + drift,Color("f4e7bd",0.16 + gust * 0.16),1.2,true)
	# Preserve the original warm floating lights in the distance.
	for i in range(14):
		var p := Vector2(75.0 + i * 86.0 + sin(time * 0.5 + i) * 13.0,220.0 + i % 5 * 57.0 + cos(time * 0.7 + i) * 12.0)
		canvas.draw_circle(p,5.0,Color("ffdc83",0.035))
		canvas.draw_circle(p,1.4,Color("ffdc83",0.36))


func _draw_canopy_jar(canvas: Node2D, p: Vector2, scale: float, phase: float) -> void:
	var flicker := 0.46 + 0.22 * sin(phase * 2.1) + 0.09 * sin(phase * 5.2)
	var size := Vector2(24.0,37.0) * scale
	canvas.draw_line(p + Vector2(0,-29.0 * scale),p + Vector2(0,-size.y * 0.5 - 4.0),Color("342b31",0.65),1.5,true)
	canvas.draw_rect(Rect2(p - size * 0.5,size),Color("b9d8b2",0.14),true)
	canvas.draw_polyline(PackedVector2Array([p + Vector2(-size.x*0.5,-size.y*0.5),p + Vector2(size.x*0.5,-size.y*0.5),p + Vector2(size.x*0.5,size.y*0.5),p + Vector2(-size.x*0.5,size.y*0.5),p + Vector2(-size.x*0.5,-size.y*0.5)]),Color("2b2932",0.54),1.6,true)
	canvas.draw_circle(p + Vector2(0,2.0 * scale),7.0 * scale,Color("ffeaa1",flicker))
	canvas.draw_circle(p + Vector2(0,2.0 * scale),13.0 * scale,Color("ffd26f",flicker * 0.12))
	canvas.draw_line(p + Vector2(-size.x*0.35,0),p + Vector2(-size.x*0.35,size.y*0.38),Color("fff2c4",0.26),1.0,true)


func _draw_paper_crane(canvas: Node2D, p: Vector2, phase: float) -> void:
	var flap := sin(phase) * 7.0
	var paper := Color("e8dfc4",0.55)
	var ink := Color("403648",0.64)
	var body := PackedVector2Array([p + Vector2(-4,0),p + Vector2(18,-9),p + Vector2(7,6),p + Vector2(26,10),p + Vector2(2,8)])
	canvas.draw_colored_polygon(body,paper)
	canvas.draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[0]]),ink,1.6,true)
	canvas.draw_polyline(PackedVector2Array([p + Vector2(1,2),p + Vector2(-21,-flap),p + Vector2(-7,5)]),paper,2.8,true)
	canvas.draw_polyline(PackedVector2Array([p + Vector2(8,2),p + Vector2(32,flap),p + Vector2(18,7)]),paper,2.8,true)
	canvas.draw_line(p + Vector2(20,-9),p + Vector2(35,-12),ink,1.5,true)


func _draw_leaf(canvas: Node2D, p: Vector2, size: Vector2, lean: float, tint: Color) -> void:
	var tip := p + Vector2(lean,-size.y)
	var points := PackedVector2Array([p,p + Vector2(size.x * 0.65,-size.y * 0.42) + Vector2(lean * 0.35,0),tip,p + Vector2(-size.x * 0.56,-size.y * 0.28) + Vector2(lean * 0.2,0)])
	canvas.draw_colored_polygon(points,tint)
	canvas.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color("1d2d2a",0.44),1.2,true)
	canvas.draw_line(p,tip,Color("d6d29b",0.32),1.0,true)
