extends Node2D
## A moving hitbox, independent of the weapon illustration and display FPS.
const BossStrength = preload("res://scripts/boss_strength.gd")
var owner_fighter
var kind = "fragment"
var velocity = Vector2.ZERO
var lifetime = 1.1
var elapsed = 0.0
var damage = 20
var tint = Color("61a7ed")
var consumed: bool = false
var knockback: float = 440.0
var visual_scale: float = 1.0
var reflection_count: int = 0
var attack_serial: int = -1
var attack_special: bool = false
var attack_air_kind: String = ""

func configure(fighter, effect_kind: String, direction: int) -> void:
	owner_fighter = fighter
	kind = effect_kind
	tint = Color(fighter.definition.color)
	elapsed = 0.0
	consumed = false
	reflection_count = 0
	attack_serial = int(fighter.attack_serial)
	attack_special = bool(fighter.is_special)
	attack_air_kind = str(fighter.attack_spec.get("air_kind", ""))
	velocity = Vector2.ZERO
	damage = 20
	knockback = 440.0
	visual_scale = float(fighter.body_scale)
	scale = Vector2(visual_scale,visual_scale)
	if kind == "shockwave":
		position = Vector2(fighter.position.x + direction * 44 * visual_scale,600)
		velocity.x = direction * 520
		damage = 32 if fighter.definition.id == "dark_lord" else 25
		lifetime = 0.8
	elif kind in ["arrow", "signal", "swarm"]:
		position = fighter.position + Vector2(direction * 44,-68) * visual_scale
		if kind == "arrow":
			velocity.x = direction * 640.0
			damage = int(fighter.attack_spec.get("projectile_damage",12))
			knockback = 310.0
			lifetime = 0.60
		elif kind == "signal":
			velocity.x = direction * 760.0
			damage = 26 if fighter.definition.id == "h4ck3r" else 24
			knockback = 470.0
			lifetime = 1.15
		else:
			velocity.x = direction * 360.0
			damage = 22
			knockback = 400.0
			lifetime = 1.35
	else:
		position = fighter.position + Vector2(direction * 44,-68) * visual_scale
		velocity = Vector2(direction * 530,-165)
		lifetime = 1.05
	# Arrow damage was derived from the fighter's scaled attack specification.
	# All other effects have independent base payloads and are scaled here once.
	if kind != "arrow":
		damage = BossStrength.damage(str(fighter.definition.id), damage)

func hitbox() -> Rect2:
	match kind:
		"shockwave": return Rect2(position + Vector2(-26,-46)*visual_scale,Vector2(52,46)*visual_scale)
		"arrow": return Rect2(position-Vector2(27,7)*visual_scale,Vector2(54,14)*visual_scale)
		"signal": return Rect2(position-Vector2(43,12)*visual_scale,Vector2(86,24)*visual_scale)
		"swarm": return Rect2(position-Vector2(35,30)*visual_scale,Vector2(70,60)*visual_scale)
	return Rect2(position-Vector2(18,18)*visual_scale,Vector2(36,36)*visual_scale)

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
	# A reflected shot is useful but weaker than a fresh special. The defender
	# still must recover before attacking, and one shot cannot ping-pong forever.
	damage = maxi(8, ceili(float(damage) * 0.75))
	knockback *= 0.8
	elapsed = 0.0
	var guard_box: Rect2 = guarding_fighter.hurtbox()
	position.x = guarding_fighter.position.x + signf(velocity.x) * (guard_box.size.x * 0.5 + hitbox().size.x * 0.5 + 5.0)
	queue_redraw()
	return true

func tick(delta: float, target) -> bool:
	if consumed:
		return true
	elapsed += delta
	var old_box: Rect2 = hitbox()
	position += velocity * delta
	if kind == "fragment":
		velocity.y += 420 * delta
	if old_box.merge(hitbox()).intersects(target.hurtbox()):
		var previous_owner = owner_fighter
		if target.take_hit(damage,1 if velocity.x >= 0 else -1,knockback,-245.0,self):
			previous_owner.total_damage += damage
		if owner_fighter != previous_owner:
			return false
		consumed = true
		return true
	queue_redraw()
	consumed = elapsed >= lifetime or position.x < 58 or position.x > 1222 or position.y > 630
	return consumed

func _draw() -> void:
	var ink = Color("070b18")
	# A faint local pool makes each projectile cast its own color without flashing the screen.
	var aura_radius: float = 54.0 if kind == "signal" else 42.0 if kind in ["shockwave","swarm"] else 31.0
	draw_circle(Vector2.ZERO,aura_radius,Color(tint,0.045))
	draw_circle(Vector2.ZERO,aura_radius*0.58,Color(tint,0.075))
	if kind in ["arrow", "signal"]:
		_draw_arrow(ink)
	elif kind == "swarm":
		_draw_swarm(ink)
	elif kind == "shockwave":
		var travel_direction: float = signf(velocity.x)
		var ground_glow := PackedVector2Array([Vector2(-82,3),Vector2(-51,-9),Vector2(5,-14),Vector2(70,-6),Vector2(91,3),Vector2(42,10),Vector2(-46,9)])
		draw_colored_polygon(ground_glow,Color(tint,0.10))
		for i in range(5):
			var x = -float(i) * travel_direction * 18
			var points = PackedVector2Array([Vector2(x-14,0),Vector2(x-9,-27-i*5),Vector2(x+3,-53+i*7),Vector2(x+16,0)])
			var alpha: float = 0.98-float(i)*0.14
			points.append(points[0])
			draw_polyline(points,Color(tint,alpha*0.055),27,true)
			draw_polyline(points,Color(tint,alpha*0.14),14,true)
			draw_colored_polygon(points,Color(tint.darkened(0.65),alpha))
			draw_polyline(points,Color(ink,alpha),5.0+float(i%2)*1.2,true)
			draw_polyline(points,Color(tint,alpha),2.3,true)
			draw_line(Vector2(x-7,-24-i*6),Vector2(x+4,-42+i*8),Color(tint.lightened(0.65),alpha),1.3,true)
			var chip := Vector2(x-8,-45-i*7)
			var debris := PackedVector2Array([chip+Vector2(-5,0),chip+Vector2(1,-7),chip+Vector2(8,-2),chip+Vector2(4,6),chip+Vector2(-4,4)])
			draw_colored_polygon(debris,Color(tint.darkened(0.45),alpha))
			debris.append(debris[0])
			draw_polyline(debris,Color(ink,alpha),2.0+float(i%2)*0.8,true)
		draw_line(Vector2(-91*travel_direction,0),Vector2(45*travel_direction,0),Color(ink,0.88),5.0,true)
		draw_line(Vector2(-91*travel_direction,-1),Vector2(45*travel_direction,-1),Color(tint.lightened(0.50),0.86),2.0,true)
	else:
		if not Settings.reduced_motion:
			var direction := velocity.normalized()
			# The decorative trail grows only after the real shard travels, capped near 250 world pixels.
			var long_tail: float = minf(172.0,elapsed*velocity.length()/visual_scale)
			if long_tail > 18.0:
				var normal := direction.orthogonal()
				var trail_path := PackedVector2Array([-direction*long_tail+normal*5,-direction*long_tail*0.70-normal*4,-direction*long_tail*0.38+normal*6,-direction*17])
				draw_polyline(trail_path,Color(tint,0.045),29,true)
				draw_polyline(trail_path,Color(tint,0.14),14,true)
				draw_polyline(trail_path,Color(ink,0.82),5.5,true)
				draw_polyline(trail_path,Color(tint.lightened(0.42),0.90),2.5,true)
				for i in range(3):
					var back: float = long_tail*(0.28+float(i)*0.19)
					var chip := -direction*back+normal*(-11.0+float(i)*10.0)
					var chip_shape := PackedVector2Array([chip+Vector2(-3,-2),chip+Vector2(2,-5),chip+Vector2(5,1),chip+Vector2(-1,4),chip+Vector2(-3,-2)])
					draw_colored_polygon(chip_shape,Color(tint.lightened(0.22),0.82))
					draw_polyline(chip_shape,Color(ink,0.78),1.5,true)
				draw_line(-direction*long_tail*0.80+normal*13,-direction*24+normal*13,Color(tint.lightened(0.65),0.68),1.6,true)
				draw_line(-direction*long_tail*0.62-normal*12,-direction*21-normal*12,Color(tint,0.57),2.0,true)
		draw_set_transform(Vector2.ZERO,0.3 if Settings.reduced_motion else elapsed*7)
		var shard := PackedVector2Array([Vector2(-15,-11),Vector2(2,-18),Vector2(16,-7),Vector2(11,12),Vector2(-4,18),Vector2(-17,6),Vector2(-15,-11)])
		draw_polyline(shard,Color(tint,0.09),15,true)
		draw_polyline(shard,Color(tint,0.22),7,true)
		draw_colored_polygon(shard,tint)
		draw_colored_polygon(PackedVector2Array([shard[0],shard[1],shard[2],Vector2(0,-1)]),tint.lightened(0.62))
		draw_colored_polygon(PackedVector2Array([Vector2(0,-1),shard[2],shard[3],shard[4]]),tint.darkened(0.32))
		draw_polyline(shard,ink,3.6,true)
		draw_polyline(PackedVector2Array([shard[0],Vector2(0,-1),shard[4]]),ink,1.8,true)
		draw_line(Vector2(0,-1),shard[2],ink,1.8,true)
		draw_polyline(PackedVector2Array([shard[0]+Vector2(1,-1),shard[1]+Vector2(0,-1),shard[2]+Vector2(1,0)]),tint.lightened(0.78),1.2,true)
		draw_polyline(PackedVector2Array([Vector2(-12,-4),Vector2(-7,-1),Vector2(-10,5),Vector2(-5,8)]),Color(ink,0.7),1.0,true)
		for i in range(2):
			var chip := Vector2(-28-i*11,9-i*20)
			var chip_shape := PackedVector2Array([chip+Vector2(-3,-2),chip+Vector2(2,-4),chip+Vector2(4,1),chip+Vector2(-1,4),chip+Vector2(-3,-2)])
			draw_colored_polygon(chip_shape,tint.lightened(0.24))
			draw_polyline(chip_shape,ink,1.6,true)
		draw_set_transform(Vector2.ZERO)

func _draw_arrow(ink: Color) -> void:
	var bright: bool = kind == "signal"
	var rear: float = -48.0 if bright else -26.0
	var tip: float = 49.0 if bright else 29.0
	var head_width: float = 15.0 if bright else 8.0
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1 if velocity.x >= 0 else -1,1))
	if bright:
		draw_line(Vector2(rear-54,0),Vector2(tip,0),Color(tint,0.045),38,true)
		draw_line(Vector2(rear-31,0),Vector2(tip,0),Color(tint,0.12),23,true)
		draw_line(Vector2(rear-17,0),Vector2(tip-5,0),Color(tint,0.26),12,true)
		if not Settings.reduced_motion:
			for i in range(5):
				draw_line(Vector2(rear-20-i*18,-14+i*7),Vector2(rear+2-i*8,-14+i*7),Color(tint.lightened(0.45),0.60-float(i)*0.07),1.5+float(i%2),true)
	else:
		draw_line(Vector2(rear-28,0),Vector2(tip,0),Color(tint,0.08),16,true)
	draw_line(Vector2(rear,0),Vector2(tip-9,0),ink,7 if bright else 4,true)
	draw_line(Vector2(rear,0),Vector2(tip-9,0),tint.lightened(0.58),3 if bright else 2,true)
	var head := PackedVector2Array([Vector2(tip,0),Vector2(tip-18,-head_width),Vector2(tip-13,0),Vector2(tip-18,head_width),Vector2(tip,0)])
	draw_colored_polygon(head,tint.lightened(0.4))
	draw_polyline(head,ink,2,true)
	for side in [-1,1]:
		var feather := PackedVector2Array([Vector2(rear,0),Vector2(rear-6,side*7),Vector2(rear+7,side*6),Vector2(rear+13,0)])
		draw_colored_polygon(feather,tint)
		draw_polyline(feather,ink,1.5,true)
	if bright:
		draw_line(Vector2(rear+6,-2),Vector2(tip-8,-2),Color("fffaf4"),1.6,true)
	draw_set_transform(Vector2.ZERO)

func _draw_swarm(ink: Color) -> void:
	# Three visible helpers move as one projectile and share its one-hit lifecycle.
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1 if velocity.x >= 0 else -1,1))
	if not Settings.reduced_motion:
		for i in range(3):
			var trail_y: float = -21+float(i)*19
			draw_line(Vector2(-88-i*9,trail_y),Vector2(-25-i*3,trail_y),Color(tint,0.065),15,true)
			draw_line(Vector2(-81-i*7,trail_y),Vector2(-25-i*3,trail_y),Color(ink,0.72),4.0,true)
			draw_line(Vector2(-74-i*6,trail_y),Vector2(-25-i*3,trail_y),Color(tint.lightened(0.50),0.76),1.8,true)
	var origins := [Vector2(-17,-21),Vector2(16,-10),Vector2(-8,4)]
	for i in range(3):
		var bob: float = 0.0 if Settings.reduced_motion else sin(elapsed*17.0+i*2.0)*1.6
		var at: Vector2 = origins[i]+Vector2(0,bob)
		var color := tint.lightened(i*0.13)
		draw_circle(at,8,Color(color,0.14))
		draw_circle(at,5.5,ink)
		draw_arc(at,5.5,0,TAU,16,color,2.2,true)
		draw_circle(at+Vector2(2,-1),1.1,Color("fff9da"))
		var limbs := [PackedVector2Array([at+Vector2(0,6),at+Vector2(0,15),at+Vector2(-7,23)]),PackedVector2Array([at+Vector2(0,15),at+Vector2(8,22)]),PackedVector2Array([at+Vector2(-7,14),at+Vector2(0,9),at+Vector2(8,12)])]
		for points in limbs:
			draw_polyline(points,ink,4.8,true)
			draw_polyline(points,color,2.2,true)
	draw_set_transform(Vector2.ZERO)
