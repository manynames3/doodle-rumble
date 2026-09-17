extends RefCounted
## Seven committed sketches: weapon, packet, three floor marks, a fan and a firewall.
## Each has a fixed-facing screen tell; recovery begins after its actual release.
const Difficulty = preload("res://scripts/difficulty.gd")
signal pattern_released(kind: String)

const PATTERNS := ["cursor_strike", "packet_blast", "cursor_stamp", "ink_geyser", "eraser_drop", "checksum_volley", "firewall_scan"]
const TELLS := ["CURSOR STRIKE!", "PACKET BLAST!", "SIDESTEP!", "INK INCOMING!", "ERASER DROP!", "CHECKSUM VOLLEY!", "FIREWALL! MOVE!"]
const REACH := [0.82, 460.0, 460.0, 460.0, 460.0, 520.0, 540.0]
const CURSOR_LUNGE_SPEED := 900.0
const CURSOR_LUNGE_MOVE := 5.8 # Fighter applies half of its 310 speed during attacks.

var state: String = "rest"
var time_left: float = 0.52
var pattern: int = 0
var tell: String = ""
var committed_facing: int = -1
var approach_speed: float = 1.07
var tell_duration: float = 0.78
var recovery_duration: float = 0.46
var execution_duration: float = 0.62
var difficulty_level: int = Difficulty.EASY
var jump_wait: float = 0.0
var lunge_origin_x: float = 0.0
var lunge_distance: float = 0.0

func configure_difficulty(selected_level: int) -> void:
	var previous_factor: float = Difficulty.rest_factor(difficulty_level)
	difficulty_level = Difficulty.normalized_level(selected_level)
	approach_speed = 1.07 * Difficulty.move_factor(difficulty_level)
	recovery_duration = 0.46 * Difficulty.rest_factor(difficulty_level)
	execution_duration = 0.62 * Difficulty.rest_factor(difficulty_level)
	if state == "rest": time_left *= Difficulty.rest_factor(difficulty_level) / previous_factor
	# Difficulty changes the time between decisions, never the 0.78-second tell.
	tell_duration = 0.78

func reset() -> void:
	state = "rest"
	time_left = 0.52 * Difficulty.rest_factor(difficulty_level)
	pattern = 0
	tell = ""
	jump_wait = 0.0
	lunge_distance = 0.0

func _visual_tell(fighter, message: String, progress: float = 0.0) -> void:
	if is_instance_valid(fighter.rig) and fighter.rig.has_method("set_opponent_tell"):
		fighter.rig.set_opponent_tell(message, progress)

func _clear_cast(fighter) -> void:
	tell = ""
	fighter.boss_cast = ""
	fighter.boss_charge = 0.0
	fighter.guard_remaining = 0.0
	fighter.boss_guard = false
	lunge_distance = 0.0
	_visual_tell(fighter, "")

func _begin_tell(fighter, dx: float) -> void:
	state = "tell"
	time_left = tell_duration
	committed_facing = 1 if dx >= 0.0 else -1
	tell = TELLS[pattern]
	fighter.facing = committed_facing
	fighter.boss_cast = PATTERNS[pattern]
	fighter.boss_charge = 0.0
	# The boss can finish a signaled move, but is open again after its active part.
	fighter.guard_remaining = tell_duration + (0.40 if pattern < 2 else 0.18)
	fighter.boss_guard = true
	_visual_tell(fighter, tell)

func _finish_pattern(fighter) -> void:
	_clear_cast(fighter)
	pattern = (pattern + 1) % PATTERNS.size()
	state = "rest"
	time_left = recovery_duration

func read_input(delta: float, fighter, opponent) -> Dictionary:
	var command := {"move":0.0, "jump":false, "attack":false, "special":false, "lock_facing":false}
	if fighter.health <= 0 or opponent.health <= 0:
		_clear_cast(fighter)
		return command
	if fighter.hurt_time > 0.0:
		if state != "rest":
			_clear_cast(fighter)
			state = "rest"
			time_left = recovery_duration
		return command
	jump_wait = maxf(0.0, jump_wait - delta)
	time_left -= delta
	var dx: float = opponent.position.x - fighter.position.x
	var dy: float = opponent.position.y - fighter.position.y
	match state:
		"rest":
			if time_left <= 0.0 and fighter.attack_time < 0.0:
				state = "approach"
				time_left = 1.25
		"approach":
			var reach: float = float(fighter.weapon.reach) * float(REACH[0]) if pattern == 0 else float(REACH[pattern])
			if absf(dx) > reach and time_left > 0.0:
				command.move = signf(dx) * approach_speed
				if dy < -70.0 and absf(dx) < 440.0 and jump_wait <= 0.0 and fighter.is_on_floor():
					command.jump = true
					jump_wait = 1.25
			else:
				_begin_tell(fighter, dx)
		"tell":
			command.lock_facing = true
			fighter.facing = committed_facing
			fighter.boss_charge = clampf(1.0 - time_left / tell_duration, 0.0, 1.0)
			_visual_tell(fighter, tell, fighter.boss_charge)
			if time_left <= 0.0:
				match PATTERNS[pattern]:
					"cursor_strike":
						command.attack = true
						# If the player fled during the announced direction, the
						# cursor carries the same strike forward. It never turns or homes.
						if absf(dx) >= 220.0:
							lunge_origin_x = fighter.position.x
							lunge_distance = minf(300.0, absf(dx) - 80.0)
							fighter.velocity.x = float(committed_facing) * CURSOR_LUNGE_SPEED
							command.move = float(committed_facing) * CURSOR_LUNGE_MOVE
					"packet_blast":
						command.special = true
						fighter.cooldown = 0.0
					_:
						pattern_released.emit(PATTERNS[pattern])
				state = "executing"
				time_left = 0.05 if pattern < 2 else execution_duration
				tell = ""
				_visual_tell(fighter, "")
		"executing":
			command.lock_facing = true
			fighter.facing = committed_facing
			if pattern == 0 and lunge_distance > 0.0 and fighter.attack_time >= 0.0:
				var active_end: float = float(fighter.attack_spec.get("windup", 0.0)) + float(fighter.attack_spec.get("active", 0.0))
				if fighter.attack_time < active_end and absf(fighter.position.x - lunge_origin_x) < lunge_distance:
					command.move = float(committed_facing) * CURSOR_LUNGE_MOVE
			if pattern < 2 and fighter.attack_time >= 0.0 and fighter.attack_time >= float(fighter.attack_spec.get("windup", 0.0)) + float(fighter.attack_spec.get("active", 0.0)):
				fighter.guard_remaining = 0.0
				fighter.boss_guard = false
			if time_left <= 0.0 and fighter.attack_time < 0.0:
				_finish_pattern(fighter)
	return command
