extends Node2D
## Draw-only Doodle Rally world. The race simulation owns progress and collision.
## Public contract: setup(curve, course), update_race(racers, race_time, reduced_motion), add_event(event).

const RacerArt := preload("res://scripts/racer_art.gd")
const INK := Color("26384b")
const PAPER := Color("fff9e9")
const ROAD := Color("fff7dc")
const SAFE_RECT := Rect2(130, 220, 1020, 330)
const ROAD_HALF := 46.0

var curve: Curve2D
var course: Dictionary = {}
var theme := "desk"
var stamps: Array = []
var racers: Array = []
var race_time := 0.0
var reduced_motion := false
var road_points := PackedVector2Array()
var track_length := 1.0
var cars: Array[Node2D] = []
var events: Array[Dictionary] = []
var _clock := 0.0

func setup(new_curve: Curve2D, new_course: Dictionary) -> void:
	curve = new_curve
	course = new_course.duplicate(true)
	theme = str(course.get("theme", _theme_from_name(str(course.get("name", "")))))
	if theme not in ["desk", "castle", "sky"]:
		theme = "desk"
	stamps = course.get("stamps", [])
	if curve != null:
		road_points = curve.get_baked_points()
		track_length = maxf(1.0, curve.get_baked_length())
	queue_redraw()

func update_race(new_racers: Array, new_race_time: float, new_reduced_motion: bool) -> void:
	racers = new_racers.duplicate(true)
	race_time = new_race_time
	reduced_motion = new_reduced_motion
	_clock = 0.0 if reduced_motion else race_time
	while cars.size() > racers.size():
		var last: Node2D = cars.pop_back()
		last.queue_free()
	while cars.size() < racers.size():
		var car: Node2D = RacerArt.new()
		car.z_index = 3
		add_child(car)
		cars.append(car)
	for index in range(racers.size()):
		var racer: Dictionary = racers[index]
		var car: Node2D = cars[index]
		car.configure(int(racer.get("style", index % 3)), _color_value(racer.get("color", Color("f59736"))))
		car.is_player = bool(racer.get("human", racer.get("is_human", false)))
		car.sticker = str(racer.get("sticker", "plain"))
		var distance := float(racer.get("distance", 0.0))
		car.position = _position(distance, float(racer.get("lane", 0.0)))
		car.heading = float(racer.get("heading", _tangent(distance).angle()))
		car.hop = float(racer.get("hop", 0.0))
		car.boosting = float(racer.get("turbo", racer.get("boost", 0.0))) > 0.01
		car.drift = float(racer.get("drift", 0.0))
		car.turn_lean = float(racer.get("turn_lean",0.0))
		car.speed = float(racer.get("speed", 0.0))
		car.motion_time = race_time
		car.reduced_motion = reduced_motion
		car.queue_redraw()
	queue_redraw()

func add_event(event: Dictionary) -> void:
	var copy := event.duplicate(true)
	copy["life"] = float(copy.get("life", 0.7))
	if not copy.has("position"):
		var marker := float(copy.get("u", -1.0))
		if marker >= 0.0 and marker <= 1.0:
			copy["position"] = _position(marker * track_length, float(copy.get("lane", 0.0)))
		else:
			var racer_index := int(copy.get("racer", 0))
			if racer_index >= 0 and racer_index < racers.size():
				var racer: Dictionary = racers[racer_index]
				copy["position"] = _position(float(racer.get("distance", 0.0)), float(racer.get("lane", 0.0)))
			else:
				copy["position"] = Vector2(640, 400)
	copy["created"] = race_time
	if str(copy.get("kind","")) in ["gate_toggle","race_complete","challenge_failed","final_lap"]: return
	events.append(copy)
	if events.size()>100: events.pop_front()
	queue_redraw()

func _process(delta: float) -> void:
	if not reduced_motion:
		_clock += delta
	for event in events:
		event["life"] = float(event.get("life", 0.0)) - delta
	for index in range(events.size() - 1, -1, -1):
		if float(events[index].get("life", 0.0)) <= 0.0 or race_time-float(events[index].get("created",race_time))>0.75:
			events.remove_at(index)
	if not reduced_motion or not events.is_empty():
		queue_redraw()

func _draw() -> void:
	_draw_backdrop()
	if road_points.size() < 2:
		return
	_draw_landscape()
	_draw_road()
	_draw_stamps()
	_draw_events()

func _draw_backdrop() -> void:
	var sky := Color("dff0f6") if theme == "sky" else (Color("f4e2b8") if theme == "castle" else Color("e7eff0"))
	draw_rect(Rect2(0, 145, 1280, 490), sky)
	for y in range(157, 632, 28):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.2, 0.31, 0.39, 0.08), 1.0)
	# Imperfect border keeps the race inside the page, leaving UI bands untouched.
	draw_style_box(_box(Color(1,1,1,0.16), 23, 0), Rect2(38, 165, 1204, 448))

func _draw_landscape() -> void:
	match theme:
		"desk":
			_draw_desk_world()
		"castle":
			_draw_castle_world()
		"sky":
			_draw_sky_world()

func _draw_desk_world() -> void:
	_draw_sketchbook(Vector2(349,375))
	_draw_sketchbook(Vector2(922,392),true)
	# Ruler bridge, penciltops, post-its and a mug make it feel like a desk toy race.
	draw_style_box(_box(Color("d7b26c"), 4, 3), Rect2(106, 182, 316, 32))
	for x in range(125, 407, 20):
		draw_line(Vector2(x, 184), Vector2(x, 195 if x % 40 else 207), INK, 1.4)
	draw_string(ThemeDB.fallback_font, Vector2(132, 205), "RULER BRIDGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
	_draw_mug(Vector2(1128, 202), Color("80c8d0"))
	for at in [Vector2(84, 530), Vector2(1190, 525), Vector2(530, 192)]:
		_draw_pencil(at, -0.28)
	_draw_note(Vector2(975, 184), "DRAW\nFAST!", Color("ffd57b"), -0.12)
	_draw_note(Vector2(77, 300), "WHEE!", Color("f3a6b7"), 0.12)

func _draw_castle_world() -> void:
	_draw_castle_landmark(Vector2(340,397))
	_draw_castle_landmark(Vector2(922,398),true)
	# Cardboard towers and crayon pennants sit outside the collision road.
	for at in [Vector2(83, 244), Vector2(1165, 265), Vector2(906, 570)]:
		_draw_tower(at)
	for at in [Vector2(360, 189), Vector2(734, 580), Vector2(1110, 420)]:
		draw_line(at, at + Vector2(0, 31), INK, 2.0)
		var flag := PackedVector2Array([at, at + Vector2(28, 8), at + Vector2(0, 16)])
		draw_colored_polygon(flag, Color("ed7569"))
		flag.append(flag[0])
		draw_polyline(flag, INK, 2.0, true)
	_draw_note(Vector2(500, 182), "BIG\nTURN!", Color("a9d590"), -0.08)

func _draw_sky_world() -> void:
	_draw_paper_kite(Vector2(344,380))
	for i in range(5):
		draw_arc(Vector2(925,415),63+i*7,PI,TAU,32,[Color("f19d9e"),Color("f4c989"),Color("d9d594"),Color("92c8b9"),Color("97b5d2")][i],7,true)
	_draw_cloud(Vector2(849,413))
	_draw_cloud(Vector2(1004,413))
	for at in [Vector2(155, 195), Vector2(350, 550), Vector2(1000, 190), Vector2(1160, 540), Vector2(660, 190)]:
		_draw_cloud(at)
	for x in range(120, 1180, 143):
		var base := Vector2(x, 580 + sin(float(x)) * 14.0)
		draw_line(base, base + Vector2(0, -30), Color("8fbfd2"), 2.0)
		draw_line(base + Vector2(0, -30), base + Vector2(17, -42), Color("8fbfd2"), 1.5)
		_draw_star(base + Vector2(20, -45), 7, Color("ffd76a"), _clock * 0.8)
	_draw_note(Vector2(94, 198), "CLOUD\nLANE", Color("b6dcf1"), 0.08)

func _draw_road() -> void:
	draw_polyline(road_points, Color(0.09, 0.14, 0.20, 0.28), ROAD_HALF * 2 + 13, true)
	draw_polyline(road_points, INK, ROAD_HALF * 2 + 7, true)
	draw_polyline(road_points, ROAD, ROAD_HALF * 2, true)
	for distance in range(0, int(track_length), 48):
		var from := _position(float(distance), 0.0)
		var to := _position(float(distance + 20), 0.0)
		draw_line(from, to, Color("b3aab9"), 2.5, true)
	_draw_finish_line()

func _draw_finish_line() -> void:
	var origin := _position(0.0, 0.0)
	var tangent := _tangent(0.0)
	var normal := Vector2(-tangent.y, tangent.x)
	for row in range(2):
		for col in range(8):
			var center := origin + tangent * (row * 10.0 - 5.0) + normal * (col * 11.5 - 40.0)
			var corners := PackedVector2Array([center - tangent * 5 - normal * 5.7, center + tangent * 5 - normal * 5.7, center + tangent * 5 + normal * 5.7, center - tangent * 5 + normal * 5.7])
			draw_colored_polygon(corners, INK if (row + col) % 2 == 0 else PAPER)
	_draw_lane_tags()

func _draw_lane_tags() -> void:
	for racer in racers:
		if not racer is Dictionary or not bool(racer.get("human", racer.get("is_human", false))):
			continue
		var at := _position(float(racer.get("distance",0.0)),float(racer.get("lane",0.0)))+Vector2(-15,-43)
		draw_style_box(_box(Color("fff7dc"),5,2),Rect2(at,Vector2(30,19)))
		draw_string(ThemeDB.fallback_font,at+Vector2(5,14),"P%d" % (int(racer.get("slot",0))+1),HORIZONTAL_ALIGNMENT_CENTER,20,12,INK)

func _draw_stamps() -> void:
	for stamp_index in range(stamps.size()):
		var stamp: Variant = stamps[stamp_index]
		if not stamp is Dictionary:
			continue
		if _stamp_collected(stamp_index):
			continue
		var at := _position(float(stamp.get("u", 0.0)) * track_length, float(stamp.get("lane", 0.0)))
		match str(stamp.get("kind", "star")):
			"ramp": _draw_ramp(at)
			"boost": _draw_boost(at)
			"puddle": _draw_puddle(at)
			"gate": _draw_gate(at, bool(stamp.get("active", true)), float(stamp.get("phase", 0.0)))
			"wind": _draw_wind(at)
			_: _draw_star(at, 11.0, Color("ffd55d"), _clock)

func _stamp_collected(stamp_index: int) -> bool:
	if str(stamps[stamp_index].get("kind","")) != "star": return false
	var any_human := false
	for racer in racers:
		if not racer.get("human",false): continue
		any_human=true
		var lap := mini(1,maxi(0,int(float(racer.distance)/track_length)))
		if not racer.get("collected_stars",[]).has(lap*stamps.size()+stamp_index): return false
	return any_human

func _draw_events() -> void:
	for event in events:
		var at := Vector2(event.get("position", Vector2.ZERO))
		var life := clampf(float(event.get("life", 0.0)), 0.0, 1.0)
		match str(event.get("kind", "puff")):
			"boost":
				draw_circle(at, 18 + (1.0-life)*32, Color(1.0,0.69,0.20,life*0.25))
			"splash":
				for i in range(5): draw_circle(at + Vector2(cos(i*1.26),sin(i*1.26))*((1.0-life)*32+8), 4, Color(0.35,0.70,0.87,life))
			"overtake", "drift_boost":
				for i in range(3): draw_line(at+Vector2(-20,i*8-8),at+Vector2(14+(1.0-life)*26,i*8-8),Color("ffd462",life),2.5,true)
			"finish", "race_complete":
				_draw_star(at,12+(1.0-life)*13,Color(1.0,0.82,0.35,life),_clock)
			_:
				draw_circle(at, 10+(1.0-life)*18, Color(1,1,1,life*0.3))

func _position(distance: float, lane: float) -> Vector2:
	if curve == null:
		return Vector2(640, 400)
	var d := fposmod(distance, track_length)
	var center := curve.sample_baked(d, true)
	var tangent := _tangent(d)
	return center + Vector2(-tangent.y, tangent.x) * clampf(lane, -38.0, 38.0)

func _tangent(distance: float) -> Vector2:
	if curve == null: return Vector2.RIGHT
	var behind := curve.sample_baked(fposmod(distance - 3.0, track_length), true)
	var ahead := curve.sample_baked(fposmod(distance + 3.0, track_length), true)
	return (ahead - behind).normalized()

func _theme_from_name(name: String) -> String:
	if name.to_lower().contains("sky"): return "sky"
	if name.to_lower().contains("castle"): return "castle"
	return "desk"

func _color_value(value: Variant) -> Color:
	if value is Color: return value
	if value is String: return Color(value)
	return Color("f59736")

func _box(color: Color, radius: int, border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	return box

func _draw_star(at: Vector2, radius: float, color: Color, angle: float) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		points.append(at + Vector2(cos(angle + i*PI/5.0-PI/2), sin(angle + i*PI/5.0-PI/2)) * (radius if i % 2 == 0 else radius*0.48))
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, INK, 1.7, true)

func _draw_ramp(at: Vector2) -> void:
	var p := PackedVector2Array([at+Vector2(-18,12),at+Vector2(15,12),at+Vector2(8,-13)])
	draw_colored_polygon(p, Color("ff9d52")); p.append(p[0]); draw_polyline(p, INK, 2.0, true)
	for x in range(-12, 12, 8): draw_line(at+Vector2(x,9), at+Vector2(x+5,-2), Color("fff1bb"), 1.4)

func _draw_boost(at: Vector2) -> void:
	draw_circle(at, 16, Color("ffd94f")); draw_arc(at,16,0,TAU,16,INK,2.0,true)
	for i in range(3): draw_line(at+Vector2(-8, -7+i*7),at+Vector2(11,-7+i*7),Color("f08a38"),2.5)

func _draw_puddle(at: Vector2) -> void:
	for i in range(3): _draw_oval(at+Vector2(i*8-8, sin(i)*3),Vector2(12,6),Color("69b9d4"))
	draw_arc(at,18,0,TAU,16,INK,1.7,true)

func _draw_gate(at: Vector2, active: bool, phase: float) -> void:
	var warning := not active and phase > 0.78
	var color := Color("ee745f") if active else Color("efb54d") if warning else Color("79b990")
	for side in [-1.0,1.0]:
		draw_style_box(_box(Color("caa369"),2,2),Rect2(at+Vector2(side*23-4,-18),Vector2(8,36)))
	if active:
		draw_style_box(_box(color,2,2),Rect2(at+Vector2(-23,-7),Vector2(46,14)))
		for x in range(-18,23,12): draw_line(at+Vector2(x,-5),at+Vector2(x-7,5),PAPER,3,true)
	else:
		draw_line(at+Vector2(-23,-3),at+Vector2(-23,-30),color,8,true)
		draw_line(at+Vector2(23,-3),at+Vector2(23,-30),color,8,true)
	draw_circle(at+Vector2(0,-22),5,color)
	draw_string(ThemeDB.fallback_font,at+Vector2(-22,33),"HOP!" if active else "WAIT!" if warning else "GO!",HORIZONTAL_ALIGNMENT_CENTER,46,10,INK)

func _draw_wind(at: Vector2) -> void:
	for i in range(3): draw_arc(at+Vector2(-10+i*10,0),8+i*3,-1.1,1.1,10,Color("71b7e4"),2.0,true)

func _draw_oval(at: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20): points.append(at+Vector2(cos(i*TAU/20.0),sin(i*TAU/20.0))*radii)
	draw_colored_polygon(points,color)

func _draw_mug(at: Vector2, color: Color) -> void:
	draw_style_box(_box(color,8,3),Rect2(at-Vector2(22,16),Vector2(40,35)))
	draw_arc(at+Vector2(22,0),11,-PI/2,PI/2,12,INK,3.0,true)
	draw_string(ThemeDB.fallback_font,at+Vector2(-15,5),"GO!",HORIZONTAL_ALIGNMENT_CENTER,30,12,INK)

func _draw_pencil(at: Vector2, angle: float) -> void:
	var axis := Vector2(cos(angle),sin(angle)); var normal := Vector2(-axis.y,axis.x)
	var end := at + axis*43
	draw_line(at,end,Color("f0ad48"),8.0); draw_line(at,end,INK,2.0)
	var tip := PackedVector2Array([end+axis*9,end-normal*5,end+normal*5]); draw_colored_polygon(tip,Color("f7ddb7")); tip.append(tip[0]); draw_polyline(tip,INK,1.6,true)

func _draw_note(at: Vector2, words: String, color: Color, angle: float) -> void:
	draw_set_transform(at,angle)
	draw_style_box(_box(color,3,2),Rect2(-30,-20,60,43))
	for i in range(words.split("\n").size()):
		draw_string(ThemeDB.fallback_font,Vector2(-24,-4+i*14),words.split("\n")[i],HORIZONTAL_ALIGNMENT_CENTER,48,11,INK)
	draw_set_transform(Vector2.ZERO)

func _draw_tower(at: Vector2) -> void:
	draw_style_box(_box(Color("e8c37c"),3,3),Rect2(at-Vector2(20,37),Vector2(40,66)))
	var roof := PackedVector2Array([at+Vector2(-25,-37),at+Vector2(0,-62),at+Vector2(25,-37)])
	draw_colored_polygon(roof,Color("df7590"));roof.append(roof[0]);draw_polyline(roof,INK,2.5,true)
	draw_arc(at+Vector2(0,-10),7,PI,TAU,10,INK,2,true)

func _draw_cloud(at: Vector2) -> void:
	for offset in [Vector2(-18,2),Vector2(0,-8),Vector2(19,2),Vector2(4,8)]: draw_circle(at+offset,15,Color("fffdf5"))

func _draw_sketchbook(at: Vector2, small: bool=false) -> void:
	draw_set_transform(at,-0.08 if not small else 0.09,Vector2.ONE*(0.78 if small else 1.0))
	draw_style_box(_box(Color("adbdc6"),4,2),Rect2(-94,-48,188,99))
	draw_style_box(_box(Color("fffdf0"),3,2),Rect2(-92,-53,184,97))
	draw_line(Vector2(0,-50),Vector2(0,42),Color("d3c9b7"),2)
	for y in range(-43,43,13):
		draw_line(Vector2(-78,y),Vector2(-13,y),Color("e3ddc7"),1)
		draw_arc(Vector2(-89,y),4,-PI/2,PI/2,8,INK,2,true)
	draw_string(ThemeDB.fallback_font,Vector2(-76,-26),"MY NEXT",HORIZONTAL_ALIGNMENT_LEFT,73,12,INK)
	draw_string(ThemeDB.fallback_font,Vector2(-76,-10),"BIG IDEA",HORIZONTAL_ALIGNMENT_LEFT,73,12,INK)
	_draw_star(Vector2(43,-7),25,Color("f1cc72"),0.0)
	for i in range(3):
		draw_line(Vector2(18+i*17,45),Vector2(32+i*17,17),[Color("72bac1"),Color("e08b98"),Color("eebd5a")][i],7,true)
	draw_set_transform(Vector2.ZERO)

func _draw_castle_landmark(at: Vector2, garden: bool=false) -> void:
	if garden:
		draw_set_transform(at)
		_draw_oval(Vector2.ZERO,Vector2(95,36),Color("bed29d"))
		for i in range(4):
			var x:float=-65+i*43
			draw_line(Vector2(x,14),Vector2(x+sin(_clock+i)*3,-19),INK,2,true)
			_draw_star(Vector2(x+sin(_clock+i)*3,-23),12,Color("efb2bf"),i*.3)
		draw_set_transform(Vector2.ZERO)
		return
	draw_style_box(_box(Color("deb674"),2,3),Rect2(at+Vector2(-78,-39),Vector2(156,80)))
	for x in [-78.0,0.0,78.0]:
		_draw_tower(at+Vector2(x,-9))
		var tip:=at+Vector2(x,-78)
		draw_line(tip,tip+Vector2(0,16),INK,2,true)
		var flag:=PackedVector2Array([tip,tip+Vector2(22,5+sin(_clock*2+x)*3),tip+Vector2(0,12)])
		draw_colored_polygon(flag,Color("cc7390"))
	draw_style_box(_box(Color("745e51"),13,2),Rect2(at+Vector2(-14,12),Vector2(28,30)))
	for i in range(5): draw_line(at+Vector2(-65+i*29,-27),at+Vector2(-61+i*29,25),Color("c79860"),1,true)

func _draw_paper_kite(at: Vector2) -> void:
	at+=Vector2(sin(_clock*.7)*7,cos(_clock*.9)*5)
	draw_line(at+Vector2(0,28),at+Vector2(23,69),Color("809eac"),2,true)
	var p:=PackedVector2Array([at+Vector2(0,-56),at+Vector2(44,-10),at+Vector2(0,30),at+Vector2(-44,-10)])
	draw_colored_polygon(p,Color("e9b0b2"));p.append(p[0]);draw_polyline(p,INK,2,true)
	draw_colored_polygon(PackedVector2Array([at+Vector2(0,-56),at+Vector2(44,-10),at+Vector2(0,30)]),Color("f0d497"))
	draw_line(at+Vector2(0,-56),at+Vector2(0,30),INK,1,true)
	draw_line(at+Vector2(-44,-10),at+Vector2(44,-10),INK,1,true)
	for i in range(3):
		var b:=at+Vector2(10+i*6,42+i*10)
		draw_line(b+Vector2(-7,-4),b+Vector2(7,4),Color("7eafc5"),4,true)
