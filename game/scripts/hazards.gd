extends Node2D
## Drawn objects are decorative; only fixed-step, warned rectangles deal damage.
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const WarningOverlay = preload("res://scripts/hazard_warning_overlay.gd")
const BossStrength = preload("res://scripts/boss_strength.gd")
const INK = Color("080d1d")
const TYPES = {
	"dark_rift":{"color":"d783ff","width":186.0,"top":472.0,"tell":1.15,"active":0.38,"damage":20,"label":"RIFT! MOVE!"},
	"eclipse_wave":{"color":"d05bff","width":348.0,"top":503.0,"tell":1.22,"active":0.32,"damage":22,"label":"ECLIPSE WAVE! JUMP!"},
	"void_pillar":{"color":"b852ff","width":108.0,"top":188.0,"tell":1.28,"active":0.25,"damage":20,"label":"VOID PILLAR! MOVE!"},
	"camera":{"color":"dcb1ff","width":76.0,"top":185.0,"tell":1.35,"active":0.27,"label":"MOVE!"},
	"cursor_stamp":{"color":"58f5e4","width":128.0,"top":410.0,"tell":1.5,"active":0.24,"label":"CLICK! SIDESTEP!"},
	"eraser_drop":{"color":"ff9cba","width":170.0,"top":505.0,"tell":1.6,"active":0.28,"label":"ERASER!"},
	"ink_geyser":{"color":"a4f475","width":220.0,"top":545.0,"tell":1.4,"active":0.32,"label":"JUMP THE INK!"},
	"firewall_scan":{"color":"ffbd56","width":174.0,"top":290.0,"tell":1.25,"active":0.38,"damage":18,"label":"FIREWALL! MOVE!"},
	"paper_swarm":{"color":"ffe4a2","width":230.0,"top":520.0,"tell":1.5,"active":0.4,"damage":8,"label":"PAPER PLANES! JUMP!"},
	"pixel_pinball":{"color":"ff9de4","width":180.0,"top":460.0,"tell":1.7,"active":0.32,"damage":12,"label":"PINBALL! SIDESTEP!"},
	"circuit_zip":{"color":"6cf3ed","width":150.0,"top":225.0,"tell":1.45,"active":0.25,"damage":12,"label":"DATA DROP! MOVE!"}
}
## Boss-only payload tuning. Ordinary stage hazards keep their original damage.
const HACKER_SIGNATURE_DAMAGE := {"cursor_stamp":14,"ink_geyser":13,"eraser_drop":15}
var camera_bugs = false
var reduced_motion = false
var marks: Array = []
var pending: Array = []
var time = 0.0
var warning_overlay: Node2D

func _ready() -> void:
	warning_overlay = WarningOverlay.new()
	add_child(warning_overlay)

func warning_spec(kind: String) -> Dictionary:
	return TYPES[kind]

func clear() -> void:
	marks.clear()
	pending.clear()
	time = 0
	queue_redraw()
	if is_instance_valid(warning_overlay): warning_overlay.queue_redraw()

func mark_target(x: float, source: int = 0, kind: String = "camera", immune_id: String = "") -> void:
	# One active event leaves a generous safe part of every arena, even at the edges.
	if not TYPES.has(kind): kind = "camera"
	var mark = {"x":clampf(x,135,1145),"age":0.0,"source":source,"hit":{},"kind":kind,"immune":immune_id}
	if not marks.is_empty():
		# A decorative stage event must not silently cancel a boss signature.
		# Queued signatures receive a fresh, full warning when the current zone clears.
		if immune_id != "" and pending.size() < 2: pending.append(mark)
		return
	marks.append(mark)
	queue_redraw()
	if is_instance_valid(warning_overlay): warning_overlay.queue_redraw()

func damage_rect(mark: Dictionary) -> Rect2:
	var spec = TYPES[mark.kind]
	return Rect2(mark.x-spec.width/2,spec.top,spec.width,600-spec.top)

func tick(delta: float, fighters: Array) -> void:
	time += delta
	for mark in marks:
		var old_age: float = mark.age
		mark.age += delta
		var spec = TYPES[mark.kind]
		# The swept clock also works when a fixed step crosses the active boundary.
		if mark.age >= spec.tell and old_age < spec.tell+spec.active:
			for fighter in fighters:
				if fighter.definition.id == mark.immune or (mark.immune == "" and camera_bugs and fighter.definition.id == "dark_lord"): continue
				if not mark.hit.has(fighter.slot) and damage_rect(mark).intersects(fighter.hurtbox()):
					mark.hit[fighter.slot] = true
					var damage: int = int(HACKER_SIGNATURE_DAMAGE.get(mark.kind, spec.get("damage", 9))) if mark.immune == "h4ck3r" else int(spec.get("damage", 9))
					damage = BossStrength.damage(str(mark.immune), damage)
					fighter.take_hit(damage,1 if fighter.position.x > mark.x else -1,210)
	marks = marks.filter(func(mark): return mark.age < TYPES[mark.kind].tell+TYPES[mark.kind].active+0.28)
	if marks.is_empty() and not pending.is_empty(): marks.append(pending.pop_front())
	queue_redraw()
	if is_instance_valid(warning_overlay): warning_overlay.queue_redraw()

func _ink_shape(points: PackedVector2Array, fill: Color, edge: Color, width: float = 3.0) -> void:
	draw_colored_polygon(points,fill)
	var line = points.duplicate()
	line.append(line[0])
	draw_polyline(line,INK,width+3,true)
	draw_polyline(line,edge,width,true)

func _draw() -> void:
	if camera_bugs:
		for i in range(2):
			var p = Vector2(190+i*900,228+(0 if reduced_motion else sin(time*2+i)*6))
			for side in [-1,1]:
				for leg in range(3):
					draw_polyline(PackedVector2Array([p+Vector2(side*16,leg*5),p+Vector2(side*29,leg*9+2),p+Vector2(side*35,leg*10+13)]),Color("ccbbf4"),3,true)
			draw_circle(p,24,Color("293147"))
			draw_arc(p,24,0,TAU,24,Color("9b8aba"),3,true)
			draw_circle(p,13,Color("756594"))
			draw_circle(p,6,Color("f8c778"))
			draw_circle(p+Vector2(-4,-5),3,Color("fff9e9"))
	for mark in marks:
		var spec = TYPES[mark.kind]
		var warning: bool = mark.age < spec.tell
		var active: bool = mark.age >= spec.tell and mark.age < spec.tell+spec.active
		var c = Color(spec.color)
		var box = damage_rect(mark)
		var fade: float = 1.0 if warning or active else clampf((spec.tell+spec.active+0.28-mark.age)/0.28,0,1)
		var progress: float = clampf(mark.age/spec.tell,0,1)
		# Sparse fill keeps the fighters visible; the collision outline is
		# redrawn over each hazard prop after the kind-specific illustration.
		draw_rect(box,Color(c,(0.025 if warning else 0.12)*fade))
		if warning:
			# Three small top ticks connect the floor label to the full hit region.
			for tick in [-1,0,1]:
				var tx: float = box.get_center().x + tick * minf(28.0,box.size.x*0.28)
				draw_line(Vector2(tx,box.position.y-8),Vector2(tx,box.position.y+6),Color(INK,0.8*fade),5,true)
				draw_line(Vector2(tx,box.position.y-8),Vector2(tx,box.position.y+6),Color(c,fade),2.5,true)
		match mark.kind:
			"paper_swarm":
				for i in range(4):
					var x: float = mark.x - 95 + i * 52
					var p = Vector2(x, 548 + i % 2 * 26)
					if warning: p.x -= 18 * (1 - progress)
					_ink_shape(PackedVector2Array([p + Vector2(22,0),p + Vector2(-21,-13),p + Vector2(-11,1),p + Vector2(-17,11)]),Color(c,fade * (0.35 if warning else 1.0)),Color(c.lightened(0.6),fade),1.5)
					if active: draw_line(p + Vector2(-33,2),p + Vector2(-59,2),Color(c,fade * 0.7),2,true)
			"pixel_pinball":
				var p = Vector2(mark.x, 532 if not warning else 365 + progress * 38)
				var points = PackedVector2Array()
				for i in range(17): points.append(p + Vector2.from_angle(i * TAU / 16) * 64)
				_ink_shape(points,Color(c.darkened(0.65),fade),Color(c,fade),4)
				draw_arc(p,47,-2.7,-1.0,14,Color(c.lightened(0.85),fade),7,true)
				draw_arc(p,58,0,TAU,24,Color(c,fade * 0.4),2,true)
				if active: _splat(Vector2(mark.x,594),c,90,fade)
			"circuit_zip":
				for i in range(4):
					var p = Vector2(mark.x, (245 + i * 85) if not warning else 170 - i * 18)
					var size = 22.0 if not warning else 14.0
					_ink_shape(PackedVector2Array([p+Vector2(-size,-size),p+Vector2(size,-size+3),p+Vector2(size-2,size),p+Vector2(-size,size-2)]),Color(c.darkened(0.7),fade),Color(c,fade),2)
					if active: draw_line(p+Vector2(0,-size-7),p+Vector2(0,-size-35),Color(c,0.55*fade),3,true)
				if active: _splat(Vector2(mark.x,590),c,65,fade)
			"dark_rift":
				var p = Vector2(mark.x,599)
				for side in [-1,1]:
					draw_polyline(PackedVector2Array([p,p+Vector2(side*22,-9),p+Vector2(side*38,-3),p+Vector2(side*67,-13),p+Vector2(side*90,-6)]),Color(c,fade),3,true)
				if not warning:
					for i in range(5):
						var x = -72+i*36
						var height = 78.0+44*(1-absf(float(i)-2)/2)
						var shard = PackedVector2Array([p+Vector2(x-14,0),p+Vector2(x-9,-height*0.72),p+Vector2(x+3,-height),p+Vector2(x+15,-height*0.46),p+Vector2(x+11,0)])
						_ink_shape(shard,Color(c.darkened(0.85),fade),Color(c,fade),2)
						draw_line(p+Vector2(x,-5),p+Vector2(x+3,-height+13),Color(c.lightened(0.8),fade),1.5,true)
			"eclipse_wave":
				var p := Vector2(mark.x,594)
				if warning:
					draw_arc(p+Vector2(0,1),52+progress*122,PI*1.05,PI*1.95,36,Color(INK,0.9*fade),9.0,true)
					draw_arc(p+Vector2(0,-3),53+progress*122,PI*1.05,PI*1.95,36,Color(c,0.95*fade),3.0,true)
					for side in [-1.0,1.0]:
						var tip := p+Vector2(side*(60+progress*105),-25-progress*24)
						draw_line(p+Vector2(side*9,-3),tip,Color(INK,0.9*fade),6.0,true)
						draw_line(p+Vector2(side*11,-6),tip,Color(c,fade),2.2,true)
				else:
					var wave := PackedVector2Array([Vector2(box.position.x,600)])
					for i in range(25):
						var x: float = box.position.x+float(i)*box.size.x/24.0
						var y: float = 566.0-92.0*pow(absf(sin(float(i)*PI/12.0)),0.65)
						wave.append(Vector2(x,y))
					wave.append(Vector2(box.end.x,600))
					_ink_shape(wave,Color(c.darkened(0.72),0.92*fade),Color(c,fade),4.5)
					for i in range(4):
						var shard_x: float = box.position.x+35.0+float(i)*86.0
						var chip := PackedVector2Array([Vector2(shard_x-7,570),Vector2(shard_x-2,533-float(i%2)*10),Vector2(shard_x+6,550),Vector2(shard_x+8,574)])
						_ink_shape(chip,Color("171025",fade),Color(c.lightened(0.42),fade),1.6)
			"void_pillar":
				var top := Vector2(mark.x,196)
				var bottom := Vector2(mark.x,595)
				if warning:
					var ring: float = 20.0+progress*18.0
					draw_arc(top,ring,0,TAU,32,Color(INK,0.9*fade),6.0,true)
					draw_arc(top,ring,0,TAU,32,Color(c,fade),2.4,true)
					for side in [-1.0,1.0]:
						var a := top+Vector2(side*(8+progress*18),20)
						var b := bottom+Vector2(side*(10+progress*29),-30)
						draw_line(a,b,Color(INK,0.83*fade),7.0,true)
						draw_line(a,b,Color(c,0.78*fade),2.0,true)
				else:
					draw_rect(Rect2(Vector2(mark.x-29,box.position.y),Vector2(58,box.size.y)),Color(INK,0.78*fade))
					draw_rect(Rect2(Vector2(mark.x-21,box.position.y),Vector2(42,box.size.y)),Color(c,0.60*fade))
					for i in range(6):
						var y: float = 222.0+float(i)*61.0
						draw_line(Vector2(mark.x-17,y),Vector2(mark.x+17,y+22),Color("f9dcff",0.78*fade),2.0,true)
					draw_arc(top,26,0,TAU,32,Color("f7d7ff",fade),3.0,true)
			"camera":
				if active: draw_rect(box,Color(c,0.46))
				draw_arc(Vector2(mark.x,579),27,-PI,0,20,Color(c,fade),3,true)
				if warning:
					draw_line(Vector2(mark.x-22,567),Vector2(mark.x+22,591),Color(c,0.7),3,true)
					draw_line(Vector2(mark.x-22,591),Vector2(mark.x+22,567),Color(c,0.7),3,true)
			"cursor_stamp":
				var y: float = 410.0 if not warning else (305.0 if reduced_motion else lerpf(280,365,progress))
				var p = Vector2(mark.x-52,y)
				var shape = PackedVector2Array([p,p+Vector2(1,158),p+Vector2(35,129),p+Vector2(62,181),p+Vector2(84,169),p+Vector2(58,119),p+Vector2(112,116)])
				_ink_shape(shape,Color(c.darkened(0.67),fade),Color(c,fade),3)
				draw_polyline(PackedVector2Array([p+Vector2(10,28),p+Vector2(10,119),p+Vector2(32,100)]),Color(c.lightened(0.6),fade),2,true)
				if active: _splat(Vector2(mark.x,590),c,85,fade)
			"firewall_scan":
				var gate = Rect2(box.position + Vector2(15, 15), box.size - Vector2(30, 30))
				if active:
					draw_rect(gate, Color(c.darkened(0.67), 0.77 * fade))
					for row in range(7):
						var y: float = gate.position.y + 16.0 + row * 39.0
						draw_line(Vector2(gate.position.x + 7, y), Vector2(gate.end.x - 7, y), Color(c.lightened(0.55), 0.72 * fade), 3, true)
				else:
					var top_y: float = gate.position.y + 20.0
					for side in [-1, 1]:
						var x: float = mark.x + side * 58.0
						draw_line(Vector2(x, top_y), Vector2(x, 570), Color(c, 0.35 * fade), 2, true)
				for row in range(3):
					var y: float = gate.position.y + 40.0 + row * 86.0
					var shield = PackedVector2Array([Vector2(mark.x - 26, y), Vector2(mark.x + 26, y), Vector2(mark.x + 24, y + 29), Vector2(mark.x, y + 47), Vector2(mark.x - 24, y + 29)])
					_ink_shape(shield, Color(c.darkened(0.55), (0.24 if warning else 0.70) * fade), Color(c.lightened(0.45), fade), 2.0)
			"eraser_drop":
				var y: float = 557.0 if not warning else (400.0 if reduced_motion else lerpf(275,457,progress*progress))
				var p = Vector2(mark.x,y)
				_ink_shape(PackedVector2Array([p+Vector2(-77,-32),p+Vector2(57,-38),p+Vector2(77,-20),p+Vector2(71,40),p+Vector2(-71,43),p+Vector2(-82,25)]),Color(c.darkened(0.12),fade),Color(c.lightened(0.6),fade))
				_ink_shape(PackedVector2Array([p+Vector2(-24,-34),p+Vector2(36,-37),p+Vector2(32,41),p+Vector2(-28,42)]),Color("f3dfce"),Color("adc7eb"),2)
				draw_string_outline(FONT,p+Vector2(-22,10),"OOPS",HORIZONTAL_ALIGNMENT_CENTER,55,18,3,INK)
				draw_string(FONT,p+Vector2(-22,10),"OOPS",HORIZONTAL_ALIGNMENT_CENTER,55,18,Color("fff2dd"))
				if active: _splat(Vector2(mark.x,591),c,100,fade)
			"ink_geyser":
				var p = Vector2(mark.x,587)
				if warning:
					# No large translucent disc over feet during a warning.
					draw_arc(p+Vector2(0,4),94,PI*1.04,PI*1.96,28,Color(c,0.75*fade),2.5,true)
					for i in range(3): draw_arc(p+Vector2(-47+i*46,-6),6+progress*7,PI,TAU,14,c,2,true)
				else:
					var ink = PackedVector2Array([p+Vector2(-109,12)])
					for i in range(61):
						var x = -108.0+float(i)*3.6
						var height = 13+27*pow(sin(float(i)/60*PI*4),2)
						ink.append(p+Vector2(x,-height))
					ink.append(p+Vector2(109,12))
					_ink_shape(ink,Color(c.darkened(0.56),fade),Color(c,fade),3)
					for i in range(4):
						var droplet = p+Vector2(-83+i*55,-46)
						draw_circle(droplet,4.5,Color(c,fade))
						draw_arc(p+Vector2(-82+i*55,-24),8,PI*1.1,PI*1.8,10,Color(c.lightened(0.7),fade),2,true)
		# Heavy ink silhouette and bright inner line match damage_rect exactly.
		draw_rect(box,Color(INK,0.82*fade),false,6.0)
		draw_rect(box,Color(c,fade),false,2.7)

func _splat(p: Vector2, c: Color, radius: float, opacity: float) -> void:
	for i in range(7):
		var v = Vector2.from_angle(PI+float(i)*PI/6)
		var tip = p+v*radius
		draw_line(p+v*28,tip,Color(INK,opacity),7,true)
		draw_line(p+v*32,tip,Color(c,opacity),3,true)
		if i%2 == 1:
			var chip = tip+v*9
			_ink_shape(PackedVector2Array([chip+Vector2(-6,-2),chip+Vector2(1,-7),chip+Vector2(8,0),chip+Vector2(3,7)]),Color(c.darkened(0.3),opacity),Color(c,opacity),1.5)
