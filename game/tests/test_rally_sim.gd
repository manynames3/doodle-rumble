extends SceneTree
## Focused deterministic simulation tests. Run headless with --isolated-qa.
const Sim = preload("res://scripts/rally_sim.gd")
const DT := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: " + description)


func course_curve() -> Curve2D:
	var curve := Curve2D.new()
	curve.bake_interval = 3.0
	var points := PackedVector2Array([
		Vector2(0, 0), Vector2(450, 0), Vector2(530, 75),
		Vector2(530, 260), Vector2(450, 335), Vector2(0, 335),
		Vector2(-80, 260), Vector2(-80, 75)
	])
	for i in range(points.size()):
		var handle := (points[(i + 1) % points.size()] - points[posmod(i - 1, points.size())]) * 0.17
		curve.add_point(points[i], -handle, handle)
	var first_handle := (points[1] - points[-1]) * 0.17
	curve.add_point(points[0], -first_handle, first_handle)
	return curve


func new_sim(styles: Array = [0, 1, 2, 0], humans: int = 1, level: int = 0, assist: bool = true, stamps: Array = [], extra: Dictionary = {}) -> RefCounted:
	var sim := Sim.new()
	var course := {"id": "test", "title": "Test Loop", "theme": "desk", "seed": 19, "stamps": stamps}
	course.merge(extra, true)
	sim.setup(course_curve(), course, styles, [0, 1, 2, 3], humans, level, assist)
	return sim


func run() -> void:
	await process_frame
	test_contract_and_steering()
	test_drift_and_bend()
	test_car_traits_and_stamps()
	test_ai_and_difficulty()
	test_challenges()
	test_consistent_steps()
	test_full_races()
	print("Rally simulation: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_contract_and_steering() -> void:
	var sim := new_sim()
	check(sim.racers.size() == 3 and sim.humans_count == 1, "solo field has one human and two AI")
	check(sim.laps == 2 and sim.track_length > 1200.0 and not sim.finished, "two-lap race starts on valid curve")
	check(sim.stamps.size() >= 8 and sim.racers[0].boost == 48.0, "stars and usable turbo resource are ready")
	for field in ["distance", "lane", "speed", "style", "color", "finished", "finish_time", "stars", "collected_stars", "boost", "turbo", "hop", "drift", "heading", "human", "slot", "lane_velocity", "turn_lean"]:
		check(sim.racers[0].has(field), "public racer field " + field)
	sim.tick(DT, [{"move": 1.0}])
	check(float(sim.racers[0].distance) > 0.0 and float(sim.racers[0].lane) > -18.0, "auto-forward plus steering responds immediately")
	check(float(sim.racers[0].lane_velocity) > 0.0, "lane velocity is available for visual lean")
	var manual := new_sim([0, 1, 2], 1, 0, false)
	for i in range(60): manual.tick(DT, [{"move": 0.0}])
	check(float(manual.racers[0].distance) > 90.0, "skillful mode remains auto-forward without extra button")
	check(sim.position_at(0.0, 0.0).is_finite() and is_finite(sim.heading_at(50.0)), "track pose API is finite")
	var local := new_sim([0, 2, 1, 0], 2)
	check(local.racers.size() == 4 and local.racers[1].human and local.racers[1].slot == 1, "local race has two human slots and two AI")


func test_drift_and_bend() -> void:
	var straight := new_sim()
	for i in range(72): straight.tick(DT, [{"attack": true, "move": 1.0}])
	straight.tick(DT, [{}])
	var drift_events: Array[Dictionary] = straight.drain_events()
	var straight_boost := false
	for event in drift_events:
		if event.kind == "drift_boost" and event.racer == 0: straight_boost = true
	check(not straight_boost, "holding brake on straight cannot mint drift boost")
	check(float(straight.racers[0].drift) == 0.0, "release clears the charge")
	var bend_at := 0.0
	var bend_strength := 0.0
	for d in range(60, int(straight.track_length) - 60, 8):
		var c := absf(straight._curvature(float(d)))
		if c > bend_strength:
			bend_at = float(d)
			bend_strength = c
	check(bend_strength > 0.2, "test course has a meaningful bend")
	var inside := new_sim()
	var outside := new_sim()
	var sign_of_bend := signf(inside._curvature(bend_at))
	for candidate in [inside, outside]:
		candidate.racers[0].distance = bend_at
		candidate.racers[0].speed = 150.0
	inside.racers[0].lane = 25.0 * sign_of_bend
	outside.racers[0].lane = -25.0 * sign_of_bend
	inside.tick(DT, [{}])
	outside.tick(DT, [{}])
	check(float(inside.racers[0].speed) > float(outside.racers[0].speed), "inside racing line keeps more corner speed")
	var charged := new_sim()
	charged.racers[0].distance = bend_at - 38.0
	charged.racers[0].lane = -20.0 * sign_of_bend
	for i in range(52): charged.tick(DT, [{"attack": true, "move": sign_of_bend}])
	var charge := float(charged.racers[0].drift)
	charged.tick(DT, [{}])
	var earned := false
	var refilled := false
	for event in charged.drain_events():
		if event.kind == "drift_boost" and event.racer == 0:
			earned = true
			refilled = float(event.fuel) >= 8.0 and float(event.boost) > 48.0
	check(charge >= 0.28 and earned and refilled, "controlled drift release gives speed and modest turbo fuel")


func test_car_traits_and_stamps() -> void:
	var dragon := new_sim([0, 1, 2], 1, 0, true, [{"kind": "puddle", "u": 0.1, "lane": -18.0}])
	var bug := new_sim([1, 0, 2], 1, 0, true, [{"kind": "puddle", "u": 0.1, "lane": -18.0}])
	for candidate in [dragon, bug]:
		candidate.racers[0].distance = candidate.track_length * 0.1 - 9.0
		candidate.racers[0].lane = -18.0
		candidate.racers[0].speed = 160.0
		candidate.tick(0.1, [{}])
	check(float(dragon.racers[0].slowdown) < float(bug.racers[0].slowdown), "Dragon Wagon shrugs off puddles faster")
	var dragon_hit := false
	for event in dragon.drain_events():
		if event.kind == "splash" and event.racer == 0: dragon_hit = true
	check(dragon_hit, "obstacle hit emits a renderer feedback event")
	var hop_clear := new_sim([0, 1, 2], 1, 0, true, [{"kind": "puddle", "u": 0.1, "lane": -18.0}])
	hop_clear.racers[0].distance = hop_clear.track_length * 0.1 - 9.0
	hop_clear.racers[0].lane = -18.0
	hop_clear.racers[0].speed = 160.0
	hop_clear.tick(0.1, [{"jump": true}])
	check(float(hop_clear.racers[0].slowdown) == 0.0, "hop begun before a puddle protects the racer")
	var dragon_hop := new_sim([0, 1, 2])
	var cloud_hop := new_sim([2, 0, 1])
	for candidate in [dragon_hop, cloud_hop]:
		candidate.tick(DT, [{"jump": true}])
		for i in range(42): candidate.tick(DT, [{}])
	check(float(dragon_hop.racers[0].hop) == 0.0 and float(cloud_hop.racers[0].hop) > 0.0, "Cloud Cruiser glides longer than Dragon Wagon")
	cloud_hop.tick(DT, [{"jump": true}])
	var hop_count := 0
	for event in cloud_hop.drain_events():
		if event.kind == "hop" and event.racer == 0: hop_count += 1
	check(hop_count == 1, "grounded cooldown rejects hop spamming")
	var rocket := new_sim([1, 0, 2])
	var dragon_turbo := new_sim([0, 1, 2])
	rocket.tick(DT, [{"special": true}])
	dragon_turbo.tick(DT, [{"special": true}])
	check(float(rocket.racers[0].turbo) > 1.4 and float(rocket.racers[0].boost) < 48.0, "Rocket Bug has long turbo and spends resource")
	for i in range(60):
		rocket.tick(DT, [{}])
		dragon_turbo.tick(DT, [{}])
	check(float(rocket.racers[0].speed) > float(dragon_turbo.racers[0].speed) + 20.0, "Rocket Bug gains a stronger boost on a straight")
	var gate := new_sim([0, 1, 2], 1, 0, true, [{"kind": "gate", "u": 0.2, "lane": 0.0}])
	var gate_index := -1
	for i in range(gate.stamps.size()):
		if gate.stamps[i].kind == "gate": gate_index = i
	check(gate_index >= 0 and gate.stamps[gate_index].has("phase") and gate.stamps[gate_index].has("active"), "timed gate exposes telegraph phase and state")
	check(bool(gate.stamps[gate_index].active) == (float(gate.stamps[gate_index].phase) < 0.61), "gate hazard matches visible phase")
	var initial := bool(gate.stamps[gate_index].active)
	for i in range(160): gate.tick(DT, [{}])
	check(bool(gate.stamps[gate_index].active) != initial, "gate visibly alternates open and closed")
	var toggled := false
	for event in gate.drain_events():
		if event.kind == "gate_toggle": toggled = true
	check(toggled, "gate timing emits a transition event")
	var endpoint := new_sim([0, 1, 2], 1, 0, true, [{"kind": "boost", "u": 0.0, "lane": 0.0}, {"kind": "star", "u": 0.999, "lane": 0.0}])
	check(endpoint.stamps.any(func(stamp: Dictionary) -> bool: return stamp.kind == "boost" and stamp.u == 0.0) and endpoint.stamps.any(func(stamp: Dictionary) -> bool: return stamp.kind == "star" and stamp.u == 0.999), "stamps accept full normalized [0,1) course range")
	endpoint.racers[0].lane = 0.0
	endpoint.tick(DT, [{}])
	var start_pad := false
	for event in endpoint.drain_events():
		if event.kind == "boost_pad" and event.racer == 0: start_pad = true
	check(start_pad, "stamp at u=0 activates on the first physics step")
	endpoint.racers[0].distance = endpoint.track_length * 0.999 - 8.0
	endpoint.racers[0].speed = 160.0
	endpoint.tick(0.1, [{}])
	check(endpoint.racers[0].stars == 1, "stamp near u=1 remains reachable before lap boundary")
	var ramp_clear := new_sim([0, 1, 2], 1, 0, true, [{"kind": "ramp", "u": 0.1, "lane": -18.0}, {"kind": "puddle", "u": 0.12, "lane": -18.0}])
	ramp_clear.racers[0].distance = ramp_clear.track_length * 0.1 - 8.0
	ramp_clear.racers[0].lane = -18.0
	ramp_clear.racers[0].speed = 160.0
	ramp_clear.tick(0.4, [{}])
	var ramp_event := false
	for event in ramp_clear.drain_events():
		if event.kind == "ramp" and event.racer == 0: ramp_event = true
	check(ramp_event and float(ramp_clear.racers[0].slowdown) == 0.0, "ramp launches racer over a nearby puddle")


func test_ai_and_difficulty() -> void:
	var obstacle := [{"kind": "puddle", "u": 0.1, "lane": 0.0}]
	var skilled := new_sim([0, 1, 2], 1, 2, true, obstacle)
	var obstacle_distance: float = skilled.track_length * 0.1
	var avoided := false
	for i in range(180):
		var previous: float = skilled.racers[1].distance
		skilled.tick(DT, [{}])
		if previous < obstacle_distance and float(skilled.racers[1].distance) >= obstacle_distance:
			avoided = absf(float(skilled.racers[1].lane)) >= 18.0 or float(skilled.racers[1].hop) > 0.15
	check(avoided, "AI chooses an open line or hops at obstacle crossing")
	var easy := new_sim([0, 1, 2], 1, 0)
	var hard := new_sim([0, 1, 2], 1, 2)
	for i in range(540):
		easy.tick(DT, [{}])
		hard.tick(DT, [{}])
	check(float(hard.racers[1].distance) > float(easy.racers[1].distance) + 30.0, "higher AI difficulty earns pace on the same course")
	check(float(hard.racers[1].distance) < hard.track_length * 2.0, "AI pace progresses continuously without teleporting to finish")
	var player_ahead := new_sim([0, 1, 2], 1, 1)
	var player_behind := new_sim([0, 1, 2], 1, 1)
	player_ahead.racers[0].distance = 1200.0
	player_behind.racers[0].distance = -250.0
	for i in range(180):
		player_ahead.tick(DT, [{}])
		player_behind.tick(DT, [{}])
	check(absf(float(player_ahead.racers[1].distance) - float(player_behind.racers[1].distance)) < 0.01, "AI pace has no hidden distance-based rubberband")
	var passing := new_sim()
	passing.racers[1].distance = 125.0
	passing.racers[1].lane = 0.0
	passing.racers[2].distance = 85.0
	passing.racers[2].lane = 0.0
	check(float(passing._ai_command(2).move) > 0.0, "AI chooses a free neighboring lane to pass a slower rival")


func test_challenges() -> void:
	var sim := new_sim()
	sim.start_challenge("stars", 3.0, 1)
	var first_star: Dictionary
	for stamp in sim.stamps:
		if stamp.kind == "star":
			first_star = stamp
			break
	sim.racers[0].distance = float(first_star.u) * sim.track_length - 10.0
	sim.racers[0].lane = float(first_star.lane)
	sim.racers[0].speed = 160.0
	sim.tick(0.1, [{}])
	check(sim.challenge.state == "complete" and sim.racers[0].stars == 1 and float(sim.racers[0].boost) > 48.0, "collected star recharges turbo and completes timed challenge")
	check(sim.racers[0].collected_stars.size() == 1, "star collection records a stable per-racer stamp id")
	sim.racers[0].distance = sim.track_length + float(first_star.u) * sim.track_length - 10.0
	sim.racers[0].speed = 160.0
	sim.tick(0.1, [{}])
	check(sim.racers[0].stars == 2 and sim.racers[0].collected_stars.size() == 2 and sim.racers[0].collected_stars[0] != sim.racers[0].collected_stars[1], "star tracking distinguishes first and second laps")
	var completed := false
	for event in sim.drain_events():
		if event.kind == "challenge_complete": completed = true
	check(completed, "challenge completion emits an event")
	sim.start_challenge("drifts", 0.1, 2)
	for i in range(8): sim.tick(DT, [{}])
	check(sim.challenge.state == "failed", "timed skill challenge expires without target")
	var unfinished := new_sim()
	unfinished.start_challenge("stars", 100.0, 50)
	unfinished.racers[0].distance = unfinished.track_length * 2.0 - 5.0
	unfinished.racers[0].speed = 160.0
	unfinished.tick(0.1, [{}])
	check(unfinished.finished and unfinished.challenge.state == "failed", "unmet challenge resolves when race ends")


func test_consistent_steps() -> void:
	var fine := new_sim()
	var coarse := new_sim()
	for i in range(600): fine.tick(DT, [{"move": 0.0}])
	for i in range(300): coarse.tick(2.0 * DT, [{"move": 0.0}])
	check(absf(float(fine.racers[0].distance) - float(coarse.racers[0].distance)) < 0.01, "two fixed step sizes yield equivalent player progress")
	check(absf(float(fine.racers[1].distance) - float(coarse.racers[1].distance)) < 0.01, "AI decisions are deterministic across tick grouping")
	check(absf(fine.race_time - coarse.race_time) < 0.001, "race clock is deterministic across tick grouping")


func test_full_races() -> void:
	for human_count in [1, 2]:
		var sim := new_sim([0, 2, 1, 0], human_count, 1)
		var ticks := 0
		var commands: Array[Dictionary] = [{}]
		if human_count == 2: commands.append({})
		while not sim.finished and ticks < 3600:
			sim.tick(DT, commands)
			ticks += 1
		check(sim.finished and ticks < 3600, "%d-player full two-lap race reaches results" % human_count)
		for i in range(human_count):
			check(sim.racers[i].finished and float(sim.racers[i].finish_time) > 0.0, "human %d receives exact finish time" % (i + 1))
			check(sim.rank_for(i) >= 1 and sim.rank_for(i) <= sim.racers.size(), "human %d receives valid rank" % (i + 1))
		var complete_count := 0
		for event in sim.drain_events():
			if event.kind == "race_complete": complete_count += 1
		check(complete_count == 1, "%d-player race completes exactly once" % human_count)
		var before: float = sim.race_time
		sim.tick(DT, commands)
		check(sim.race_time == before, "completed race clock stays fixed")
