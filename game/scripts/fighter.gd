extends CharacterBody2D
## All authoritative movement, attack windows and damage use fixed physics ticks.
signal attacked(fighter, special)
signal released(fighter, special_kind)
signal damaged(fighter, amount, direction)
signal jumped(fighter)
signal landed(fighter, speed)
signal dodge_started(fighter)
signal perfect_dodged(fighter)
signal guarded(fighter, reflected)

const BODY_SCALE = 1.45
const SPEED = 310.0
const GRAVITY = 1550.0
const JUMP_SPEED = -770.0
const SPECIAL_COOLDOWN = 6.0
const DODGE_DURATION = 0.32
const DODGE_INVULNERABLE_START = 0.05
const DODGE_INVULNERABLE_END = 0.21
const DODGE_COOLDOWN = 1.15
const DODGE_SPEED = 430.0
const COUNTER_DURATION = 2.5
const COUNTER_DAMAGE_MULTIPLIER = 1.25
const BossStrength = preload("res://scripts/boss_strength.gd")
const CustomKits = preload("res://scripts/custom_kits.gd")
const SHIELD_REFLECT_START = 0.065
const SHIELD_REFLECT_END = 0.155
const PLAYABLE_IDS = ["orange", "red", "green", "blue", "purple", "yellow"]
var body_scale = BODY_SCALE
var definition: Dictionary
var weapon: Dictionary
var slot = 1
var max_health = 100
var health = 100
var guard_remaining = 0.0
var boss_guard = false
var boss_cast = ""
var boss_charge = 0.0
var facing = 1
var cooldown = 0.0
var hurt_time = 0.0
var invulnerable = 0.0
var attack_time = -1.0
var attack_spec: Dictionary = {}
var is_special = false
var attack_serial = 0
var hit_targets: Dictionary = {}
var emitted = false
var coyote = 0.0
var airborne_time = 0.0
var jump_buffer = 0.0
var victory = false
var result_defeated = false
var rig: Node2D
var temporary_art = true
var reduced_motion = false
var total_damage = 0
var visual_hold = 0.0
var held_art_position := Vector2.ZERO
var dodge_time = -1.0
var dodge_cooldown = 0.0
var dodge_direction = 1
var dodge_button_held = false
var dodge_perfected = false
var shield_reflected = false
var counter_time = 0.0
var last_hit_source = null
var last_hit_attack_serial: int = -1
var last_hit_special: bool = false
var last_hit_air_kind: String = ""
var thrown_weapon_hidden: bool = false
var active_custom_projectile_count: int = 0
var home_run_reflected: bool = false

func setup(id: String, player_slot: int, use_temporary_art: bool = false) -> void:
	definition = Data.fighter(id)
	max_health = int(definition.get("max_health",100))
	body_scale = BODY_SCALE * float(definition.get("size_multiplier",1.0))
	weapon = CustomKits.ground(str(definition.get("kit", "pixel_pick"))) if bool(definition.get("custom",false)) else Data.weapon(definition.weapon)
	if str(definition.get("basic_projectile", "")).is_empty():
		weapon.reach = float(weapon.reach) * body_scale
	slot = player_slot
	temporary_art = use_temporary_art
	collision_layer = 2
	collision_mask = 1
	var collider = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = float(definition.get("collision_radius",21)) * body_scale
	shape.height = float(definition.get("collision_height",110)) * body_scale
	collider.shape = shape
	collider.position.y = -shape.height/2
	add_child(collider)
	if not temporary_art:
		rig = load("res://scripts/fighter_rig.gd").new()
		add_child(rig)
		rig.configure(definition)
		rig.scale = Vector2.ONE * body_scale

func reset_at(spawn: Vector2) -> void:
	position = spawn
	velocity = Vector2.ZERO
	health = max_health
	guard_remaining = 0
	boss_guard = false
	boss_cast = ""
	boss_charge = 0
	cooldown = 0
	hurt_time = 0
	invulnerable = 0
	attack_time = -1
	attack_spec = {}
	hit_targets.clear()
	victory = false
	result_defeated = false
	coyote = 0
	airborne_time = 0
	jump_buffer = 0
	total_damage = 0
	visual_hold = 0
	dodge_time = -1
	dodge_cooldown = 0
	dodge_direction = 1
	dodge_button_held = false
	dodge_perfected = false
	shield_reflected = false
	counter_time = 0
	last_hit_source = null
	last_hit_attack_serial = -1
	last_hit_special = false
	last_hit_air_kind = ""
	thrown_weapon_hidden = false
	active_custom_projectile_count = 0
	home_run_reflected = false
	is_special = false
	emitted = false
	if rig: rig.position = Vector2.ZERO

func tick(delta: float, command: Dictionary, opponent: Node2D) -> void:
	guard_remaining = maxf(0,guard_remaining-delta)
	boss_guard = guard_remaining > 0
	var was_grounded = is_on_floor()
	cooldown = maxf(0, cooldown - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	counter_time = maxf(0, counter_time - delta)
	hurt_time = maxf(0, hurt_time - delta)
	invulnerable = maxf(0, invulnerable - delta)
	var dodge_pressed: bool = bool(command.get("dodge", false))
	var dodge_edge: bool = dodge_pressed and not dodge_button_held
	dodge_button_held = dodge_pressed
	if is_on_floor():
		coyote = 0.12
	else:
		coyote = maxf(0, coyote - delta)
	jump_buffer = maxf(0, jump_buffer - delta)
	if command.get("jump", false):
		jump_buffer = 0.14
	if dodge_edge:
		start_dodge(float(command.get("move", 0.0)), opponent)
	if health > 0 and hurt_time <= 0 and dodge_time < 0:
		if attack_time < 0:
			if opponent and not command.get("lock_facing",false) and absf(opponent.position.x - position.x) > 8:
				facing = 1 if opponent.position.x > position.x else -1
			if command.get("special", false) and cooldown <= 0:
				start_attack(true)
			elif command.get("attack", false):
				start_attack(false)
		if jump_buffer > 0 and coyote > 0 and (attack_time < 0 or not is_special):
			velocity.y = JUMP_SPEED
			coyote = 0
			jump_buffer = 0
			jumped.emit(self)
		var move = float(command.get("move", 0.0))
		var movement_scale = 0.5 if attack_time >= 0 else 1.0
		velocity.x = move_toward(velocity.x, move * SPEED * float(definition.get("move_multiplier",1.0)) * movement_scale, 2200 * delta)
	else:
		if dodge_time >= 0:
			# A sidestep commits its direction through its vulnerable recovery.
			velocity.x = dodge_direction * DODGE_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 550 * delta)
	if dodge_time >= 0:
		dodge_time += delta
		if dodge_time >= DODGE_DURATION:
			dodge_time = -1
	if attack_time >= 0:
		attack_time += delta
		if attack_time >= float(attack_spec.windup) and not emitted:
			emitted = true
			if is_special:
				released.emit(self, definition.special)
			elif not str(definition.get("basic_projectile", "")).is_empty():
				released.emit(self, str(definition.basic_projectile))
		if is_active() and is_special and definition.special == "dash":
			velocity.x = facing * float(definition.get("dash_speed",760.0))
		elif is_active() and not is_special:
			match str(attack_spec.get("air_kind", "")):
				"hammer_drop": velocity.y = maxf(velocity.y, 420.0)
				"pick_drop": velocity.y = maxf(velocity.y, 320.0)
				"diagonal_slash": velocity.x = facing * 420.0
				"staff_drop": velocity.y = maxf(velocity.y, 300.0)
		if attack_time >= duration():
			attack_time = -1
	velocity.y += GRAVITY * delta
	var fall_speed = velocity.y
	move_and_slide()
	airborne_time = 0.0 if is_on_floor() else airborne_time + delta
	if not was_grounded and is_on_floor() and fall_speed > 180:
		landed.emit(self,fall_speed)
	position.x = clampf(position.x, 78, 1202)
	if position.y > 680: # Defensive recovery; arena itself has no pits.
		position.y = 599
		velocity = Vector2.ZERO
	update_art(delta)

func begin_impact_hold(seconds: float = 0.055) -> void:
	# Freeze presentation at the contact point, not authoritative combat clocks.
	if reduced_motion or not is_instance_valid(rig): return
	if visual_hold <= 0: held_art_position = rig.global_position
	visual_hold = maxf(visual_hold,seconds)

func update_art(delta: float) -> void:
	# Brief pose hold adds impact without delaying physics, damage, or the round clock.
	if visual_hold > 0:
		visual_hold = maxf(0,visual_hold-delta)
		if rig: rig.global_position = held_art_position
		return
	if rig:
		rig.position = Vector2.ZERO
		rig.pose(delta, {"velocity":velocity if not victory and not result_defeated and health>0 else Vector2.ZERO, "grounded":is_on_floor() or victory or result_defeated or health<=0, "facing":facing,
			"attack_progress":attack_time / duration() if attack_time >= 0 else -1.0,
			"attack_windup_ratio":float(attack_spec.get("windup",0.1))/duration(),
			"attack_active_ratio":float(attack_spec.get("active",0.1))/duration(),
			"special":is_special, "hurt":hurt_time > 0, "defeated":health <= 0 or result_defeated,
			"dodging":dodge_time >= 0, "dodge_progress":dodge_time / DODGE_DURATION if dodge_time >= 0 else -1.0,
			"dodge_invulnerable":dodge_invulnerable(), "counter_ready":counter_time > 0,
			"shield_guard":shield_guard_active(), "shield_perfect":shield_reflect_window() and not shield_reflected,
			"shield_progress":dodge_time / DODGE_DURATION if dodge_time >= 0 else -1.0,
			"counter_attack":attack_time >= 0 and bool(attack_spec.get("counter",false)),
			"air_basic_kind":str(attack_spec.get("air_kind", "")) if attack_time >= 0 else "",
			"weapon_hidden":thrown_weapon_hidden, "custom_kit":str(definition.get("kit", "")),
			"boss_guard":boss_guard,"boss_cast":boss_cast,"boss_charge":boss_charge,"boss_enraged":health<max_health/2.0,
			"victory":victory, "invulnerable":invulnerable > 0, "reduced_motion":reduced_motion})
	queue_redraw()

func duration() -> float:
	return float(attack_spec.get("windup",0.1)) + float(attack_spec.get("active",0.1)) + float(attack_spec.get("recovery",0.3))

func start_attack(special: bool) -> bool:
	if health <= 0 or hurt_time > 0 or attack_time >= 0 or dodge_time >= 0 or (special and cooldown > 0):
		return false
	# A thrown bone cannot also land invisible melee hits before returning.
	if thrown_weapon_hidden:
		return false
	is_special = special
	attack_spec = weapon.duplicate(true)
	if special:
		cooldown = SPECIAL_COOLDOWN
		if bool(definition.get("custom",false)):
			attack_spec.merge(CustomKits.special(str(definition.get("kit", "pixel_pick"))),true)
			attack_spec.reach = float(attack_spec.reach) * body_scale
		else:
			attack_spec.merge({"damage":22, "windup":0.18,"active":0.30,"recovery":0.38,"reach":155 * body_scale,"knockback":480}, true)
			if definition.special == "shockwave":
				attack_spec.windup = 0.30
			if definition.special == "dash":
				attack_spec.active = 0.24
			if definition.special in ["signal", "swarm"]:
				attack_spec.windup = 0.28
				attack_spec.damage = 24 if definition.special == "signal" else 22
		attack_spec.damage = int(definition.get("special_damage",attack_spec.damage))
	else:
		if airborne_time > 0 and is_playable():
			configure_air_basic()
		if counter_time > 0:
			attack_spec.damage = ceili(float(attack_spec.damage) * COUNTER_DAMAGE_MULTIPLIER)
			attack_spec.counter = true
			counter_time = 0
	# Keep the outgoing payload authoritative for melee and any derived shot.
	# Projectile scripts with their own base values apply this rule separately.
	attack_spec.damage = BossStrength.damage(str(definition.id), int(attack_spec.damage))
	if not special:
		if str(definition.get("basic_projectile", "")) != "":
			attack_spec.projectile_damage = int(attack_spec.damage)
	attack_time = 0
	attack_serial += 1
	home_run_reflected = false
	hit_targets.clear()
	emitted = false
	attacked.emit(self, special)
	return true

func start_dodge(move_input: float = 0.0, opponent: Node2D = null) -> bool:
	if health <= 0 or victory or hurt_time > 0 or attack_time >= 0 or dodge_time >= 0 or dodge_cooldown > 0:
		return false
	if not is_playable():
		return false
	if absf(move_input) > 0.15:
		dodge_direction = 1 if move_input > 0 else -1
	elif opponent and absf(opponent.position.x - position.x) > 8.0:
		dodge_direction = -1 if opponent.position.x > position.x else 1
	else:
		dodge_direction = -facing
	dodge_time = 0
	dodge_cooldown = DODGE_COOLDOWN
	dodge_perfected = false
	shield_reflected = false
	jump_buffer = 0
	dodge_started.emit(self)
	return true

func dodge_invulnerable() -> bool:
	return dodge_time >= DODGE_INVULNERABLE_START and dodge_time < DODGE_INVULNERABLE_END

func shield_guard_active() -> bool:
	return str(definition.get("id", "")) == "purple" and dodge_invulnerable()

func shield_reflect_window() -> bool:
	return shield_guard_active() and dodge_time >= SHIELD_REFLECT_START and dodge_time < SHIELD_REFLECT_END

func is_playable() -> bool:
	return bool(definition.get("custom",false)) or str(definition.get("id", "")) in PLAYABLE_IDS

func home_run_reflect_window() -> bool:
	return is_special and str(definition.get("special", "")) == "home_run" and is_active() and not home_run_reflected

func configure_air_basic() -> void:
	# All shapes and timings are authoritative attack data; the rig reads air_kind.
	if bool(definition.get("custom",false)):
		var air = CustomKits.air(str(definition.get("kit", "pixel_pick")))
		air.reach = float(air.reach) * body_scale
		attack_spec.merge(air,true)
		return
	match str(definition.id):
		"orange":
			attack_spec.merge({"air_kind":"fork_sweep", "damage":10, "reach":125.0 * body_scale,
				"windup":0.12, "active":0.19, "recovery":0.39, "hitbox_top":93.0,
				"hitbox_height":105.0, "hitbox_both_sides":true},true)
		"red":
			attack_spec.merge({"air_kind":"hammer_drop", "damage":22, "reach":104.0 * body_scale,
				"windup":0.20, "active":0.17, "recovery":0.54, "knockback":525.0,
				"launch_y":240.0, "hitbox_top":72.0, "hitbox_height":111.0},true)
		"green":
			attack_spec.merge({"air_kind":"diagonal_slash", "damage":11, "reach":126.0 * body_scale,
				"windup":0.11, "active":0.13, "recovery":0.34, "hitbox_top":111.0,
				"hitbox_height":146.0},true)
		"blue":
			attack_spec.merge({"air_kind":"pick_uppercut", "damage":15, "reach":99.0 * body_scale,
				"windup":0.13, "active":0.16, "recovery":0.39, "knockback":400.0,
				"launch_y":-390.0, "hitbox_top":159.0, "hitbox_height":116.0},true)
		"purple":
			attack_spec.merge({"air_kind":"aimed_arrow", "damage":12,
				"windup":0.14, "active":0.10, "recovery":0.43},true)
		"yellow":
			attack_spec.merge({"air_kind":"staff_drop", "damage":13, "reach":99.0 * body_scale,
				"windup":0.11, "active":0.15, "recovery":0.38, "knockback":365.0,
				"launch_y":140.0, "hitbox_top":55.0, "hitbox_height":105.0},true)

func is_active() -> bool:
	return attack_time >= float(attack_spec.get("windup",99)) and attack_time < float(attack_spec.get("windup",99)) + float(attack_spec.get("active",0))

func visual_head_height() -> float:
	return (166.0 if definition.head == "crown" else 152.0 if definition.head == "monitor" else 140.0)*body_scale

func hurtbox() -> Rect2:
	var width = float(definition.get("hurtbox_width",46))
	return Rect2(position + Vector2(-width/2,-float(definition.get("hurtbox_top",116))) * body_scale, Vector2(width,float(definition.get("hurtbox_height",113))) * body_scale)

func hitbox() -> Rect2:
	if not is_active():
		return Rect2()
	if is_special and definition.special in ["shockwave", "fragment", "signal", "swarm", "ore_pop", "fossil_fetch", "swerve_shot", "cluckquake", "rainbow_ruckus"]:
		return Rect2() # Their separate moving hitboxes are created at release.
	if not is_special and not str(definition.get("basic_projectile", "")).is_empty():
		return Rect2() # A bow release creates an arrow, never an extra melee hit.
	var reach = float(attack_spec.reach)
	if is_special and definition.special == "spin":
		return Rect2(position + Vector2(-reach,-125 * body_scale), Vector2(reach * 2,125 * body_scale))
	var top: float = float(attack_spec.get("hitbox_top",104.0)) * body_scale
	var height: float = float(attack_spec.get("hitbox_height",90.0)) * body_scale
	if bool(attack_spec.get("hitbox_both_sides",false)):
		return Rect2(position + Vector2(-reach,-top),Vector2(reach*2.0,height))
	return Rect2(position + Vector2(0 if facing == 1 else -reach, -top), Vector2(reach,height))

func try_hit(target) -> bool:
	if not is_active() or hit_targets.has(target.get_instance_id()):
		return false
	if hitbox().has_area() and hitbox().intersects(target.hurtbox()):
		hit_targets[target.get_instance_id()] = true
		var direction = 1 if target.position.x >= position.x else -1
		var hit = target.take_hit(int(attack_spec.damage), direction, float(attack_spec.knockback), float(attack_spec.get("launch_y",-245.0)), self)
		if hit:
			total_damage += int(attack_spec.damage)
		return hit
	return false

func take_hit(amount: int, direction: int, force: float = 350, launch_y: float = -245.0, source = null) -> bool:
	if health <= 0 or invulnerable > 0:
		return false
	# The bat's announced active frames can return one physical incoming shot.
	# Projectile.reflect_from owns the one-reflection limit and changes ownership.
	if home_run_reflect_window() and direction == -facing and source != null and source.has_method("reflect_from") and source.reflect_from(self):
		home_run_reflected = true
		guarded.emit(self,true)
		return false
	if dodge_invulnerable():
		# Purple's dodge is a short, directional shield. A shot caught on its early
		# face reverses once; an ordinary melee hit or late shot is simply guarded.
		# Back attacks remain dangerous even while the shield is visible.
		if str(definition.get("id", "")) != "purple" or direction == -facing:
			var reflected = false
			if shield_reflect_window() and not shield_reflected and source != null and source.has_method("reflect_from"):
				reflected = source.reflect_from(self)
				shield_reflected = reflected
			if not dodge_perfected and amount > 0:
				dodge_perfected = true
				counter_time = COUNTER_DURATION
				perfect_dodged.emit(self)
			if shield_guard_active():
				guarded.emit(self, reflected)
			return false
	health = maxi(0, health - amount)
	counter_time = 0
	# Committed boss windups take full damage, but cannot be erased by holding attack.
	# The short guard expires before recovery; ordinary fighters retain their escape window.
	invulnerable = 0.68
	if guard_remaining <= 0 or health <= 0:
		hurt_time = 0.18
		attack_time = -1
		dodge_time = -1
		jump_buffer = 0
		velocity = Vector2(direction * force, launch_y)
		guard_remaining = 0
		boss_guard = false
	last_hit_source = source
	last_hit_attack_serial = -1
	last_hit_special = false
	last_hit_air_kind = ""
	if source != null:
		last_hit_attack_serial = int(source.attack_serial)
		if source.has_method("start_attack"):
			last_hit_special = bool(source.is_special)
			last_hit_air_kind = str(source.attack_spec.get("air_kind", ""))
		else:
			last_hit_special = bool(source.attack_special)
			last_hit_air_kind = str(source.attack_air_kind)
	damaged.emit(self, amount, direction)
	return true

func _draw() -> void:
	if not temporary_art:
		return
	var c = Color(definition.get("color", "f59736"))
	draw_arc(Vector2(0,-101),20,0,TAU,24,c,6,true)
	draw_line(Vector2(0,-78),Vector2(0,-35),c,6,true)
	draw_line(Vector2(0,-65),Vector2(36*facing,-60),c,6,true)
	draw_line(Vector2(0,-35),Vector2(-20,0),c,6,true)
	draw_line(Vector2(0,-35),Vector2(20,0),c,6,true)
	if is_active():
		draw_rect(Rect2(Vector2(0 if facing == 1 else -138,-100),Vector2(138,90)),Color(c,0.3))
