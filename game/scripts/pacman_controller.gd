extends RefCounted
## Pac-Man commits to a visible direction, attacks, then gives the player recovery time.
const Difficulty = preload("res://scripts/difficulty.gd")
signal pattern_released(kind: String)

const PATTERNS = ["bite", "dash", "pellet_fan", "leap_chomp"]
const TELL_SECONDS = {"bite":0.35, "dash":0.70, "pellet_fan":0.68, "leap_chomp":0.58}
const TELLS = {"bite":"BITE!", "dash":"CHARGE!", "pellet_fan":"PELLET SPIT!", "leap_chomp":"HOP CHOMP!"}
const APPROACH_REACH = {"bite":128.0, "dash":285.0, "pellet_fan":465.0, "leap_chomp":260.0}
const APPROACH_SPEED = 1.12

var state: String = "rest"
var time_left: float = 0.38
var tell: String = ""
var next_dash: bool = false
var queued_dash: bool = false
var jump_wait: float = 0.0
var attack_serial_at_release: int = -1
var pattern_index: int = 0
var current_pattern: String = "bite"
var committed_facing: int = 1
var committed_distance: float = 0.0
var approach_elapsed: float = 0.0
var leap_start_x: float = 0.0
var leap_travel: float = 0.0
var difficulty_level: int = Difficulty.EASY
var approach_speed: float = APPROACH_SPEED

func configure_difficulty(selected_level: int) -> void:
	var previous_factor: float = Difficulty.rest_factor(difficulty_level)
	difficulty_level = Difficulty.normalized_level(selected_level)
	approach_speed = APPROACH_SPEED * Difficulty.move_factor(difficulty_level)
	if state == "rest": time_left *= Difficulty.rest_factor(difficulty_level) / previous_factor

func reset() -> void:
	state = "rest"
	time_left = 0.38 * Difficulty.rest_factor(difficulty_level)
	tell = ""
	next_dash = false
	queued_dash = false
	jump_wait = 0.0
	attack_serial_at_release = -1
	pattern_index = 0
	current_pattern = "bite"
	committed_facing = 1
	committed_distance = 0.0
	approach_elapsed = 0.0
	leap_start_x = 0.0
	leap_travel = 0.0

func _visual_tell(fighter, message: String, progress: float = 0.0) -> void:
	if is_instance_valid(fighter.rig) and fighter.rig.has_method("set_opponent_tell"):
		fighter.rig.set_opponent_tell(message, progress)

func _clear_guard(fighter) -> void:
	fighter.boss_guard = false
	fighter.guard_remaining = 0.0

func _rest(fighter, duration: float = -1.0) -> void:
	state = "rest"
	time_left = duration if duration >= 0.0 else (0.29 + 0.06 * float(pattern_index % 2)) * Difficulty.rest_factor(difficulty_level)
	tell = ""
	queued_dash = false
	_clear_guard(fighter)
	_visual_tell(fighter, "")

func _advance(fighter) -> void:
	pattern_index += 1
	next_dash = PATTERNS[pattern_index % PATTERNS.size()] == "dash"
	_rest(fighter)

func _begin_tell(fighter, dx: float) -> void:
	state = "tell"
	queued_dash = current_pattern == "dash"
	committed_facing = 1 if dx >= 0.0 else -1
	committed_distance = absf(dx)
	time_left = float(TELL_SECONDS[current_pattern])
	tell = str(TELLS[current_pattern])
	# Guard is armed once. Its finite lifetime cannot be refreshed by held attacks.
	fighter.boss_guard = true
	fighter.guard_remaining = minf(1.5, time_left + (0.92 if current_pattern == "leap_chomp" else 0.52))
	_visual_tell(fighter, tell, 0.0)

func _choose_pattern(fighter) -> void:
	current_pattern = str(PATTERNS[pattern_index % PATTERNS.size()])
	# The six-second rush cooldown is real; a bite fills the unavailable turn.
	if current_pattern == "dash" and fighter.cooldown > 0.0:
		current_pattern = "bite"
	queued_dash = false
	approach_elapsed = 0.0
	state = "approach"

func read_input(delta: float, fighter, opponent) -> Dictionary:
	var command := {"move":0.0, "jump":false, "attack":false, "special":false, "lock_facing":false}
	jump_wait = maxf(0.0, jump_wait - delta)
	if fighter.health <= 0 or opponent.health <= 0:
		_rest(fighter, 0.38 * Difficulty.rest_factor(difficulty_level))
		return command
	# A real interruption cancels one commitment. Do not re-arm a full rest on
	# each frame of the same hit stun.
	if fighter.hurt_time > 0.0:
		if state != "rest":
			_rest(fighter, 0.24 * Difficulty.rest_factor(difficulty_level))
		return command
	time_left -= delta
	var dx: float = opponent.position.x - fighter.position.x
	var dy: float = opponent.position.y - fighter.position.y
	match state:
		"rest":
			if time_left <= 0.0 and fighter.attack_time < 0.0:
				_choose_pattern(fighter)
		"approach":
			approach_elapsed += delta
			var reach: float = float(APPROACH_REACH[current_pattern])
			var vertical_ok: bool = absf(dy) < (210.0 if current_pattern == "pellet_fan" else 110.0 if current_pattern == "leap_chomp" else 85.0)
			if absf(dx) > reach:
				command.move = signf(dx) * approach_speed
			# Pursue a player on a platform without jumping every physics frame.
			if dy < -75.0 and absf(dx) < 440.0 and jump_wait <= 0.0 and fighter.is_on_floor() and current_pattern != "leap_chomp":
				command.jump = true
				jump_wait = 1.25
			# A platform camper cannot suspend the boss's action loop forever.
			if approach_elapsed > 1.65 and not vertical_ok:
				current_pattern = "pellet_fan"
				reach = float(APPROACH_REACH[current_pattern])
				vertical_ok = absf(dy) < 260.0
			if absf(dx) <= reach and vertical_ok and fighter.attack_time < 0.0 and fighter.is_on_floor():
				_begin_tell(fighter, dx)
				command.move = 0.0
		"tell":
			var duration: float = float(TELL_SECONDS[current_pattern])
			_visual_tell(fighter, tell, clampf(1.0 - time_left / duration, 0.0, 1.0))
			if time_left <= 0.0:
				fighter.facing = committed_facing
				command.lock_facing = true
				match current_pattern:
					"bite":
						command.attack = true
						attack_serial_at_release = fighter.attack_serial
						state = "executing"
					"dash":
						command.special = true
						attack_serial_at_release = fighter.attack_serial
						state = "executing"
					"pellet_fan":
						pattern_released.emit("pellet_fan")
						state = "executing"
						time_left = 0.33
						_clear_guard(fighter)
					"leap_chomp":
						command.jump = true
						leap_start_x = fighter.position.x
						leap_travel = clampf(committed_distance - 135.0, 0.0, 125.0)
						command.move = float(committed_facing) * approach_speed if leap_travel > 0.0 else 0.0
						state = "leaping"
						time_left = 0.52
				tell = ""
				_visual_tell(fighter, "")
		"leaping":
			command.move = float(committed_facing) * approach_speed if absf(fighter.position.x - leap_start_x) < leap_travel else 0.0
			if time_left <= 0.0:
				fighter.facing = committed_facing
				command.attack = true
				command.lock_facing = true
				attack_serial_at_release = fighter.attack_serial
				state = "executing"
		"executing":
			if current_pattern == "pellet_fan":
				if time_left <= 0.0:
					_advance(fighter)
			else:
				# End guard at the actual active-window end; recovery is punishable.
				if fighter.attack_time >= 0.0 and fighter.attack_time >= float(fighter.attack_spec.get("windup", 0.0)) + float(fighter.attack_spec.get("active", 0.0)):
					_clear_guard(fighter)
				if fighter.attack_time < 0.0:
					_advance(fighter)
	return command
