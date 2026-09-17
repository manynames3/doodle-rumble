extends RefCounted
## Journey difficulty changes decisions and pace; all attacks retain visible tells.
const Difficulty = preload("res://scripts/difficulty.gd")
const PROFILES := [
	{"speed":0.46,"retreat":0.28,"think_min":0.38,"think_max":0.60,"approach":0.65,"special":0.06,"tell":0.65,"rest_min":1.5,"rest_max":2.05,"jump_wait":2.8,"guard_stride":6,"guard_reaction":0.19,"guard_cooldown":5.5},
	{"speed":0.62,"retreat":0.40,"think_min":0.22,"think_max":0.42,"approach":0.78,"special":0.16,"tell":0.50,"rest_min":1.3,"rest_max":1.7,"jump_wait":2.3,"guard_stride":4,"guard_reaction":0.15,"guard_cooldown":4.5},
	{"speed":0.80,"retreat":0.50,"think_min":0.12,"think_max":0.22,"approach":0.94,"special":0.35,"tell":0.48,"rest_min":1.1,"rest_max":1.4,"jump_wait":1.4,"guard_stride":3,"guard_reaction":0.11,"guard_cooldown":3.5}
]
var level: int = 1
var profile: Dictionary = PROFILES[1]
var difficulty_level: int = Difficulty.EASY
var think_time = 0.0
var rest_time = 1.4
var tell_time = 0.0
var move_choice = 0.0
var jump_wait = 0.0
var waiting_for_attack: bool = false
var guard_cooldown: float = 0.0
var guard_pending: bool = false
var guard_reaction: float = 0.0
var guard_pending_projectile: bool = false
var guard_seen_serial: int = -1
var guard_threat_count: int = 0
var rng = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func configure(difficulty: int = 1) -> void:
	level = clampi(difficulty,0,PROFILES.size()-1)
	_apply_difficulty()

func configure_difficulty(selected_level: int) -> void:
	var previous_factor: float = Difficulty.rest_factor(difficulty_level)
	difficulty_level = Difficulty.normalized_level(selected_level)
	_apply_difficulty()
	if not waiting_for_attack:
		rest_time *= Difficulty.rest_factor(difficulty_level) / previous_factor

func _apply_difficulty() -> void:
	# Duplicate before tuning so a Hard match cannot mutate a chapter's Easy
	# baseline or flatten the increasing Blue-to-Green chapter profiles.
	profile = PROFILES[level].duplicate()
	for key in ["think_min", "think_max"]:
		profile[key] = float(profile[key]) * Difficulty.think_factor(difficulty_level)
	for key in ["rest_min", "rest_max"]:
		profile[key] = float(profile[key]) * Difficulty.rest_factor(difficulty_level)
	profile.speed = float(profile.speed) * Difficulty.move_factor(difficulty_level)
	profile.approach = minf(1.0, float(profile.approach) * Difficulty.move_factor(difficulty_level))

func reset() -> void:
	rest_time = float(profile.rest_max)
	tell_time = 0
	think_time = 0
	move_choice = 0
	jump_wait = 0
	waiting_for_attack = false
	guard_cooldown = 0.0
	guard_pending = false
	guard_reaction = 0.0
	guard_pending_projectile = false
	guard_seen_serial = -1
	guard_threat_count = 0

func read_input(delta: float, fighter, opponent) -> Dictionary:
	var command = {"move":0.0,"jump":false,"attack":false,"special":false,"dodge":false}
	guard_cooldown = maxf(0.0,guard_cooldown-delta)
	if _purple_guard_read(delta,fighter,opponent,command):
		return command
	# Recovery starts after the swing, so faster profiles mean actual pressure.
	if waiting_for_attack and fighter.attack_time >= 0 and fighter.hurt_time <= 0:
		return command
	waiting_for_attack = false
	jump_wait = maxf(0,jump_wait-delta)
	rest_time = maxf(0,rest_time-delta)
	var dx = opponent.position.x - fighter.position.x
	var dy = opponent.position.y - fighter.position.y
	if fighter.hurt_time > 0:
		# A hit interrupts the tell; recovery protection in Fighter remains authoritative.
		tell_time = 0
		move_choice = 0
		rest_time = maxf(rest_time,0.4)
		return command
	if tell_time > 0:
		tell_time -= delta
		if tell_time <= 0:
			command.special = fighter.cooldown <= 0 and rng.randf() < float(profile.special)
			command.attack = not command.special
			rest_time = rng.randf_range(float(profile.rest_min),float(profile.rest_max))
			waiting_for_attack = true
		return command
	think_time -= delta
	if think_time <= 0:
		think_time = rng.randf_range(float(profile.think_min),float(profile.think_max))
		move_choice = 0
		if absf(dx) > float(fighter.weapon.reach) - 12 and rng.randf() < float(profile.approach):
			move_choice = signf(dx) * float(profile.speed)
		elif absf(dx) < 55 and rest_time > 0.5:
			move_choice = -signf(dx) * float(profile.retreat)
	command.move = move_choice
	if dy < -70 and absf(dx) < 370 and jump_wait <= 0 and fighter.is_on_floor():
		command.jump = true
		jump_wait = float(profile.jump_wait)
	if absf(dx) < float(fighter.weapon.reach) + 16 and absf(dy) < 92 and rest_time <= 0 and fighter.attack_time < 0 and fighter.hurt_time <= 0:
		tell_time = float(profile.tell)
		command.move = 0
	return command

func _purple_guard_read(delta: float, fighter, opponent, command: Dictionary) -> bool:
	if str(fighter.definition.get("id","")) != "purple": return false
	if fighter.health <= 0 or fighter.hurt_time > 0 or fighter.attack_time >= 0 or fighter.dodge_time >= 0:
		guard_pending = false
		return false
	if guard_pending:
		# A selected response commits to watching the announced attack rather
		# than slipping a free shield into the AI's own attack animation.
		guard_reaction -= delta
		if not guard_pending_projectile and opponent.attack_time < 0:
			guard_pending = false
			return false
		if guard_reaction <= 0:
			guard_pending = false
			guard_cooldown = float(profile.guard_cooldown)
			command.dodge = true
			# The shield must actually meet a traveling shot; melee reads retreat.
			command.move = signf(opponent.position.x-fighter.position.x) if guard_pending_projectile else -signf(opponent.position.x-fighter.position.x)
		return true
	if guard_cooldown > 0 or fighter.dodge_cooldown > 0 or opponent.attack_time < 0:
		return false
	if opponent.attack_serial == guard_seen_serial:
		return false
	guard_seen_serial = opponent.attack_serial
	var dx: float = opponent.position.x-fighter.position.x
	if absf(dx) < 12.0 or opponent.facing != -signf(dx) or fighter.facing != signf(dx):
		return false
	var kind: String = str(opponent.definition.get("basic_projectile", "")) if not opponent.is_special else str(opponent.definition.get("special", ""))
	var projectile: bool = kind in ["arrow","signal","swarm","fragment","shockwave"]
	var reach: float = 600.0 if projectile else float(opponent.attack_spec.get("reach",0.0))+75.0
	if absf(dx) > reach:
		return false
	guard_threat_count += 1
	if guard_threat_count % int(profile.guard_stride) != 0:
		return false
	guard_pending = true
	guard_pending_projectile = projectile
	guard_reaction = float(profile.guard_reaction)
	if projectile:
		var shot_speed: float = {"arrow":640.0,"signal":760.0,"swarm":360.0,"fragment":530.0,"shockwave":520.0}.get(kind,500.0)
		var until_release: float = maxf(0.0,float(opponent.attack_spec.get("windup",0.0))-opponent.attack_time)
		guard_reaction = maxf(guard_reaction,until_release+maxf(0.0,absf(dx)-100.0)/shot_speed-0.20)
	else:
		guard_reaction = maxf(guard_reaction,float(opponent.attack_spec.get("windup",0.0))-opponent.attack_time-0.13)
	return true
