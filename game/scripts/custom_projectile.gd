extends Node2D
## Fixed-tick physical effects for workshop kits. Collision does not follow the art.

const FLOOR_Y := 600.0
const WORKSHOP_BONE: Texture2D = preload("res://assets/workshop/weapons/dinosaur_bone_v2.png")
const WORKSHOP_BALL: Texture2D = preload("res://assets/workshop/weapons/soccer_ball_v2.png")
const WORKSHOP_CHICKEN: Texture2D = preload("res://assets/workshop/weapons/rubber_chicken_v1.png")
const WORKSHOP_CRAYON: Texture2D = preload("res://assets/workshop/weapons/giant_crayon_v1.png")
var owner_fighter
var kind: String = ""
var velocity := Vector2.ZERO
var tint := Color("f7c968")
var damage: int = 22
var knockback: float = 400.0
var elapsed: float = 0.0
var lifetime: float = 1.5
var consumed: bool = false
var reflection_count: int = 0
var attack_serial: int = -1
var attack_special: bool = true
var attack_air_kind: String = ""
var bounce_count: int = 0
var hit_targets: Dictionary = {}
var platforms: Array[Rect2] = []
var cast_origin := Vector2.ZERO
var cast_direction: int = 1
var returning: bool = false
var reflected: bool = false
var cleanup_done: bool = false
var visual_scale: float = 1.0
var hidden_weapon_owner = null
var attack_surface_y: float = FLOOR_Y

func set_platforms(walkable: Array) -> void:
	platforms.clear()
	for rect in walkable:
		if rect is Rect2: platforms.append(rect)

func configure(fighter, effect_kind: String, direction: int, walkable_platforms: Array = []) -> void:
	owner_fighter = fighter
	kind = effect_kind
	tint = Color(fighter.definition.color)
	damage = int(fighter.attack_spec.get("damage",22))
	knockback = float(fighter.attack_spec.get("knockback",400.0))
	attack_serial = int(fighter.attack_serial)
	attack_special = true
	attack_air_kind = ""
	visual_scale = float(fighter.body_scale)
	cast_direction = 1 if direction >= 0 else -1
	cast_origin = fighter.position
	platforms.clear()
	for rect in walkable_platforms:
		if rect is Rect2: platforms.append(rect)
	attack_surface_y = _resolve_attack_surface_y(cast_origin)
	position = fighter.position + Vector2(cast_direction * 45.0, -82.0) * visual_scale
	match kind:
		"ore_pop":
			position = Vector2(fighter.position.x, attack_surface_y)
			velocity = Vector2.ZERO
			lifetime = 0.67
		"fossil_fetch":
			velocity = Vector2(cast_direction * 640.0, -115.0)
			lifetime = 1.25
			fighter.thrown_weapon_hidden = true
			hidden_weapon_owner = fighter
		"swerve_shot":
			position = fighter.position + Vector2(cast_direction * 68.0,-25.0) * visual_scale
			velocity = Vector2(cast_direction * 510.0, -230.0)
			lifetime = 2.4
		"cluckquake":
			position = Vector2(fighter.position.x,attack_surface_y)
			velocity = Vector2.ZERO
			lifetime = 0.34
		"rainbow_ruckus":
			position = Vector2(fighter.position.x,attack_surface_y)
			velocity = Vector2.ZERO
			lifetime = 0.48
		_:
			consumed = true
	fighter.active_custom_projectile_count += 1
	queue_redraw()

func _resolve_attack_surface_y(origin: Vector2) -> float:
	# Surface waves follow the floor/platform beneath the caster. While airborne,
	# choose the nearest walkable surface below their feet, then fall back to floor.
	var surface_y := FLOOR_Y
	for rect in platforms:
		var overlaps_x: bool = origin.x >= rect.position.x - 30.0 and origin.x <= rect.end.x + 30.0
		var is_below_feet: bool = rect.position.y >= origin.y - 8.0 and rect.position.y <= FLOOR_Y
		if overlaps_x and is_below_feet:
			surface_y = minf(surface_y, rect.position.y)
	return surface_y

func cleanup() -> void:
	if cleanup_done: return
	cleanup_done = true
	if is_instance_valid(owner_fighter):
		owner_fighter.active_custom_projectile_count = maxi(0,owner_fighter.active_custom_projectile_count - 1)
	if is_instance_valid(hidden_weapon_owner):
		hidden_weapon_owner.thrown_weapon_hidden = false
		hidden_weapon_owner = null

func _exit_tree() -> void:
	cleanup()

func hitbox() -> Rect2:
	match kind:
		"ore_pop":
			var index := _ore_active_index()
			if index < 0: return Rect2()
			var x := _ore_x(index)
			return Rect2(Vector2(x - 33.0, attack_surface_y - 165.0),Vector2(66.0,177.0))
		"cluckquake":
			if elapsed < 0.045 or elapsed > 0.27: return Rect2()
			var radius := 62.0 + clampf((elapsed-0.045)/0.225,0.0,1.0)*116.0
			return Rect2(Vector2(position.x-radius,attack_surface_y-142.0),Vector2(radius*2.0,154.0))
		"rainbow_ruckus":
			if elapsed < 0.055 or elapsed > 0.40: return Rect2()
			var first := position.x + cast_direction*38.0
			var last := position.x + cast_direction*344.0
			return Rect2(Vector2(minf(first,last),attack_surface_y-126.0),Vector2(absf(last-first),138.0))
		"fossil_fetch": return Rect2(position-Vector2(32.0,18.0)*visual_scale,Vector2(64.0,36.0)*visual_scale)
		"swerve_shot": return Rect2(position-Vector2(17.0,17.0)*visual_scale,Vector2(34.0,34.0)*visual_scale)
	return Rect2()

func _ore_x(index: int) -> float:
	return clampf(cast_origin.x + cast_direction * (110.0 + 94.0 * index),70.0,1210.0)

func _ore_active_index() -> int:
	# Each marked seam pops after its own readable warning.
	for index in range(3):
		var start := 0.16 + 0.14 * index
		if elapsed >= start and elapsed < start + 0.12:
			return index
	return -1

func reflect_from(guarding_fighter) -> bool:
	if consumed or kind in ["ore_pop","cluckquake","rainbow_ruckus"] or reflection_count > 0 or guarding_fighter == owner_fighter:
		return false
	# A returning bone leaves its original thrower's hand as soon as ownership changes.
	cleanup()
	reflection_count = 1
	reflected = true
	returning = false
	attack_serial = -1
	attack_special = false
	attack_air_kind = "reflect"
	owner_fighter = guarding_fighter
	tint = Color(guarding_fighter.definition.color)
	velocity.x = -velocity.x if absf(velocity.x) > 10.0 else -cast_direction * 650.0
	if kind == "fossil_fetch":
		velocity.y = -45.0
		lifetime = 1.1
	damage = maxi(8,ceili(float(damage) * 0.75))
	knockback *= 0.8
	elapsed = 0.0
	var guard_box: Rect2 = guarding_fighter.hurtbox()
	position.x = guarding_fighter.position.x + signf(velocity.x) * (guard_box.size.x * 0.5 + hitbox().size.x * 0.5 + 5.0)
	# This is the same node and the same single global reflection allowance.
	cleanup_done = false
	guarding_fighter.active_custom_projectile_count += 1
	queue_redraw()
	return true

func tick(delta: float, target) -> bool:
	if consumed: return true
	elapsed += delta
	var old_box: Rect2 = hitbox()
	if kind in ["ore_pop","cluckquake","rainbow_ruckus"]:
		# The active seam is computed from fixed elapsed time, never render frames.
		pass
	elif kind == "fossil_fetch":
		if not returning and not reflected and (elapsed >= 0.38 or absf(position.x - cast_origin.x) >= 295.0):
			returning = true
		if returning:
			if not is_instance_valid(owner_fighter):
				consumed = true
				cleanup()
				return true
			var home: Vector2 = owner_fighter.position + Vector2(owner_fighter.facing * 28.0,-78.0) * visual_scale
			velocity = (home-position).normalized() * 720.0
			if position.distance_to(home) <= maxf(21.0,velocity.length()*delta):
				consumed = true
				cleanup()
				return true
		position += velocity * delta
	else:
		var before := position
		velocity.y += 870.0 * delta
		position += velocity * delta
		_bounce_from_stage(before,position)
	var current_box: Rect2 = hitbox()
	var stationary_attack: bool = kind in ["ore_pop","cluckquake","rainbow_ruckus"]
	var contact: bool = current_box.has_area() and (current_box if stationary_attack else old_box.merge(current_box)).intersects(target.hurtbox())
	if contact and not hit_targets.has(target.get_instance_id()):
		hit_targets[target.get_instance_id()] = true
		var previous_owner = owner_fighter
		var impact_direction: int = (1 if target.position.x >= cast_origin.x else -1) if kind == "cluckquake" else cast_direction if kind in ["ore_pop","rainbow_ruckus"] else 1 if velocity.x >= 0 else -1
		if target.take_hit(damage,impact_direction,knockback,-245.0,self):
			if is_instance_valid(previous_owner): previous_owner.total_damage += damage
		if owner_fighter != previous_owner:
			return false
		if kind == "swerve_shot":
			consumed = true
	if elapsed >= lifetime or position.x < 45.0 or position.x > 1235.0 or position.y > 655.0:
		consumed = true
	if consumed: cleanup()
	queue_redraw()
	return consumed

func _bounce_from_stage(before: Vector2, after: Vector2) -> void:
	var radius := 17.0 * visual_scale
	var plane := INF
	for rect in platforms:
		if before.y + radius <= rect.position.y + 0.001 and after.y + radius >= rect.position.y and after.x >= rect.position.x-radius and after.x <= rect.end.x+radius:
			plane = minf(plane,rect.position.y)
	if before.y + radius <= FLOOR_Y + 0.001 and after.y + radius >= FLOOR_Y:
		plane = minf(plane,FLOOR_Y)
	if plane == INF: return
	position.y = plane-radius
	if bounce_count >= 2:
		consumed = true
		return
	bounce_count += 1
	velocity.y = -maxf(275.0,absf(velocity.y)*0.65)
	velocity.x *= 0.88

func _draw() -> void:
	var ink := Color("0a0b15")
	if kind == "ore_pop":
		for index in range(3):
			var local := Vector2(_ore_x(index)-position.x,0)
			var begin := 0.16+0.14*index
			var active := elapsed >= begin and elapsed < begin+0.12
			if elapsed < begin:
				var grow := clampf((elapsed-(begin-0.16))/0.16,0.0,1.0)
				draw_arc(local,27.0+8.0*grow,PI,TAU,14,Color(tint,0.62),2.0,true)
				draw_line(local+Vector2(-23,-3),local+Vector2(22,2),ink,3.0,true)
			elif active:
				draw_circle(local+Vector2(0,-55),54.0,Color(tint,0.13))
				var shard := PackedVector2Array([local+Vector2(-24,0),local+Vector2(-12,-92),local+Vector2(0,-155),local+Vector2(11,-108),local+Vector2(29,0)])
				draw_colored_polygon(shard,Color(tint,0.85))
				shard.append(shard[0])
				draw_polyline(shard,ink,4.0,true)
				draw_line(local+Vector2(-6,-95),local+Vector2(0,-140),Color.WHITE,2.0,true)
		return
	if kind == "cluckquake":
		var pulse := 0.0 if elapsed < 0.045 else clampf((elapsed-0.045)/0.225,0.0,1.0)
		var radius := 18.0 + pulse*116.0
		draw_circle(Vector2(0,-38),radius*0.68,Color("ffd75d",0.10))
		for direction in [-1.0,1.0]:
			var wave_ring := PackedVector2Array()
			for i in range(14):
				var t := float(i)/13.0
				wave_ring.append(Vector2(direction*(10.0+radius*t),-72.0-sin(t*PI)*radius*0.42))
			draw_polyline(wave_ring,Color("0a0b15",0.95),7.0,true)
			draw_polyline(wave_ring,Color("fff3bf",0.96),3.5,true)
			var wave := PackedVector2Array([Vector2(direction*24,-12),Vector2(direction*38,-36),Vector2(direction*55,-22),Vector2(direction*71,-58),Vector2(direction*88,-31)])
			draw_polyline(wave,Color("e99d34",0.92),5.0,true)
			for i in range(2):
				var feather := Vector2(direction*(35+i*51),-86-i*10)
				draw_line(feather,feather+Vector2(direction*9,-14),Color("fff1b5",0.93),3.0,true)
				draw_line(feather+Vector2(direction*3,-4),feather+Vector2(direction*12,-5),Color("ef9a32",0.88),2.0,true)
		var spin := 0.0 if is_instance_valid(owner_fighter) and owner_fighter.reduced_motion else elapsed*5.0
		draw_set_transform(Vector2(0,-78),spin,Vector2.ONE*0.052)
		draw_texture(WORKSHOP_CHICKEN,-Vector2(WORKSHOP_CHICKEN.get_size())*0.5)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		return
	if kind == "rainbow_ruckus":
		var fade := 1.0-clampf(elapsed/0.48,0.0,1.0)*0.65
		var palette := [Color("ff4f68"),Color("ff9e31"),Color("ffdf45"),Color("56dc76"),Color("43c9f1"),Color("ab68ed")]
		var points := PackedVector2Array()
		var count := 18
		for i in range(count):
			var t := float(i)/float(count-1)
			var x := cast_direction*(38.0+306.0*t)
			var wobble := 0.0 if is_instance_valid(owner_fighter) and owner_fighter.reduced_motion else sin(elapsed*12.0+i*0.7)*5.0
			var y := -23.0-72.0*absf(sin(t*PI*2.3))+wobble
			points.append(Vector2(x,y))
		var under := points.duplicate()
		for i in under.size(): under[i] += Vector2(0,7)
		draw_polyline(under,Color("090d1c",fade),17.0,true)
		draw_polyline(points,Color("fff5d1",fade*0.92),8.0,true)
		for i in palette.size():
			var strand := points.duplicate()
			for point in strand.size(): strand[point] += Vector2(0,float(i-2)*2.0)
			draw_polyline(strand,Color(palette[i],fade*0.94),2.4,true)
		for i in range(5):
			var at := Vector2(cast_direction*(70.0+i*57.0),-68.0-(i%2)*31.0)
			draw_line(at+Vector2(-4,0),at+Vector2(4,0),Color("fff6ce",fade),2.0,true)
			draw_line(at+Vector2(0,-4),at+Vector2(0,4),Color("fff6ce",fade),2.0,true)
		var texture_angle := deg_to_rad(27.0)
		if cast_direction < 0: texture_angle = PI+texture_angle
		draw_set_transform(Vector2(cast_direction*7,-88),texture_angle,Vector2.ONE*0.042)
		draw_texture(WORKSHOP_CRAYON,-Vector2(WORKSHOP_CRAYON.get_size())*0.5)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		return
	if kind == "fossil_fetch":
		draw_circle(Vector2.ZERO,44.0,Color(tint,0.08))
		var spin := elapsed * 8.5 + (PI if velocity.x < 0.0 else 0.0)
		draw_polyline(PackedVector2Array([Vector2(-47,13),Vector2(-38,4),Vector2(-28,7)]),Color(tint,0.75),2.5,true)
		draw_set_transform(Vector2.ZERO,spin,Vector2.ONE * (0.043 * visual_scale))
		draw_texture(WORKSHOP_BONE,-Vector2(WORKSHOP_BONE.get_size()) * 0.5)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	elif kind == "swerve_shot":
		draw_circle(Vector2.ZERO,37.0,Color(tint,0.09))
		for i in range(3):
			var streak_y := -4.0 + i * 7.0
			draw_polyline(PackedVector2Array([Vector2(-37,streak_y+4),Vector2(-29-i*3,streak_y),Vector2(-22-i*2,streak_y+1)]),Color(tint,0.65-i*0.13),2.0,true)
		draw_set_transform(Vector2.ZERO,elapsed*1.6,Vector2.ONE * (0.027 * visual_scale))
		draw_texture(WORKSHOP_BALL,-Vector2(WORKSHOP_BALL.get_size()) * 0.5)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		if bounce_count > 0:
			draw_line(Vector2(-25,20),Vector2(-38,24),Color(tint,0.65),2.0,true)
