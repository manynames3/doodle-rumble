extends Node2D
## Optional arena tactics. Call begin_tick before fighter.tick and end_tick after both.
const Layout = preload("res://scripts/arena_layout.gd")
signal activated(kind: String, at: Vector2)

const SPRING_SPEED = -1010.0
const TELEPORT_COOLDOWN = 2.0
const BRIDGE_LOAD_TIME = 0.52
const BRIDGE_REFORM_TIME = 2.25

var arena_kind = "desktop"
var boss_large = false
var platform_bodies: Array = []
var jump_was_down = [false,false]
var suppress_jump_until_release = [false,false]
var spring_pending = [false,false]
var teleport_cooldown = [0.0,0.0]
var flash_time = 0.0
var flash_at = Vector2.ZERO
var bridge_load = 0.0
var bridge_gone = 0.0
var reduced_motion = false

func configure(kind: String, bodies: Array, large_boss: bool = false) -> void:
	arena_kind = kind
	boss_large = large_boss
	platform_bodies = bodies
	reset()

func reset() -> void:
	jump_was_down = [false,false]
	suppress_jump_until_release = [false,false]
	spring_pending = [false,false]
	teleport_cooldown = [0.0,0.0]
	flash_time = 0.0
	bridge_load = 0.0
	bridge_gone = 0.0
	_set_bridge_collision(true)
	queue_redraw()

func _set_bridge_collision(enabled: bool) -> void:
	if arena_kind != "quarry" or platform_bodies.size() <= Layout.QUARRY_BRIDGE_INDEX:
		return
	var body: StaticBody2D = platform_bodies[Layout.QUARRY_BRIDGE_INDEX]
	if not is_instance_valid(body): return
	var shape: CollisionShape2D = body.get_child(0)
	shape.set_deferred("disabled",not enabled)

func begin_tick(delta: float, fighters: Array, commands: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(2):
		var command: Dictionary = commands[i].duplicate()
		var fighter = fighters[i]
		teleport_cooldown[i] = maxf(0.0,float(teleport_cooldown[i])-delta)
		var jump_down: bool = bool(command.get("jump",false))
		var jump_pressed: bool = jump_down and not bool(jump_was_down[i])
		jump_was_down[i] = jump_down
		if not jump_down: suppress_jump_until_release[i] = false
		if suppress_jump_until_release[i]: command["jump"] = false
		spring_pending[i] = false
		if not boss_large and is_instance_valid(fighter) and fighter.health > 0 and fighter.hurt_time <= 0 and fighter.attack_time < 0 and fighter.dodge_time < 0 and fighter.is_on_floor() and jump_pressed:
			if arena_kind == "desktop" and Layout.DESKTOP_PAD.has_point(fighter.position):
				spring_pending[i] = true
			elif arena_kind == "glitch" and teleport_cooldown[i] <= 0.0:
				var pad_index = _pad_index(fighter.position)
				if pad_index >= 0:
					var destination: Vector2 = _safe_exit(pad_index,fighters[1-i].position)
					if destination != Vector2.ZERO:
						fighter.position = destination
						fighter.velocity = Vector2.ZERO
						fighter.coyote = 0.0
						fighter.jump_buffer = 0.0
						command["jump"] = false
						suppress_jump_until_release[i] = true
						teleport_cooldown[i] = TELEPORT_COOLDOWN
						_flash("teleport",destination)
		result.append(command)
	return result

func end_tick(delta: float, fighters: Array) -> void:
	flash_time = maxf(0.0,flash_time-delta)
	if boss_large:
		return
	if arena_kind == "desktop":
		for i in range(2):
			if spring_pending[i] and fighters[i].velocity.y < 0:
				fighters[i].velocity.y = SPRING_SPEED
				_flash("spring",Vector2(fighters[i].position.x,Layout.DESKTOP_PAD.position.y))
			spring_pending[i] = false
	elif arena_kind == "quarry":
		if bridge_gone > 0.0:
			bridge_gone = maxf(0.0,bridge_gone-delta)
			if bridge_gone == 0.0:
				_set_bridge_collision(true)
		else:
			var bridge: Rect2 = Layout.QUARRY_PLATFORMS[Layout.QUARRY_BRIDGE_INDEX]
			var occupied = false
			for fighter in fighters:
				if is_instance_valid(fighter) and fighter.health > 0 and fighter.is_on_floor() and fighter.position.x > bridge.position.x+14 and fighter.position.x < bridge.end.x-14 and absf(fighter.position.y-bridge.position.y)<4.0:
					occupied = true
			if occupied:
				bridge_load += delta
				if bridge_load >= BRIDGE_LOAD_TIME:
					bridge_gone = BRIDGE_REFORM_TIME
					bridge_load = 0.0
					_set_bridge_collision(false)
					_flash("crumble",bridge.get_center())
			else:
				bridge_load = maxf(0.0,bridge_load-delta*1.5)
	queue_redraw()

func _pad_index(position: Vector2) -> int:
	for i in range(Layout.GLITCH_PADS.size()):
		if Layout.GLITCH_PADS[i].has_point(position): return i
	return -1

func _safe_exit(from_index: int, other: Vector2) -> Vector2:
	var preferred: Vector2 = Layout.GLITCH_EXITS[from_index]
	var alternatives = [preferred,preferred+Vector2(-124 if from_index == 0 else 124,0),preferred+Vector2(124 if from_index == 0 else -124,0)]
	for candidate in alternatives:
		if candidate.x >= 78 and candidate.x <= 1202 and candidate.distance_to(other) > 96:
			return candidate
	return Vector2.ZERO

func _flash(kind: String, at: Vector2) -> void:
	flash_at = at
	flash_time = 0.36
	activated.emit(kind,at)
	queue_redraw()

func _draw() -> void:
	if flash_time <= 0 or reduced_motion: return
	var progress = 1.0-flash_time/0.36
	var color = Color("f4ca78") if arena_kind == "desktop" else Color("f2d47d") if arena_kind == "quarry" else Color("e18cff")
	for ring in range(2):
		draw_arc(flash_at,22+progress*42+ring*17,0,TAU,28,Color(color,(1-progress)*(0.42-ring*0.17)),2.6,true)
