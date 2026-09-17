extends Node2D
## Live hand-painted HUD marks. Labels remain Controls in main.gd for accessibility/tests.

const HandFont = preload("res://assets/fonts/Kalam-Bold.ttf")
const BLACK = Color("08090fe9")
const EDGE = Color("020309e8")
const CHALK = Color("f1eee3d9")
var host: Node

func bind(match_host: Node) -> void:
	host = match_host
	process_mode = Node.PROCESS_MODE_ALWAYS
	queue_redraw()

func _process(_delta: float) -> void:
	if not is_instance_valid(host):
		return
	var age := float(Time.get_ticks_msec() - host.hud_note_started_at)
	var note_alpha := 1.0 if host.state == "paused" else clampf(1.0 - (age - 4200.0) / 2200.0, 0.34, 1.0)
	if is_instance_valid(host.hint_label):
		host.hint_label.modulate.a = note_alpha
	for prompt in host.prompts:
		if is_instance_valid(prompt): prompt.modulate.a = note_alpha
	queue_redraw()

func _rough_box(rect: Rect2, seed_value: int, color: Color = BLACK) -> void:
	var points = PackedVector2Array()
	for i in range(13):
		var x := rect.position.x + rect.size.x * i / 12.0
		points.append(Vector2(x + (6 if i == 0 else -5 if i == 12 else 0), rect.position.y + sin(float(i * 17 + seed_value)) * 3.4))
	for i in range(12, -1, -1):
		var x := rect.position.x + rect.size.x * i / 12.0
		points.append(Vector2(x - (3 if i == 12 else 0), rect.end.y + sin(float(i * 11 + seed_value)) * 2.7))
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, EDGE, 2.0, true)
	# Dry marker ends and drifting bristles replace a tidy rectangular frame.
	for i in range(5):
		var y: float = rect.position.y+5+i*(rect.size.y-10)/4.0
		var bristle: float = 3+absf(sin(float(i*13+seed_value)))*7
		draw_line(Vector2(rect.position.x+10,y-2),Vector2(rect.position.x-bristle*0.5,y+2),color,1.3+float(i%2),true)
		draw_line(Vector2(rect.end.x-12,y-1),Vector2(rect.end.x+bristle*0.5,y-3),color,1.3+float(i%2),true)
	for i in range(3):
		var y := rect.position.y + 9.0 + i * (rect.size.y - 15.0) / 3.0
		draw_line(Vector2(rect.position.x + 12.0 + sin(float(seed_value + i)) * 7.0, y), Vector2(rect.end.x - 15.0, y + sin(float(i + seed_value)) * 1.5), Color("25263148"), 1.3, true)

func _jagged_bar(rect: Rect2, amount: float, color: Color, right_to_left: bool, seed_value: int) -> void:
	var track := PackedVector2Array([
		Vector2(rect.position.x - 3, rect.position.y + 2), Vector2(rect.end.x + 2, rect.position.y - 1),
		Vector2(rect.end.x - 2, rect.end.y + 2), Vector2(rect.position.x + 2, rect.end.y)
	])
	draw_colored_polygon(track, Color("20212bbc"))
	draw_polyline(PackedVector2Array([track[0],track[1],track[2],track[3],track[0]]), Color("020309e8"), 2.2, true)
	var width := rect.size.x * clampf(amount, 0.0, 1.0)
	if width < 1.0:
		return
	var left := rect.end.x - width if right_to_left else rect.position.x
	var right := rect.end.x if right_to_left else rect.position.x + width
	var teeth := minf(width * 0.35,3.0 + absf(sin(float(seed_value) + amount * 9.0)) * 3.0)
	var fill := PackedVector2Array([
		Vector2(left + (teeth if right_to_left else 0.0),rect.position.y),
		Vector2(right - (teeth if not right_to_left else 0.0),rect.position.y + 1),
		Vector2(right if not right_to_left else right,rect.end.y - 1),
		Vector2(left + (teeth if right_to_left else 0.0),rect.end.y),
		Vector2(left if right_to_left else left,rect.position.y + rect.size.y * 0.5)
	])
	draw_colored_polygon(fill, color)
	draw_polyline(PackedVector2Array([fill[0],fill[1],fill[2],fill[3],fill[4],fill[0]]), color.darkened(0.48), 2.0, true)
	var highlight_y := rect.position.y + 4.0
	draw_line(Vector2(left + 6, highlight_y), Vector2(maxf(left + 6, right - 8), highlight_y - 1), color.lightened(0.30), 1.4, true)

func _head_icon(center: Vector2, color: Color, style: String, flip: float) -> void:
	var head := PackedVector2Array()
	for i in range(15):
		var angle := TAU * i / 14.0
		var wobble := 1.0 + sin(float(i * 5 + style.length())) * 0.07
		head.append(center + Vector2(cos(angle) * 11.0, sin(angle) * 10.0) * wobble)
	draw_polyline(head, CHALK, 2.0, true)
	if style == "double_ring":
		draw_arc(center + Vector2(1,0), 7.0, 0, TAU, 13, color, 1.5, true)
	elif style == "chomp":
		draw_colored_polygon(PackedVector2Array([center,center+Vector2(12*flip,-6),center+Vector2(12*flip,6)]),BLACK)
	elif style == "monitor":
		draw_colored_polygon(PackedVector2Array([center+Vector2(-13,-12),center+Vector2(13,-11),center+Vector2(12,7),center+Vector2(-12,8)]),BLACK)
		draw_polyline(PackedVector2Array([center+Vector2(-13,-12),center+Vector2(13,-11),center+Vector2(12,7),center+Vector2(-12,8),center+Vector2(-13,-12)]),color,2,true)
	elif style == "crown":
		draw_polyline(PackedVector2Array([center+Vector2(-9,-9),center+Vector2(-6,-17),center+Vector2(0,-11),center+Vector2(6,-18),center+Vector2(9,-9)]),color,1.8,true)
	else:
		draw_line(center + Vector2(-7,-7),center + Vector2(7,-9),color,1.5,true)
	draw_circle(center + Vector2(-3 * flip,-1),1.3,CHALK)
	draw_circle(center + Vector2(4 * flip,-1),1.3,CHALK)
	draw_line(center + Vector2(-8,10),center + Vector2(-12,15),CHALK,1.8,true)
	draw_line(center + Vector2(8,10),center + Vector2(12,15),CHALK,1.8,true)

func _special_icon(at: Vector2, color: Color, ready: bool, flip: float) -> void:
	var ink := color if ready else Color("777987")
	var points := PackedVector2Array([
		at+Vector2(-7*flip,2),at+Vector2(-2*flip,-7),at+Vector2(1*flip,-2),
		at+Vector2(7*flip,-5),at+Vector2(4*flip,2),at+Vector2(8*flip,6),
		at+Vector2(0,5),at+Vector2(-5*flip,8),at+Vector2(-7*flip,2)
	])
	draw_polyline(points,ink,1.8,true)

func _round_pips(slot: int, color: Color, score: int) -> void:
	var centers := [Vector2(505,39),Vector2(529,39)] if slot == 0 else [Vector2(751,39),Vector2(775,39)]
	for i in range(2):
		var center: Vector2 = centers[i]
		if score > i: draw_circle(center,6.0,color)
		draw_arc(center,7.0,0,TAU,13,color if score > i else CHALK,1.8,true)
		draw_line(center+Vector2(-5,5),center+Vector2(4,7),Color("020309b0"),1.0,true)

func _draw() -> void:
	_rough_box(Rect2(20,10,458,68),7)
	_rough_box(Rect2(802,10,458,68),11)
	_rough_box(Rect2(590,7,100,72),19,Color("08090ff2"))
	if not is_instance_valid(host) or not is_instance_valid(host.first) or not is_instance_valid(host.second):
		return
	var fighters := [host.first,host.second]
	for i in range(2):
		var fighter = fighters[i]
		var tint := Color(fighter.definition.color)
		var health_rect := Rect2(66 if i == 0 else 824,39,390,18)
		_jagged_bar(health_rect,float(fighter.health)/float(fighter.max_health),tint,i == 1,17+i*8)
		var cooldown_ready: float = clampf((6.0-float(fighter.cooldown))/6.0,0.0,1.0)
		var cooldown_rect := Rect2(67 if i == 0 else 1137,68,76,5)
		_jagged_bar(cooldown_rect,cooldown_ready,tint,i == 1,41+i*6)
		_head_icon(Vector2(42 if i == 0 else 1238,33),tint,str(fighter.definition.head),1.0 if i == 0 else -1.0)
		_special_icon(Vector2(45 if i == 0 else 1235,67),tint,fighter.cooldown <= 0,1.0 if i == 0 else -1.0)
		_round_pips(i,tint,int(host.rules.scores[i]))
		if fighter.definition.id in ["orange","red","green","blue","purple","yellow"]:
			var point := Vector2(445 if i == 0 else 820,68)
			var ready: float = clampf(1.0-float(fighter.dodge_cooldown)/float(fighter.DODGE_COOLDOWN),0,1)
			draw_arc(point,7.0,0.3,0.3+TAU*ready,16,tint if ready>=0.99 else CHALK,1.4,true)
			draw_polyline(PackedVector2Array([point+Vector2(-7,-5),point+Vector2(-8,0),point+Vector2(-3,-1)]),tint,1.7,true)
			if fighter.counter_time>0:
				draw_string(HandFont,Vector2(364 if i==0 else 834,29),"COUNTER!",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("fff0ab"))
	var age := float(Time.get_ticks_msec() - host.hud_note_started_at)
	var note_alpha := 1.0 if host.state == "paused" else clampf(1.0 - (age - 4200.0) / 2200.0,0.34,1.0)
	_rough_box(Rect2(18,683,594,27),31,Color(0.03,0.035,0.06,0.66*note_alpha))
	_rough_box(Rect2(648,683,605,27),37,Color(0.03,0.035,0.06,0.66*note_alpha))
