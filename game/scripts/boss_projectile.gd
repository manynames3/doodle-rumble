extends Node2D
## Telegraphs live in the controllers. These fixed-velocity shots never home in.
const BossStrength = preload("res://scripts/boss_strength.gd")
var owner_fighter
var kind = "void_orb"
var tint = Color("c981ff")
var velocity = Vector2.ZERO
var damage = 24
var knockback = 400.0
var elapsed = 0.0
var lifetime = 2.5
var consumed = false
var radius = 23.0
var trail: Array[Vector2] = []
var reflection_count: int = 0
var attack_serial: int = -1
var attack_special: bool = false
var attack_air_kind: String = ""

func configure(fighter, effect_kind: String, direction: int, angle: float = 0) -> void:
	owner_fighter = fighter
	kind = effect_kind
	reflection_count = 0
	attack_serial = int(fighter.attack_serial)
	attack_special = bool(fighter.is_special)
	attack_air_kind = str(fighter.attack_spec.get("air_kind", ""))
	consumed = false
	elapsed = 0.0
	trail.clear()
	radius = 23.0
	damage = 24
	knockback = 400.0
	lifetime = 2.5
	tint = Color(fighter.definition.color)
	position = fighter.position+Vector2(direction*76,-76)*fighter.body_scale
	if kind == "pellet_fan":
		position = fighter.position+Vector2(direction*48,-50)*fighter.body_scale
		radius = 13
		damage = 18
		knockback = 310
		lifetime = 1.7
	elif kind == "checksum_volley":
		position = fighter.position+Vector2(direction*58,-69)*fighter.body_scale
		radius = 16
		damage = 20
		knockback = 360
		lifetime = 1.9
	elif kind == "eclipse_volley":
		position = fighter.position+Vector2(direction*68,-83)*fighter.body_scale
		radius = 18
		damage = 15
		knockback = 390
		lifetime = 2.15
	damage = BossStrength.damage(str(fighter.definition.id), damage)
	velocity = Vector2(direction*cos(angle),sin(angle))*(590 if kind == "eclipse_volley" else 520 if kind == "checksum_volley" else 470 if kind == "pellet_fan" else 390)

func hitbox() -> Rect2:
	return Rect2(position-Vector2.ONE*radius,Vector2.ONE*radius*2)

func reflect_from(guarding_fighter) -> bool:
	if consumed or reflection_count > 0 or guarding_fighter == owner_fighter:
		return false
	reflection_count = 1
	attack_serial = -1
	attack_special = false
	attack_air_kind = "reflect"
	owner_fighter = guarding_fighter
	tint = Color(guarding_fighter.definition.color)
	velocity.x = -velocity.x
	damage = maxi(8, ceili(float(damage) * 0.75))
	knockback *= 0.8
	elapsed = 0.0
	trail.clear()
	position.x = guarding_fighter.position.x + signf(velocity.x) * (guarding_fighter.hurtbox().size.x * 0.5 + radius + 5.0)
	queue_redraw()
	return true

func tick(delta: float, target) -> bool:
	if consumed: return true
	elapsed += delta
	# Sweep the projectile's physical bounds, so fast shots cannot tunnel at low FPS.
	var old = position
	position += velocity*delta
	var sweep = Rect2(old-Vector2.ONE*radius,Vector2.ONE*radius*2).merge(hitbox())
	if sweep.intersects(target.hurtbox()):
		var previous_owner = owner_fighter
		if target.take_hit(damage,1 if velocity.x>0 else -1,knockback,-245.0,self): previous_owner.total_damage += damage
		if owner_fighter != previous_owner:
			return false
		consumed = true
		return true
	trail.push_front(position)
	if trail.size()>12: trail.pop_back()
	consumed = elapsed >= lifetime or position.x<40 or position.x>1240 or position.y<90 or position.y>615
	queue_redraw()
	return consumed

func _draw() -> void:
	var ink = Color("080914")
	if not Settings.reduced_motion:
		for i in range(trail.size()):
			var p = trail[i]-position
			draw_circle(p,radius*(1-float(i)/14),Color(tint,0.05*(1-float(i)/12)))
	for i in range(6): draw_circle(Vector2.ZERO,radius+float(i)*5,Color(tint,0.02))
	if kind == "pellet_fan":
		draw_circle(Vector2.ZERO,radius,ink)
		draw_circle(Vector2.ZERO,radius-3,tint)
		draw_circle(Vector2(-3,-4),3,Color("fff5d4"))
		draw_arc(Vector2.ZERO,radius+5,0.2,2.5,15,tint,2,true)
	elif kind == "eclipse_volley":
		var aim: Vector2 = velocity.normalized()
		var normal: Vector2 = aim.orthogonal()
		draw_line(-aim*(radius+35),-aim*4,Color(tint,0.24),10.0,true)
		draw_line(-aim*(radius+27),-aim*5,Color("f8d5ff",0.9),2.0,true)
		var points := PackedVector2Array()
		for i in range(8):
			var angle: float = float(i)*TAU/8.0-PI/8.0
			var size: float = radius+4.0 if i%2 == 0 else radius*0.64
			points.append(Vector2.from_angle(angle)*size)
		draw_colored_polygon(points,ink)
		var outline: PackedVector2Array = points.duplicate()
		outline.append(outline[0])
		draw_polyline(outline,Color("070713"),4.2,true)
		draw_polyline(outline,Color(tint),2.2,true)
		draw_arc(Vector2.ZERO,radius+10.0,-2.5,1.55,22,Color(tint,0.86),3.0,true)
		draw_arc(Vector2.ZERO,radius+5.0,0.25,4.2,22,Color("f5d9ff",0.76),1.5,true)
		draw_colored_polygon(PackedVector2Array([-aim*10.0+normal*4.0,aim*7.0-normal*8.0,aim*8.0+normal*7.0]),Color("f3d7ff"))
	elif kind == "checksum_volley":
		var points = PackedVector2Array([Vector2(-radius,-radius*0.75),Vector2(radius*0.7,-radius),Vector2(radius,radius*0.72),Vector2(-radius*0.8,radius)])
		draw_colored_polygon(points,ink)
		var outline = points.duplicate()
		outline.append(points[0])
		draw_polyline(outline,tint,4,true)
		draw_line(Vector2(-7,-3),Vector2(1,4),Color("fff9d0"),3,true)
		draw_line(Vector2(1,4),Vector2(9,-5),Color("fff9d0"),3,true)
	else:
		draw_circle(Vector2.ZERO,radius,ink)
		var spin = 0.0 if Settings.reduced_motion else elapsed*2.7
		for i in range(4):
			var points = PackedVector2Array()
			for j in range(18):
				var angle = spin+i*TAU/4+j*0.07
				points.append(Vector2.from_angle(angle)*(radius+sin(float(j)*0.5)*3))
			draw_polyline(points,tint,4,true)
			draw_polyline(points,Color("f9dcff"),1,true)
		var eyes = PackedVector2Array([Vector2(-8,-2),Vector2(-3,2),Vector2(-8,6),Vector2(-10,2)])
		draw_colored_polygon(eyes,Color("efb7ff"))
		for i in range(eyes.size()): eyes[i].x += 15
		draw_colored_polygon(eyes,Color("efb7ff"))
