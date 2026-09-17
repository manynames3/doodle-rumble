extends RefCounted
## Fixed-step Doodle Rally simulation. No nodes, input polling, clocks, or saved data.
## Call setup(), then tick(1.0 / 60.0, [Settings.read_player(0), ...]) from physics.
## Consume events with drain_events(); pausing simply stops calling tick().

const LAPS := 2
const MAX_LANE := 30.0
const TURBO_COST := 35.0
const CAR_SPEEDS := [159.0, 166.0, 156.0]
const CAR_NAMES := ["Dragon Wagon", "Rocket Bug", "Cloud Cruiser"]

var racers: Array[Dictionary] = []
var stamps: Array[Dictionary] = []
var events: Array[Dictionary] = []
var challenge: Dictionary = {}
var race_time := 0.0
var track_length := 0.0
var laps := LAPS
var finished := false
var humans_count := 1
var difficulty := 0
var assist := true
var course_id := ""
var _curve: Curve2D
var _seed := 1


func setup(curve: Curve2D, course: Dictionary, styles: Array, colors: Array, humans: int = 1, level: int = 0, auto_forward: bool = true) -> void:
	_curve = curve
	track_length = curve.get_baked_length() if curve != null else 0.0
	track_length = maxf(track_length, 1.0)
	course_id = str(course.get("id", "custom"))
	_seed = int(course.get("seed", 271828))
	humans_count = clampi(humans, 1, 2)
	difficulty = clampi(level, 0, 2)
	assist = auto_forward
	race_time = 0.0
	finished = false
	events.clear()
	challenge.clear()
	if course.has("challenge") and course["challenge"] is Dictionary:
		var data: Dictionary = course["challenge"]
		start_challenge(str(data.get("kind", "stars")), float(data.get("duration", 35.0)), int(data.get("target", 4)))
	_build_stamps(course.get("stamps", []))
	racers.clear()
	var count := humans_count + 2
	for i in range(count):
		var style := clampi(int(styles[i]) if i < styles.size() else i % 3, 0, 2)
		var color: Variant = colors[i] if i < colors.size() else i % 4
		var start_distance := 0.0 if i == 0 else -18.0 if i == 1 and humans_count == 2 else -32.0 - 24.0 * float(i - humans_count)
		var start_lane: float = [-18.0, 18.0, 1.0, -5.0][i]
		racers.append({
			"distance": start_distance, "lane": start_lane, "speed": 0.0,
			"style": style, "color": color, "human": i < humans_count,
			"is_human": i < humans_count, "slot": i if i < humans_count else -1,
			"finished": false, "finish_time": -1.0, "stars": 0,
			"collected_stars": [],
			"boost": 48.0, "turbo": 0.0, "hop": 0.0, "drift": 0.0,
			"heading": heading_at(start_distance), "lane_velocity": 0.0,
			"turn_lean": 0.0, "slowdown": 0.0,
			"_hop_left": 0.0, "_hop_duration": 0.0, "_hop_cooldown": 0.0,
			"_drift_held": false, "_drift_time": 0.0, "_drift_boost": 0.0,
			"_ai_lane": start_lane, "_ai_bend": 0.0
		})


func _build_stamps(source: Variant) -> void:
	stamps.clear()
	if source is Array:
		for item in source:
			if not item is Dictionary:
				continue
			var kind := str(item.get("kind", ""))
			if kind not in ["ramp", "boost", "puddle", "gate", "wind", "star"]:
				continue
			var u := float(item.get("u", -1.0))
			var lane := float(item.get("lane", 0.0))
			if not is_finite(u) or not is_finite(lane) or u < 0.0 or u >= 1.0:
				continue
			stamps.append({"kind": kind, "u": u, "lane": clampf(lane, -MAX_LANE, MAX_LANE), "active": false, "phase": 0.0})
	# Stars give every course a recoverable turbo budget and a visible optional line.
	for i in range(8):
		var u := (float(i) + 0.43) / 8.0
		var lane: float = [-24.0, 0.0, 24.0, 0.0][i % 4]
		var crowded := false
		for stamp in stamps:
			if absf(float(stamp.u) - u) < 0.025 and absf(float(stamp.lane) - lane) < 18.0:
				crowded = true
		if not crowded:
			stamps.append({"kind": "star", "u": u, "lane": lane, "active": true, "phase": 0.0})
	stamps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.u) < float(b.u))
	_update_gate_states(false)


func start_challenge(kind: String, duration: float = 35.0, target: int = 4) -> void:
	if kind not in ["stars", "drifts", "hops", "clean_gates", "time_trial"]:
		kind = "stars"
	challenge = {"kind": kind, "duration": maxf(duration, 0.1), "time_left": maxf(duration, 0.1), "target": maxi(target, 1), "score": 0, "state": "active"}


func drain_events() -> Array[Dictionary]:
	var result := events.duplicate(true)
	events.clear()
	return result


func tick(dt: float, commands: Array) -> void:
	if finished or not is_finite(dt) or dt <= 0.0 or _curve == null:
		return
	# The caller is expected to use a fixed physics step. Split long steps so a
	# frame hitch cannot skip a course stamp or create a giant steering leap.
	var remaining := dt
	while remaining > 0.000001:
		var step := minf(remaining, 1.0 / 60.0)
		_tick_step(step, commands)
		remaining -= step
		if finished:
			break


func _tick_step(dt: float, commands: Array) -> void:
	var previous_time := race_time
	race_time += dt
	_update_gate_states(true)
	var old_distances: Array[float] = []
	var new_finishers: Array[int] = []
	for racer in racers:
		old_distances.append(float(racer.distance))
	for i in range(racers.size()):
		var racer := racers[i]
		if racer.finished:
			continue
		var command: Dictionary = commands[i] if i < humans_count and i < commands.size() else _ai_command(i)
		_update_racer(i, racer, dt, command, previous_time)
		_cross_stamps(i, racer, old_distances[i])
		if racer.distance >= track_length * float(laps):
			racer.distance = track_length * float(laps)
			racer.finished = true
			new_finishers.append(i)
	for i in new_finishers:
		var racer := racers[i]
		events.append({"kind": "finish", "racer": i, "rank": rank_for(i), "time": racer.finish_time, "message": "%s finished!" % CAR_NAMES[int(racer.style)]})
	for i in range(racers.size()):
		for j in range(i + 1, racers.size()):
			if old_distances[i] <= old_distances[j] - 5.0 and float(racers[i].distance) > float(racers[j].distance) + 5.0:
				events.append({"kind": "pass", "racer": i, "other": j})
			elif old_distances[j] <= old_distances[i] - 5.0 and float(racers[j].distance) > float(racers[i].distance) + 5.0:
				events.append({"kind": "pass", "racer": j, "other": i})
	_update_challenge(dt)
	var all_humans_done := true
	for i in range(humans_count):
		all_humans_done = all_humans_done and bool(racers[i].finished)
	finished = all_humans_done
	if finished:
		if not challenge.is_empty() and str(challenge.state) == "active":
			challenge.state = "failed"
			events.append({"kind": "challenge_failed", "challenge": challenge.kind, "score": challenge.score, "message": "Try the challenge again!"})
		events.append({"kind": "race_complete", "time": race_time})


func _update_racer(i: int, racer: Dictionary, dt: float, command: Dictionary, previous_time: float) -> void:
	var old_distance := float(racer.distance)
	var old_hop_left := float(racer._hop_left)
	var move := float(command.get("move", 0.0))
	if not is_finite(move):
		move = 0.0
	move = clampf(move, -1.0, 1.0)
	var curvature := _curvature(old_distance)
	var bend := absf(curvature)
	var corner_sign := signf(curvature)
	var steering_rate := 94.0 * (1.23 if bool(command.get("attack", false)) else 1.0)
	var previous_lane := float(racer.lane)
	racer.lane = clampf(previous_lane + move * steering_rate * dt * (1.0 if assist or not bool(racer.human) else 1.17), -MAX_LANE, MAX_LANE)
	racer.lane_velocity = (float(racer.lane) - previous_lane) / dt
	racer.turn_lean = clampf(move * 0.58 + curvature * 0.4, -1.0, 1.0)
	var attack := bool(command.get("attack", false))
	if attack:
		racer._drift_time = float(racer._drift_time) + dt
		# A real turn and a useful line are required. Straight brake-spam only loses speed.
		if bend > 0.12 and move * corner_sign > 0.2 and float(racer._drift_time) > 0.2:
			racer.drift = minf(1.0, float(racer.drift) + dt * (0.58 + bend * 1.2))
		else:
			racer.drift = maxf(0.0, float(racer.drift) - dt * 0.08)
	elif bool(racer._drift_held):
		if float(racer.drift) >= 0.28 and float(racer._drift_time) >= 0.45:
			racer._drift_boost = 0.42 + float(racer.drift) * 0.65
			var fuel := 8.0 + float(racer.drift) * 12.0
			racer.boost = minf(100.0, float(racer.boost) + fuel)
			events.append({"kind": "drift_boost", "racer": i, "charge": racer.drift, "fuel": fuel, "boost": racer.boost, "message": "Scribble slide!"})
			_challenge_point("drifts", i)
		racer.drift = 0.0
		racer._drift_time = 0.0
	racer._drift_held = attack

	racer._hop_cooldown = maxf(0.0, float(racer._hop_cooldown) - dt)
	racer._hop_left = maxf(0.0, old_hop_left - dt)
	if bool(command.get("jump", false)) and float(racer._hop_cooldown) <= 0.0 and old_hop_left <= 0.0:
		var hop_duration := 1.2 if int(racer.style) == 2 else 0.64
		racer._hop_duration = hop_duration
		racer._hop_left = hop_duration
		racer._hop_cooldown = 2.2 if int(racer.style) == 2 else 2.0
		events.append({"kind": "hop", "racer": i, "duration": hop_duration})
		_challenge_point("hops", i)
	racer.hop = sin(PI * float(racer._hop_left) / maxf(float(racer._hop_duration), 0.01)) if float(racer._hop_left) > 0.0 else 0.0

	racer.turbo = maxf(0.0, float(racer.turbo) - dt)
	racer._drift_boost = maxf(0.0, float(racer._drift_boost) - dt)
	racer.slowdown = maxf(0.0, float(racer.slowdown) - dt)
	if bool(command.get("special", false)) and float(racer.boost) >= TURBO_COST and float(racer.turbo) <= 0.0:
		racer.boost = float(racer.boost) - TURBO_COST
		racer.turbo = 1.5 if int(racer.style) == 1 else 1.1
		events.append({"kind": "turbo", "racer": i, "message": "Crayon turbo!"})

	var corner_inside := clampf(float(racer.lane) * corner_sign / MAX_LANE, -1.0, 1.0)
	var line_penalty := bend * (0.15 if assist and bool(racer.human) else 0.31) * (1.0 - 0.6 * corner_inside)
	var speed_target := float(CAR_SPEEDS[int(racer.style)]) * (1.0 - line_penalty)
	if not bool(racer.human):
		speed_target *= [0.90, 0.97, 1.04][difficulty]
	if attack:
		speed_target *= 0.76
	if float(racer.slowdown) > 0.0:
		speed_target *= 0.7
	if float(racer.turbo) > 0.0:
		var straight_bonus := 1.95 if int(racer.style) == 1 and bend < 0.13 else 1.69
		speed_target *= straight_bonus
	elif float(racer._drift_boost) > 0.0:
		speed_target *= 1.48
	racer.speed = move_toward(float(racer.speed), speed_target, (340.0 if speed_target > float(racer.speed) else 490.0) * dt)
	var unbounded_distance := old_distance + float(racer.speed) * dt
	racer.distance = minf(unbounded_distance, track_length * float(laps))
	racer.heading = heading_at(float(racer.distance))
	if racer.distance >= track_length * float(laps):
		var traveled := unbounded_distance - old_distance
		var fraction := clampf((track_length * float(laps) - old_distance) / maxf(traveled, 0.0001), 0.0, 1.0)
		racer.finish_time = previous_time + dt * fraction
	if old_distance < track_length and float(racer.distance) >= track_length:
		events.append({"kind": "final_lap", "racer": i, "message": "Last lap!"})


func _cross_stamps(i: int, racer: Dictionary, previous_distance: float) -> void:
	var distance := float(racer.distance)
	for lap in range(laps):
		var lap_start := float(lap) * track_length
		for stamp_index in range(stamps.size()):
			var stamp := stamps[stamp_index]
			var at := lap_start + float(stamp.u) * track_length
			if (at <= previous_distance and not (at == 0.0 and previous_distance == 0.0)) or at > distance:
				continue
			var near := absf(float(racer.lane) - float(stamp.lane)) < 18.0
			# A hop protects from the first physics step through landing, even while
			# the visible arc is still near the ground at takeoff.
			var airborne := float(racer._hop_left) > 0.0
			var data := {"racer": i, "u": stamp.u, "lane": stamp.lane, "lap": lap + 1, "stamp": stamp_index}
			match str(stamp.kind):
				"star":
					if near:
						racer.stars = int(racer.stars) + 1
						racer.collected_stars.append(lap * stamps.size() + stamp_index)
						racer.boost = minf(100.0, float(racer.boost) + 17.0)
						data.kind = "star"
						data.total = racer.stars
						events.append(data)
						_challenge_point("stars", i)
				"boost":
					if near:
						racer.boost = minf(100.0, float(racer.boost) + 25.0)
						racer._drift_boost = maxf(float(racer._drift_boost), 0.65)
						data.kind = "boost_pad"
						events.append(data)
				"ramp":
					if near:
						racer._hop_duration = 1.3 if int(racer.style) == 2 else 0.8
						racer._hop_left = float(racer._hop_duration)
						racer.hop = 0.1
						data.kind = "ramp"
						events.append(data)
				"puddle":
					if near and not airborne:
						racer.slowdown = 0.42 if int(racer.style) == 0 else 0.88
						data.kind = "splash"
						events.append(data)
				"gate":
					if near and bool(stamp.active) and not airborne:
						racer.slowdown = 0.5 if int(racer.style) == 0 else 1.0
						data.kind = "gate_hit"
						events.append(data)
					elif near and not bool(stamp.active):
						data.kind = "gate_clear"
						events.append(data)
						_challenge_point("clean_gates", i)
				"wind":
					if near:
						var push := 9.0 if int(racer.style) == 0 else 12.0 if int(racer.style) == 2 else 18.0
						racer.lane = clampf(float(racer.lane) + push * (1.0 if float(stamp.lane) <= 0 else -1.0), -MAX_LANE, MAX_LANE)
						data.kind = "wind"
						events.append(data)


func _update_gate_states(report: bool) -> void:
	for i in range(stamps.size()):
		var stamp := stamps[i]
		if str(stamp.kind) != "gate":
			continue
		var phase := fposmod(race_time + float(i % 3) * 0.8, 3.6) / 3.6
		var active := phase < 0.61
		var changed := bool(stamp.active) != active
		stamp.phase = phase
		stamp.active = active
		if changed and report:
			events.append({"kind": "gate_toggle", "stamp": i, "u": stamp.u, "lane": stamp.lane, "active": active})


func _ai_command(i: int) -> Dictionary:
	var racer := racers[i]
	var distance := float(racer.distance)
	var bend := _curvature(distance + 40.0)
	var ideal := signf(bend) * minf(24.0, absf(bend) * 65.0)
	var target := ideal
	var nearest := INF
	var obstacle_index := -1
	var obstacle_kind := ""
	var obstacle_lane := 0.0
	for lap in range(laps):
		for j in range(stamps.size()):
			var stamp := stamps[j]
			if str(stamp.kind) not in ["puddle", "gate", "wind"]:
				continue
			if str(stamp.kind) == "gate" and not bool(stamp.active):
				continue
			var ahead := float(lap) * track_length + float(stamp.u) * track_length - distance
			if ahead > 0.0 and ahead < nearest:
				nearest = ahead
				obstacle_index = j + lap * stamps.size()
				obstacle_kind = str(stamp.kind)
				obstacle_lane = float(stamp.lane)
	var reaction: float = [83.0, 111.0, 139.0][difficulty]
	if nearest < reaction:
		var mistake_roll := _hash01(_seed + i * 337 + obstacle_index * 991)
		var mistake_rate: float = [0.32, 0.16, 0.055][difficulty]
		if mistake_roll >= mistake_rate:
			target = -24.0 if obstacle_lane > 0.0 else 24.0
		elif obstacle_kind == "gate" and nearest < 50.0:
			target = obstacle_lane
	# Passing chooses a neighboring line when a slower racer blocks the lane.
	if nearest >= reaction:
		for j in range(racers.size()):
			if i == j:
				continue
			var other := racers[j]
			var gap := float(other.distance) - distance
			if gap > 0.0 and gap < 75.0 and absf(float(other.lane) - target) < 19.0:
				target = -24.0 if float(other.lane) > 0.0 else 24.0
				break
	racer._ai_lane = target
	var move := clampf((target - float(racer.lane)) / 13.0, -1.0, 1.0)
	var jump: bool = obstacle_index >= 0 and nearest < 33.0 and nearest > 0.0 and absf(float(racer.lane) - obstacle_lane) < 18.0 and _hash01(_seed + i * 103 + obstacle_index * 53) > float([0.45, 0.28, 0.15][difficulty])
	var use_turbo := float(racer.boost) >= TURBO_COST and float(racer.turbo) <= 0.0 and absf(_curvature(distance)) < 0.14 and (i + int(distance / 350.0)) % 3 == 0
	return {"move": move, "jump": jump, "attack": false, "special": use_turbo}


func _hash01(value: int) -> float:
	var x := posmod(value * 1103515245 + 12345, 2147483647)
	return float(x) / 2147483647.0


func _curvature(distance: float) -> float:
	var before := _tangent(distance - 27.0)
	var after := _tangent(distance + 27.0)
	return before.angle_to(after)


func _tangent(distance: float) -> Vector2:
	if _curve == null:
		return Vector2.RIGHT
	var back := _curve.sample_baked(fposmod(distance - 4.0, track_length), true)
	var front := _curve.sample_baked(fposmod(distance + 4.0, track_length), true)
	var tangent := front - back
	return tangent.normalized() if tangent.length_squared() > 0.0001 else Vector2.RIGHT


func heading_at(distance: float) -> float:
	return _tangent(distance).angle()


func position_at(distance: float, lane: float = 0.0) -> Vector2:
	if _curve == null:
		return Vector2.ZERO
	var tangent := _tangent(distance)
	return _curve.sample_baked(fposmod(distance, track_length), true) + Vector2(-tangent.y, tangent.x) * lane


func rank_for(index: int) -> int:
	if index < 0 or index >= racers.size():
		return 0
	var racer := racers[index]
	var rank := 1
	for j in range(racers.size()):
		if j == index:
			continue
		var other := racers[j]
		if bool(other.finished) and not bool(racer.finished):
			rank += 1
		elif bool(other.finished) and bool(racer.finished) and float(other.finish_time) < float(racer.finish_time):
			rank += 1
		elif not bool(other.finished) and not bool(racer.finished) and float(other.distance) > float(racer.distance):
			rank += 1
	return rank


func _challenge_point(kind: String, racer_index: int) -> void:
	if challenge.is_empty() or str(challenge.state) != "active" or racer_index >= humans_count or str(challenge.kind) != kind:
		return
	challenge.score = int(challenge.score) + 1
	if int(challenge.score) >= int(challenge.target):
		challenge.state = "complete"
		events.append({"kind": "challenge_complete", "challenge": kind, "score": challenge.score, "message": "Challenge complete!"})


func _update_challenge(dt: float) -> void:
	if challenge.is_empty() or str(challenge.state) != "active":
		return
	if str(challenge.kind) == "time_trial":
		for i in range(humans_count):
			if bool(racers[i].finished):
				challenge.state = "complete"
				events.append({"kind": "challenge_complete", "challenge": "time_trial", "score": 1, "message": "Time trial complete!"})
				return
	challenge.time_left = maxf(0.0, float(challenge.time_left) - dt)
	if float(challenge.time_left) <= 0.0:
		challenge.state = "failed"
		events.append({"kind": "challenge_failed", "challenge": challenge.kind, "score": challenge.score, "message": "Try the challenge again!"})
