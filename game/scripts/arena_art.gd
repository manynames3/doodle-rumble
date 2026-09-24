extends Node2D
## Illustrated environments; only this presentation layer scrolls. Collision is fixed.
const ArenaLayout = preload("res://scripts/arena_layout.gd")
const HandFont = preload("res://assets/fonts/Kalam-Bold.ttf")
const Ambience = preload("res://scripts/arena_ambience.gd")
var ambience = Ambience.new()
const INK = Color("171424")

var arena_kind = "desktop"
var focus_x = 640.0
var reduced_motion = false
var training = false
var boss_large = false
var interactions
var elapsed = 0.0
var textures: Dictionary = {}
const FLOOR_FRACTION = {"desktop":0.734,"quarry":0.757,"glitch":0.739,"canopy":0.645,"arcade":0.638,"network":0.658}
const ACCENTS = {"desktop":Color("ffb45f"),"quarry":Color("ffd36d"),"glitch":Color("d98cff"),"canopy":Color("f3d597"),"arcade":Color("ff9dcf"),"network":Color("6cedf2")}

func _ready() -> void:
	for id in ["desktop","quarry","glitch","canopy","arcade","network"]:
		textures[id] = load("res://assets/arenas/"+id+"_v2.png")

func _process(delta: float) -> void:
	if not reduced_motion: elapsed += delta
	queue_redraw()

func _draw() -> void:
	if textures.is_empty(): return
	var texture: Texture2D = textures.get(arena_kind,textures.desktop)
	var size = texture.get_size()
	var floor_y = size.y * float(FLOOR_FRACTION.get(arena_kind,0.84))
	var parallax = clampf((focus_x-640)*0.012,-4,4) if not reduced_motion else 0.0
	var accent: Color = ACCENTS.get(arena_kind,ACCENTS.desktop)
	var floor_rect: Rect2 = ArenaLayout.FLOOR
	# Align the illustration's floor edge with the authoritative y=600 surface.
	draw_texture_rect_region(texture,Rect2(-12-parallax,0,1304,floor_rect.position.y),Rect2(0,0,size.x,floor_y))
	draw_texture_rect_region(texture,Rect2(0,floor_rect.position.y,1280,floor_rect.size.y),Rect2(0,floor_y,size.x,size.y-floor_y))

	ambience.paint(self,arena_kind,elapsed if not reduced_motion else 0.0)
	# The painting stays unobscured; small atmosphere marks tie the line art into it.
	for i in range(16):
		var drift = 0.0 if reduced_motion else elapsed * (1.5 + i % 3)
		var p = Vector2(fposmod(i*211.0+drift,1240.0)+20.0,210.0+fposmod(i*83.0-drift,330.0))
		draw_circle(p,0.7+(i%3)*0.35,Color(accent,0.07+(i%4)*0.025))

	if boss_large:
		_draw_boss_platforms()
		return
	match arena_kind:
		"canopy","arcade","network":
			_draw_story_platforms()
			_draw_story_route_cues()
		"quarry": _draw_quarry_platforms()
		"glitch": _draw_glitch_platforms()
		_: _draw_desktop_platforms()

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result = points.duplicate()
	if not result.is_empty(): result.append(result[0])
	return result

func _outlined(points: PackedVector2Array, fill: Color, edge: Color, width: float = 3.2) -> void:
	draw_colored_polygon(points,fill)
	draw_polyline(_closed(points),Color(INK,0.44),width+3.6,true)
	draw_polyline(_closed(points),edge,width,true)

func _rough_line(a: Vector2, b: Vector2, color: Color, width: float, seed: float, steps: int = 9) -> void:
	var points = PackedVector2Array()
	var direction = b-a
	var normal = Vector2(-direction.y,direction.x).normalized()
	for i in range(steps+1):
		var t = float(i)/steps
		var wobble = 0.0 if i in [0,steps] else sin(seed+i*2.17)*0.9 + sin(seed*0.7+i*4.9)*0.35
		points.append(a+direction*t+normal*wobble)
	draw_polyline(points,color,width,true)

func _surface(rect: Rect2, color: Color, accent: Color, depth: float, seed: float) -> PackedVector2Array:
	# The top edge is exact: it is the visible version of the shared collision surface.
	var points = PackedVector2Array([
		Vector2(rect.position.x-3,rect.position.y),
		Vector2(rect.end.x+3,rect.position.y),
		Vector2(rect.end.x+1,rect.position.y+depth-2),
		Vector2(rect.end.x-7,rect.position.y+depth+2),
		Vector2(rect.position.x+6,rect.position.y+depth),
		Vector2(rect.position.x-2,rect.position.y+depth-3),
	])
	_outlined(points,color,INK,3.0)
	draw_line(Vector2(rect.position.x,rect.position.y),Vector2(rect.end.x,rect.position.y),Color(INK,0.95),4.2,true)
	_rough_line(Vector2(rect.position.x+2,rect.position.y+1.5),Vector2(rect.end.x-2,rect.position.y+1.5),accent,1.8,seed)
	# Irregular dry-brush tooth gives every suspended platform a material
	# thickness while its authoritative walkable top remains a straight line.
	for i in range(7):
		var x = rect.position.x+13.0+i*(rect.size.x-26.0)/6.0
		var y = rect.position.y+8.0+(i%3)*4.0
		var length = 5.0+(i%4)*2.2
		_rough_line(Vector2(x,y),Vector2(x+length,y+1.4),Color(accent,0.27+(i%2)*0.12),1.0,seed+i*3.1,3)
	return points

func _draw_desktop_platforms() -> void:
	_draw_desktop_pad()
	var ruler: Rect2 = ArenaLayout.PLATFORMS[0]
	var book: Rect2 = ArenaLayout.PLATFORMS[1]
	var drawer: Rect2 = ArenaLayout.PLATFORMS[2]

	# A nicked wooden ruler, with hand-cut marks rather than a sterile UI bar.
	_surface(ruler,Color("d79a57"),Color("ffe0a3"),31,1.0)
	for i in range(1,22):
		var x = ruler.position.x+i*10.0
		var tick = 11.0 if i%5 == 0 else 7.0 if i%2 == 0 else 4.0
		_rough_line(Vector2(x,ruler.position.y+5),Vector2(x,ruler.position.y+5+tick),Color("5d3b35"),1.2,float(i),3)
	for hole_x in [ruler.position.x+18,ruler.end.x-17]:
		draw_circle(Vector2(hole_x,ruler.position.y+20),3.6,Color("775347"))
		draw_arc(Vector2(hole_x,ruler.position.y+20),4.2,0,TAU,12,INK,1.4,true)

	# A thick sketchbook with loose page edges and a taped paper label.
	_surface(book,Color("655881"),Color("e9c6ff"),48,2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(505,447),Vector2(773,447),Vector2(770,474),Vector2(509,478)]),Color("eee5d6"))
	_rough_line(Vector2(508,450),Vector2(771,449),Color("83758f"),1.2,6.0,13)
	_rough_line(Vector2(510,459),Vector2(768,458),Color("b1a4b7"),1.0,7.0,13)
	_rough_line(Vector2(511,469),Vector2(766,467),Color("94879e"),1.0,8.0,13)
	draw_colored_polygon(PackedVector2Array([Vector2(607,447),Vector2(679,447),Vector2(675,466),Vector2(604,467)]),Color("efbb74"))
	draw_polyline(PackedVector2Array([Vector2(607,447),Vector2(679,447),Vector2(675,466),Vector2(604,467)]),Color("7b5370"),1.5,true)

	# A pulled-out art drawer becomes the high ledge; its side depth sells the height.
	_surface(drawer,Color("725b65"),Color("ffc47e"),55,3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(907,379),Vector2(1113,378),Vector2(1107,415),Vector2(911,417)]),Color("aa7768"))
	draw_polyline(_closed(PackedVector2Array([Vector2(907,379),Vector2(1113,378),Vector2(1107,415),Vector2(911,417)])),INK,2.2,true)
	draw_arc(Vector2(1010,397),22,0.15,PI-0.15,18,Color("e5b084"),3.0,true)
	_rough_line(Vector2(929,425),Vector2(1095,423),Color("493840"),2.0,9.0,8)
	# A crooked sheet peeks from the drawer without changing the walkable edge.
	draw_colored_polygon(PackedVector2Array([Vector2(936,375),Vector2(1047,374),Vector2(1035,394),Vector2(948,391)]),Color("ece4cf"))
	_rough_line(Vector2(959,382),Vector2(1027,381),Color("8b7890"),1.1,12.0,6)

func _stone_block(rect: Rect2, depth: float, seed: float) -> void:
	_surface(rect,Color("7c6a79"),Color("ffd071"),depth,seed)
	var middle_y = rect.position.y+depth*0.52
	_rough_line(Vector2(rect.position.x+5,middle_y),Vector2(rect.end.x-6,middle_y+2),Color("332c3d"),1.5,seed+4.0,8)
	for i in range(4):
		var x = rect.position.x+26+i*(rect.size.x-48)/3.0
		var y = rect.position.y+8+(i%2)*7
		var crack = PackedVector2Array([Vector2(x,y),Vector2(x-5,y+7),Vector2(x+2,y+13),Vector2(x-3,y+20)])
		draw_polyline(crack,Color("342d3b"),1.6,true)
	for i in range(6):
		var gx = rect.position.x+12+i*(rect.size.x-24)/5.0
		_rough_line(Vector2(gx,rect.position.y-1),Vector2(gx+sin(seed+i)*4,rect.position.y-7-(i%3)*2),Color("bd9f4c"),1.6,seed+i,3)

func _draw_quarry_platforms() -> void:
	var platforms = ArenaLayout.get_platforms("quarry")
	for i in range(platforms.size()):
		var rect: Rect2 = platforms[i]
		if i == ArenaLayout.QUARRY_BRIDGE_INDEX:
			if interactions and interactions.bridge_gone > 0.0:
				_draw_broken_bridge(rect)
				continue
			_stone_block(rect,31,19.0)
			for joint in range(1,5):
				var x = rect.position.x+joint*rect.size.x/5.0
				_rough_line(Vector2(x,rect.position.y+2),Vector2(x+4,rect.position.y+28),Color("342d3b"),2.4,float(joint+50),4)
			if interactions and interactions.bridge_load > 0.08:
				var pressure = clampf(interactions.bridge_load/0.52,0.0,1.0)
				draw_line(Vector2(rect.position.x+8,rect.position.y-6),Vector2(rect.position.x+8+rect.size.x*pressure,rect.position.y-6),Color("ffe3a2",0.85),3.0,true)
		else:
			_stone_block(rect,43 if i == 3 else 38,11.0+float(i)*8.0)
	_draw_quarry_bridge_note(platforms[ArenaLayout.QUARRY_BRIDGE_INDEX])

func _glitch_panel(rect: Rect2, depth: float, seed: float) -> void:
	var neon = Color("e066ff")
	draw_line(Vector2(rect.position.x-4,rect.position.y),Vector2(rect.end.x+4,rect.position.y),Color(neon,0.10),15.0,true)
	draw_line(Vector2(rect.position.x-3,rect.position.y),Vector2(rect.end.x+3,rect.position.y),Color(neon,0.25),8.0,true)
	_surface(rect,Color("20213e"),neon,depth,seed)
	for i in range(7):
		var x = rect.position.x+11+i*(rect.size.x-22)/6.0
		var y = rect.position.y+12+(i%3)*7
		var run = minf(21.0,rect.end.x-x-4)
		draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+run*0.5,y),Vector2(x+run*0.5,y+5),Vector2(x+run,y+5)]),Color("65d8ff",0.75),1.4,false)
	for i in range(5):
		var px = rect.position.x+24+i*(rect.size.x-48)/4.0
		draw_rect(Rect2(px,rect.position.y+depth-12,5,5),Color("f0a0ff",0.8))

func _draw_glitch_platforms() -> void:
	var platforms = ArenaLayout.get_platforms("glitch")
	for i in range(platforms.size()):
		_glitch_panel(platforms[i],35 if i%2 == 0 else 47,31.0+float(i)*6.0)
	_draw_glitch_pads()

func _draw_boss_platforms() -> void:
	# Ink-dark retreat ledges leave the Dark lord's ground lane open.
	var platforms = ArenaLayout.get_platforms(arena_kind,true)
	for i in range(platforms.size()):
		var rect: Rect2 = platforms[i]
		_glitch_panel(rect,32 if i != 1 else 40,71.0+float(i)*9.0)
		_rough_line(Vector2(rect.position.x+9,rect.position.y+8),Vector2(rect.end.x-10,rect.position.y+8),Color("f2be82",0.58),1.2,float(i+83),11)
		for scratch in range(3):
			var x = rect.position.x+28+scratch*(rect.size.x-56)/2.0
			_rough_line(Vector2(x,rect.position.y+17),Vector2(x+12,rect.position.y+27),Color("a973b8",0.64),1.4,float(scratch+90),3)

func _draw_desktop_pad() -> void:
	var p: Rect2 = ArenaLayout.DESKTOP_PAD
	# A flat eraser and open-book leaves sit on the desk exactly where the boost triggers.
	var pages = PackedVector2Array([Vector2(p.position.x-22,599),Vector2(p.position.x+4,580),Vector2(p.end.x-4,580),Vector2(p.end.x+22,599)])
	_outlined(pages,Color("e6d8b5"),INK,2.3)
	_outlined(PackedVector2Array([Vector2(p.position.x+5,584),Vector2(p.end.x-5,584),Vector2(p.end.x-11,597),Vector2(p.position.x+11,597)]),Color("ec9a9d"),INK,2.7)
	_rough_line(Vector2(p.position.x+18,590),Vector2(p.end.x-18,590),Color("fff0ca"),1.5,41.0,8)
	draw_string(HandFont,Vector2(p.position.x+21,569),"JUMP ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("ffe3a2"))

func _draw_quarry_bridge_note(bridge: Rect2) -> void:
	var x = bridge.get_center().x
	draw_string(HandFont,Vector2(x-57,bridge.position.y-17),"LOOSE STONE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe2a1"))
	for sign in [-1,1]:
		_rough_line(Vector2(x+sign*91,bridge.position.y-15),Vector2(x+sign*91,bridge.position.y-5),Color("ffe2a1",0.8),1.4,float(sign+60),3)

func _draw_broken_bridge(bridge: Rect2) -> void:
	# The walkway visibly disappears while its collision is disabled; the floor remains safe.
	for i in range(5):
		var x = bridge.position.x+25+i*61
		var drop = 21.0+(i%3)*13.0
		var piece = PackedVector2Array([Vector2(x,bridge.position.y+drop),Vector2(x+35,bridge.position.y+drop+3),Vector2(x+27,bridge.position.y+drop+18),Vector2(x+5,bridge.position.y+drop+15)])
		_outlined(piece,Color("746474",0.65),Color("342d3b",0.8),2.0)
	draw_string(HandFont,Vector2(bridge.get_center().x-47,bridge.position.y-18),"REFORMING",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffdf9b"))

func _draw_glitch_pads() -> void:
	for i in range(ArenaLayout.GLITCH_PADS.size()):
		var pad: Rect2 = ArenaLayout.GLITCH_PADS[i]
		var cooling = interactions and interactions.teleport_cooldown[i] > 0.0
		var neon = Color("9c82ac") if cooling else Color("e389fa")
		var slab = PackedVector2Array([Vector2(pad.position.x-5,600),Vector2(pad.position.x+8,583),Vector2(pad.end.x-8,583),Vector2(pad.end.x+5,600)])
		_outlined(slab,Color("292943"),INK,2.6)
		draw_line(Vector2(pad.position.x+11,588),Vector2(pad.end.x-11,588),Color(neon,0.65),4.0,true)
		for j in range(3):
			var px = pad.position.x+23+j*25
			draw_rect(Rect2(px,592,8,4),Color("6fe3f1",0.5 if cooling else 0.9))
		draw_string(HandFont,Vector2(pad.position.x+10,572),"JUMP ↗" if i == 0 else "↖ JUMP",HORIZONTAL_ALIGNMENT_LEFT,-1,14,neon)

func _draw_story_platforms() -> void:
	var platforms := ArenaLayout.get_platforms(arena_kind)
	var accent:Color = ACCENTS[arena_kind]
	for i in range(platforms.size()):
		var rect:Rect2=platforms[i]
		var fill:Color={"canopy":Color("607a65"),"arcade":Color("59365f"),"network":Color("253a4d")}[arena_kind]
		_surface(rect,fill,accent,32 if arena_kind=="canopy" else 25,float(i+50))
		match arena_kind:
			"canopy":
				for j in range(6):
					var x:=rect.position.x+17+j*(rect.size.x-34)/5
					var p:=Vector2(x,rect.position.y+17)
					_outlined(PackedVector2Array([p,p+Vector2(18,16),p+Vector2(3,31),p+Vector2(-14,10)]),Color("8d9e68"),INK,1.5)
					draw_line(p,p+Vector2(3,25),Color("d4c992"),1.2,true)
				for j in range(4):
					var bx = rect.position.x+25+j*(rect.size.x-50)/3.0
					_rough_line(Vector2(bx,rect.position.y+12),Vector2(bx+7,rect.position.y+26),Color("c1ad77",0.62),1.3,float(i*11+j),4)
			"arcade":
				for j in range(9):
					var x:=rect.position.x+13+j*(rect.size.x-26)/8
					draw_circle(Vector2(x,rect.position.y+13),3.5,Color("ffd78d") if j%2==0 else Color("f28bc9"))
				_rough_line(rect.position+Vector2(5,22),rect.end+Vector2(-5,-2),Color("ec7eca"),2,float(i+80))
				for j in range(4):
					var px = rect.position.x+28+j*(rect.size.x-56)/3.0
					draw_line(Vector2(px,rect.position.y+8),Vector2(px+9,rect.position.y+20),Color("ffe4b4",0.52),1.5,true)
					draw_circle(Vector2(px+15,rect.position.y+17),1.6,Color("f492ce",0.8))
			"network":
				for j in range(7):
					var x:=rect.position.x+14+j*(rect.size.x-28)/6
					draw_line(Vector2(x,rect.position.y+8),Vector2(x,rect.position.y+23),Color("d4b17b"),3,true)
				draw_circle(Vector2(rect.position.x+8,rect.position.y+13),2,accent)
				for j in range(4):
					var nx = rect.position.x+24+j*(rect.size.x-48)/3.0
					draw_polyline(PackedVector2Array([Vector2(nx,rect.position.y+23),Vector2(nx+6,rect.position.y+16),Vector2(nx+16,rect.position.y+16)]),Color("80dce2",0.65),1.2,false)
					draw_circle(Vector2(nx+17,rect.position.y+16),1.7,Color("f2bd90",0.8))

func _draw_story_route_cues() -> void:
	match arena_kind:
		"canopy":
			for index in range(ArenaLayout.CANOPY_GUST_PADS.size()):
				var pad: Rect2 = ArenaLayout.CANOPY_GUST_PADS[index]
				var center := Vector2(pad.get_center().x,pad.position.y-8.0)
				var direction := -1.0 if index == 0 else 1.0
				for line in range(3):
					var from := center+Vector2(-16.0,5.0+line*4.0)
					var to := from+Vector2(direction*(19.0+line*4.0),-5.0)
					_rough_line(from,to,Color("c8f29b",0.78-float(line)*0.14),1.7,float(index*7+line),5)
				draw_string(HandFont,center+Vector2(-49,-13),"JUMP: CATCH WIND",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e1f2b5"))
		"arcade":
			for index in range(ArenaLayout.ARCADE_BUMPER_PADS.size()):
				var pad: Rect2 = ArenaLayout.ARCADE_BUMPER_PADS[index]
				var center := Vector2(pad.get_center().x,594.0)
				draw_arc(center,16.0,PI,TAU,18,Color("ff9cce",0.8),3.0,true)
				draw_arc(center,10.0,PI,TAU,16,Color("ffe37d",0.9),2.0,true)
				var direction: float = 1.0 if index == 0 else -1.0
				var arrow := PackedVector2Array([center+Vector2(-5,9),center+Vector2(direction,-9),center+Vector2(direction*8,-1)])
				_rough_line(arrow[0],arrow[1],Color("ffe37d"),2.0,float(index+31),4)
				_rough_line(arrow[1],arrow[2],Color("ffe37d"),2.0,float(index+37),3)
				draw_string(HandFont,center+Vector2(-48,-22),"JUMP: BUMPER",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ffe7a0"))
		"network":
			for index in range(ArenaLayout.NETWORK_LIFT_PADS.size()):
				var pad: Rect2 = ArenaLayout.NETWORK_LIFT_PADS[index]
				var center := Vector2(pad.get_center().x,pad.position.y-7.0)
				for stripe in range(4):
					var x := pad.position.x+11.0+stripe*20.0
					draw_rect(Rect2(x,pad.position.y+7.0,11,3),Color("70eff3",0.42+float((stripe+index)%2)*0.22))
				var arrow := PackedVector2Array([center+Vector2(-5,7),center+Vector2(0,-8),center+Vector2(5,7)])
				_rough_line(arrow[0],arrow[1],Color("9affff",0.88),2.0,float(index+51),4)
				_rough_line(arrow[1],arrow[2],Color("9affff",0.88),2.0,float(index+57),4)
				draw_string(HandFont,center+Vector2(-42,-16),"JUMP: DATA LIFT",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("a5f9f5"))
