extends Node2D
## Telegraphs live in the controllers. These fixed-velocity shots never home in.
const BossStrength = preload("res://scripts/boss_strength.gd")

static func muzzle_position(fighter, direction: int, frame_name: String = "fire") -> Vector2:
	var fallback: Vector2 = fighter.position + Vector2(direction * 70.0, -104.0) * fighter.body_scale
	if not is_instance_valid(fighter.rig) or not fighter.rig.has_packed_art(): return fallback
	var art = fighter.rig.packed_art
	var frame: Dictionary = art.frames.get(frame_name, {})
	var muzzle: Array = frame.get("muzzle", [])
	if muzzle.size() != 2: return fallback
	return fighter.position + Vector2(direction * float(muzzle[0]) * art.pixels_to_local * absf(fighter.rig.scale.x),
		float(muzzle[1]) * art.pixels_to_local * absf(fighter.rig.scale.y))

var owner_fighter
var kind = "void_orb"
var tint = Color("c981ff")
var velocity = Vector2.ZERO
var damage = 24
var knockback = 400.0
var elapsed = 0.0
var lifetime = 2.5
var consumed = false
var hit_target = false
var radius = 23.0
var trail: Array[Vector2] = []
var reflection_count: int = 0
var attack_serial: int = -1
var attack_special: bool = false
var attack_air_kind: String = ""
var missile_texture: Texture2D
var exhaust_texture: Texture2D
var crackle_texture: Texture2D
var burst_ready := false

func _optional_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path)
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty(): return ImageTexture.create_from_image(image)
	return null

func configure(fighter, effect_kind: String, direction: int, angle: float = 0) -> void:
	owner_fighter = fighter
	kind = effect_kind
	reflection_count = 0
	attack_serial = int(fighter.attack_serial)
	attack_special = bool(fighter.is_special)
	attack_air_kind = str(fighter.attack_spec.get("air_kind", ""))
	consumed = false
	hit_target = false
	elapsed = 0.0
	trail.clear()
	radius = 23.0
	damage = 24
	knockback = 400.0
	lifetime = 2.5
	tint = Color(fighter.definition.color)
	missile_texture = null
	exhaust_texture = null
	crackle_texture = null
	burst_ready = false
	position = fighter.position+Vector2(direction*76,-76)*fighter.body_scale
	if kind in ["rocket_single", "firecracker_arc", "firework_fan"]:
		position = muzzle_position(fighter, direction, "cast_impact")
		tint = Color("51dff2")
		radius = 14.0 if kind == "rocket_single" else 12.0 if kind == "firecracker_arc" else 10.0
		damage = 18 if kind == "rocket_single" else 0 if kind == "firecracker_arc" else 10
		knockback = 330.0
		lifetime = 0.46 if kind == "firecracker_arc" else 1.65
		crackle_texture = _optional_texture("res://assets/character_art/crackle/firecracker.png" if kind == "firecracker_arc" else "res://assets/character_art/crackle/rocket.png")
		if kind != "firecracker_arc": exhaust_texture = _optional_texture("res://assets/character_art/crackle/effect_exhaust.png")
	elif kind == "firework_spark":
		tint = Color("ffe083")
		radius = 8.0
		damage = 8
		knockback = 245.0
		lifetime = 0.49
		crackle_texture = _optional_texture("res://assets/character_art/crackle/spark.png")
	elif kind.begins_with("missile_"):
		position = muzzle_position(fighter, direction)
		tint = Color("ff6548")
		radius = 18.0 if kind == "missile_single" else 16.0
		damage = 18 if kind == "missile_single" else 11 if kind in ["missile_salvo", "missile_burst"] else 13
		knockback = 370.0
		lifetime = 1.9
		missile_texture = _optional_texture("res://assets/character_art/fuse/missile.png")
		exhaust_texture = _optional_texture("res://assets/character_art/fuse/effect_exhaust.png")
	elif kind == "pellet_fan":
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
	damage = BossStrength.damage(str(fighter.definition.id), damage, int(fighter.combat_difficulty))
	velocity = Vector2(direction*cos(angle),sin(angle))*(650 if kind.begins_with("missile_") else 610 if kind == "rocket_single" else 565 if kind == "firework_fan" else 560 if kind == "firecracker_arc" else 590 if kind == "eclipse_volley" else 520 if kind == "checksum_volley" else 470 if kind == "pellet_fan" else 390)
	if kind == "firecracker_arc": velocity.y = -440.0 + sin(angle) * 170.0

func configure_spark(fighter, origin: Vector2, heading: Vector2) -> void:
	configure(fighter, "firework_spark", 1)
	position = origin
	velocity = heading.normalized() * 390.0
	attack_special = true

func spawn_fragments() -> Array:
	var sparks: Array = []
	if not burst_ready or kind != "firecracker_arc": return sparks
	burst_ready = false
	for i in range(8):
		var spark = get_script().new()
		spark.configure_spark(owner_fighter, position, Vector2.from_angle(-PI + float(i) * TAU / 8.0))
		spark.attack_serial = attack_serial
		sparks.append(spark)
	return sparks

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
	if kind == "firecracker_arc":
		velocity.y += 1150.0 * delta
		trail.push_front(position)
		if trail.size() > 10: trail.pop_back()
		if elapsed >= lifetime or position.x < 40 or position.x > 1240 or position.y < 90 or position.y > 615:
			burst_ready = elapsed >= lifetime and position.x >= 45 and position.x <= 1235 and position.y >= 100 and position.y <= 605
			consumed = true
		queue_redraw()
		return consumed
	var sweep = Rect2(old-Vector2.ONE*radius,Vector2.ONE*radius*2).merge(hitbox())
	if sweep.intersects(target.hurtbox()):
		var previous_owner = owner_fighter
		if target.take_hit(damage,1 if velocity.x>0 else -1,knockback,-245.0,self): previous_owner.total_damage += damage
		if owner_fighter != previous_owner:
			return false
		hit_target = true
		consumed = true
		return true
	trail.push_front(position)
	if trail.size()>12: trail.pop_back()
	consumed = elapsed >= lifetime or position.x<40 or position.x>1240 or position.y<90 or position.y>615
	queue_redraw()
	return consumed

func spawn_impact(parent: Node2D) -> void:
	if Settings.reduced_motion: return
	var crackle_impact: bool = kind == "firecracker_arc" and burst_ready or hit_target and kind in ["rocket_single", "firework_fan", "firework_spark"]
	if not crackle_impact and not (hit_target and kind.begins_with("missile_")): return
	var texture := _optional_texture("res://assets/character_art/crackle/effect_impact_burst.png" if crackle_impact else "res://assets/character_art/fuse/effect_impact_burst.png")
	if texture == null: return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	var size: float = 158.0 if kind == "firecracker_arc" else 112.0 if kind == "firework_spark" else 120.0 if kind.begins_with("missile_") else 136.0
	sprite.scale = Vector2.ONE * (size / maxf(float(texture.get_width()), float(texture.get_height())))
	sprite.z_index = 7
	parent.add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_interval(0.06)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15 if kind.begins_with("missile_") else 0.18)
	tween.tween_callback(sprite.queue_free)

func _draw() -> void:
	var ink = Color("080914")
	if kind in ["rocket_single", "firecracker_arc", "firework_fan", "firework_spark"]:
		if not Settings.reduced_motion:
			for i in range(trail.size()):
				var p: Vector2 = trail[i] - position
				var fade: float = 1.0 - float(i) / float(trail.size() + 1)
				draw_circle(p, radius * (0.9 + float(i) * 0.08), Color(tint, 0.20 * fade))
		if kind == "firecracker_arc":
			draw_arc(Vector2.ZERO, radius + 8.0 + elapsed * 22.0, 0.0, TAU, 28, Color("ffe083", 0.65), 2.5, true)
		draw_set_transform(Vector2.ZERO, velocity.angle(), Vector2.ONE)
		var visual_size := Vector2(70, 29) if kind == "rocket_single" else Vector2(48, 26) if kind == "firecracker_arc" else Vector2(55, 23) if kind == "firework_fan" else Vector2(23, 23)
		var nose_offset := 20.0 if kind == "rocket_single" else 15.0 if kind == "firework_fan" else 0.0
		if exhaust_texture != null and not Settings.reduced_motion:
			draw_texture_rect(exhaust_texture, Rect2(Vector2(-visual_size.x * 0.5 - nose_offset - 50.0, -17.0), Vector2(55, 34)), false, Color(1, 1, 1, 0.85))
		if crackle_texture != null:
			draw_texture_rect(crackle_texture, Rect2(-visual_size * 0.5 - Vector2(nose_offset, 0), visual_size), false)
		elif kind == "firework_spark":
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(-2, -5), Vector2(12, 0), Vector2(-2, 5)]), Color("ffe083"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-25 - nose_offset, -8), Vector2(12 - nose_offset, -8), Vector2(28 - nose_offset, 0), Vector2(12 - nose_offset, 8), Vector2(-25 - nose_offset, 8)]), ink)
			draw_colored_polygon(PackedVector2Array([Vector2(-21 - nose_offset, -5), Vector2(10 - nose_offset, -5), Vector2(22 - nose_offset, 0), Vector2(10 - nose_offset, 5), Vector2(-21 - nose_offset, 5)]), tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if kind.begins_with("missile_"):
		if not Settings.reduced_motion:
			for i in range(trail.size()):
				var p: Vector2 = trail[i] - position
				var fade: float = 1.0 - float(i) / float(trail.size() + 1)
				draw_circle(p, 5.0 + float(i) * 1.2, Color("f5d5c2", 0.22 * fade))
				draw_circle(p, 2.2 + float(i) * 0.4, Color(tint, 0.26 * fade))
		draw_set_transform(Vector2.ZERO, velocity.angle(), Vector2.ONE)
		if exhaust_texture != null and not Settings.reduced_motion:
			draw_texture_rect(exhaust_texture, Rect2(-125.0, -18.0, 47.0, 36.0), false, Color(1, 1, 1, 0.82))
		if missile_texture != null:
			draw_texture_rect(missile_texture, Rect2(-83.0, -20.0, 102.0, 40.0), false)
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-83,-14),Vector2(-9,-14),Vector2(19,0),Vector2(-9,14),Vector2(-83,14)]), ink)
			draw_colored_polygon(PackedVector2Array([Vector2(-79,-10),Vector2(-12,-10),Vector2(11,0),Vector2(-12,10),Vector2(-79,10)]), tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
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
