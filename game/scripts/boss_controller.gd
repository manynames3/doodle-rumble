extends RefCounted
## Final boss uses eight committed attacks with readable tells and short punish windows.
const Difficulty = preload("res://scripts/difficulty.gd")
signal pattern_released(kind: String)
var state = "rest"
var time_left = 0.40
var pattern = 0
var tell = ""
var approach_speed: float = 1.08
var tell_duration: float = 0.65
var recovery_duration: float = 0.46
var difficulty_level: int = Difficulty.EASY
var committed_facing = -1
var jump_wait: float = 0.0
const PATTERNS = ["reaper","quake","void_orb","rift","eclipse_volley","eclipse_wave","void_pillar","camera"]
const TELLS = ["REAPER SWEEP!","JUMP THE WAVE!","VOID VOLLEY!","RIFT INCOMING!","ECLIPSE SHARDS!","JUMP THE ECLIPSE!","VOID PILLAR! MOVE!","DODGE THE MARK!"]

func configure_difficulty(selected_level: int) -> void:
	var previous_factor: float = Difficulty.rest_factor(difficulty_level)
	difficulty_level = Difficulty.normalized_level(selected_level)
	approach_speed = 1.22 * Difficulty.move_factor(difficulty_level)
	recovery_duration = 0.34 * Difficulty.rest_factor(difficulty_level)
	if state == "rest": time_left *= Difficulty.rest_factor(difficulty_level) / previous_factor
	# Boss cast tells remain fully readable at every difficulty.
	tell_duration = 0.65

func reset() -> void:
	state = "rest"
	time_left = 0.40 * Difficulty.rest_factor(difficulty_level)
	pattern = 0
	tell = ""
	jump_wait = 0.0

func read_input(delta: float, fighter, opponent) -> Dictionary:
	var command = {"move":0.0,"jump":false,"attack":false,"special":false,"lock_facing":false}
	if fighter.health <= 0 or opponent.health <= 0: return command
	if fighter.hurt_time > 0:
		tell = ""
		fighter.boss_cast = ""
		# Keep the pending pattern; damage buys a short window, never a whole AI reset.
		state = "rest"
		time_left = 0.28
		return command
	jump_wait = maxf(0.0,jump_wait-delta)
	time_left -= delta
	var enraged = fighter.health < fighter.max_health*0.5
	match state:
		"rest":
			fighter.boss_cast = ""
			if time_left <= 0:
				state = "approach"
				time_left = 0.78
		"approach":
			var dx = opponent.position.x-fighter.position.x
			var dy: float = opponent.position.y-fighter.position.y
			var reach = fighter.weapon.reach*0.88 if pattern == 0 else 470.0
			if absf(dx) > reach and time_left > 0:
				command.move = signf(dx)*approach_speed
				if dy < -70.0 and absf(dx) < 510.0 and jump_wait <= 0.0 and fighter.is_on_floor():
					command.jump = true
					jump_wait = 1.05
			else:
				state = "tell"
				time_left = tell_duration
				tell = TELLS[pattern]
				fighter.boss_cast = PATTERNS[pattern]
				committed_facing = 1 if dx>=0 else -1
				fighter.facing = committed_facing
				fighter.guard_remaining = tell_duration+0.60
				fighter.boss_guard = true
		"tell":
			command.lock_facing = true
			fighter.facing = committed_facing
			fighter.boss_charge = clampf(1-time_left/tell_duration,0,1)
			if time_left <= 0:
				match PATTERNS[pattern]:
					"reaper": command.attack = true
					"quake": command.special = true; fighter.cooldown = 0
					_: pattern_released.emit(PATTERNS[pattern])
				state = "executing"
				var kind: String = PATTERNS[pattern]
				time_left = 0.34 if kind == "reaper" else 0.55 if kind == "quake" else 0.58 if kind in ["void_orb","eclipse_volley"] else 1.55
				tell = ""
		"executing":
			command.lock_facing = true
			if fighter.attack_time >= 0 and fighter.attack_time >= float(fighter.attack_spec.windup)+float(fighter.attack_spec.active):
				fighter.guard_remaining = 0
			if fighter.attack_time < 0 and time_left <= 0:
				fighter.guard_remaining = 0
				fighter.boss_cast = ""
				pattern = (pattern+1)%PATTERNS.size()
				state = "rest"
				time_left = recovery_duration-(0.10 if enraged else 0)
	return command
