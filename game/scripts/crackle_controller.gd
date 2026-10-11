extends RefCounted
## Committed fireworks and a spear thrust with a clear punish window.
const Difficulty = preload("res://scripts/difficulty.gd")
const BossProjectile = preload("res://scripts/boss_projectile.gd")
signal pattern_released(kind: String, angle: float)

const PATTERNS := ["rocket_single", "firecracker_arc", "firework_fan", "spear_thrust"]
const TELLS := ["ROCKET!", "FIRECRACKER! POP!", "FIREWORK FAN!", "SPEAR THRUST!"]
const TELL_DURATION := [0.78, 0.88, 0.86, 0.62]
const RELEASE_DURATION := 0.13
const RECOVERY_DURATION := 0.68

var state := "rest"
var time_left := 0.38
var pattern := 0
var tell := ""
var committed_facing := -1
var committed_angle := 0.0
var approach_speed := 1.05
var difficulty_level: int = Difficulty.EASY
var jump_wait := 0.0

func configure_difficulty(selected_level: int) -> void:
	var old_factor: float = Difficulty.rest_factor(difficulty_level)
	difficulty_level = Difficulty.normalized_level(selected_level)
	approach_speed = 1.05 * Difficulty.move_factor(difficulty_level)
	if state == "rest": time_left *= Difficulty.rest_factor(difficulty_level) / old_factor

func reset() -> void:
	state = "rest"
	time_left = 0.38 * Difficulty.rest_factor(difficulty_level)
	pattern = 0
	tell = ""
	committed_facing = -1
	committed_angle = 0.0
	jump_wait = 0.0

func _visual_tell(fighter, message: String, progress: float = 0.0) -> void:
	if is_instance_valid(fighter.rig) and fighter.rig.has_method("set_opponent_tell"):
		fighter.rig.set_opponent_tell(message, progress)

func _clear_cast(fighter) -> void:
	tell = ""
	fighter.boss_cast = ""
	fighter.boss_charge = 0.0
	fighter.guard_remaining = 0.0
	fighter.boss_guard = false
	_visual_tell(fighter, "")

func _begin_tell(fighter, opponent, dx: float) -> void:
	state = "tell"
	time_left = float(TELL_DURATION[pattern])
	committed_facing = 1 if dx >= 0.0 else -1
	fighter.facing = committed_facing
	var muzzle: Vector2 = BossProjectile.muzzle_position(fighter, committed_facing, "cast_impact")
	var target: Vector2 = opponent.hurtbox().get_center()
	committed_angle = clampf(atan2(target.y - muzzle.y, maxf(125.0, absf(target.x - muzzle.x))), -0.65, 0.46)
	tell = TELLS[pattern]
	fighter.boss_cast = PATTERNS[pattern]
	fighter.boss_charge = 0.0
	var active_window: float = float(fighter.weapon.windup) + float(fighter.weapon.active) + 0.06 if pattern == 3 else 0.04
	fighter.guard_remaining = time_left + active_window
	fighter.boss_guard = true
	_visual_tell(fighter, tell)

func _begin_released(fighter) -> void:
	state = "released"
	time_left = RELEASE_DURATION
	tell = ""
	fighter.boss_charge = 1.0
	fighter.guard_remaining = 0.0
	fighter.boss_guard = false
	_visual_tell(fighter, "")

func _begin_recovery(fighter) -> void:
	state = "recovery"
	time_left = RECOVERY_DURATION
	pattern = (pattern + 1) % PATTERNS.size()
	tell = ""
	fighter.boss_cast = "reload"
	fighter.boss_charge = 0.0
	fighter.guard_remaining = 0.0
	fighter.boss_guard = false
	_visual_tell(fighter, "")

func read_input(delta: float, fighter, opponent) -> Dictionary:
	var command := {"move":0.0, "jump":false, "attack":false, "special":false, "lock_facing":false}
	if fighter.health <= 0 or opponent.health <= 0:
		_clear_cast(fighter)
		return command
	if fighter.hurt_time > 0.0:
		if state != "rest":
			_clear_cast(fighter)
			state = "rest"
			time_left = RECOVERY_DURATION
		return command
	jump_wait = maxf(0.0, jump_wait - delta)
	time_left -= delta
	var dx: float = opponent.position.x - fighter.position.x
	var dy: float = opponent.position.y - fighter.position.y
	match state:
		"rest":
			if time_left <= 0.0 and fighter.attack_time < 0.0:
				state = "approach"
				time_left = 1.30
		"approach":
			var reach: float = minf(float(fighter.weapon.reach) * 0.92, 155.0) if pattern == 3 else 390.0 if pattern == 1 else 485.0
			if absf(dx) > reach and time_left > 0.0:
				command.move = signf(dx) * approach_speed
				if dy < -90.0 and absf(dx) < 325.0 and jump_wait <= 0.0 and fighter.is_on_floor():
					command.jump = true
					jump_wait = 1.3
			else:
				_begin_tell(fighter, opponent, dx)
		"tell":
			command.lock_facing = true
			fighter.facing = committed_facing
			fighter.boss_charge = clampf(1.0 - time_left / float(TELL_DURATION[pattern]), 0.0, 1.0)
			_visual_tell(fighter, tell, fighter.boss_charge)
			if time_left <= 0.0:
				if pattern == 3:
					command.attack = true
					state = "executing"
					time_left = 0.12
					tell = ""
					_visual_tell(fighter, "")
				else:
					pattern_released.emit(PATTERNS[pattern], committed_angle)
					_begin_released(fighter)
		"released":
			command.lock_facing = true
			fighter.facing = committed_facing
			if time_left <= 0.0: _begin_recovery(fighter)
		"executing":
			command.lock_facing = true
			fighter.facing = committed_facing
			if fighter.attack_time >= 0.0 and fighter.attack_time >= float(fighter.attack_spec.get("windup", 0.0)) + float(fighter.attack_spec.get("active", 0.0)):
				fighter.guard_remaining = 0.0
				fighter.boss_guard = false
			if time_left <= 0.0 and fighter.attack_time < 0.0: _begin_recovery(fighter)
		"recovery":
			command.lock_facing = true
			fighter.facing = committed_facing
			if time_left <= 0.0:
				_clear_cast(fighter)
				state = "rest"
				time_left = 0.22 * Difficulty.rest_factor(difficulty_level)
	return command
