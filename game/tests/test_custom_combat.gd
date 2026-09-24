extends SceneTree
## Run with --isolated-qa --silent-qa. Records stay in memory; no user save changes.
var Fighter: GDScript
const Kits = preload("res://scripts/custom_kits.gd")
const Shot = preload("res://scripts/custom_projectile.gd")
var ExistingShot: GDScript
const AI = preload("res://scripts/ai_controller.gd")
const Layout = preload("res://scripts/arena_layout.gd")
const KINDS := ["pixel_pick","bone","bat","ball","rubber_chicken","giant_crayon"]
const EXPECTED := [14,15,16,12,15,14]
var checks := 0
var failures: Array[String] = []
var world: Node2D
var prior_records: Array[Dictionary] = []
var doodles
var data

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)

func spawn(id: String, x: float = 400.0, y: float = 599.0):
	var fighter = Fighter.new()
	world.add_child(fighter)
	fighter.setup(id,1,true)
	fighter.reset_at(Vector2(x,y))
	return fighter

func step(a, b, command: Dictionary = {}, delta: float = 1.0/60.0) -> void:
	await physics_frame
	a.tick(delta,command,b)
	b.tick(delta,{},a)

func settle(a, b) -> void:
	for frame in range(5): await step(a,b)

func clean(nodes: Array) -> void:
	for node in nodes:
		if is_instance_valid(node): node.queue_free()
	await process_frame

func run() -> void:
	await process_frame
	doodles = root.get_node("Doodles")
	data = root.get_node("Data")
	Fighter = load("res://scripts/fighter.gd")
	ExistingShot = load("res://scripts/attack_effect.gd")
	check(Fighter != null and Fighter.can_instantiate(),"custom fighter script compiles")
	if Fighter == null or not Fighter.can_instantiate():
		quit(1)
		return
	prior_records = doodles._records.duplicate(true)
	for kit in KINDS:
		var record: Dictionary = doodles.new_record()
		record.id = "custom_qa_" + kit
		record.name = "QA " + kit
		record.kit = kit
		doodles._records.append(record)
	world = Node2D.new()
	root.add_child(world)
	var floor_body = StaticBody2D.new()
	var floor_shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(1280,100)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(640,650)
	world.add_child(floor_body)
	await physics_frame
	for delta in [1.0/30.0,1.0/60.0,1.0/120.0]:
		await test_basics(delta)
		await test_specials(delta)
		await test_elevated_ground_specials(delta)
		await test_bounces_and_reflection(delta)
	await test_ai()
	await test_bot_matches()
	doodles._records = prior_records
	world.queue_free()
	await process_frame
	print("CUSTOM_COMBAT_TEST_RESULT checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("  " + failure)
	quit(0 if failures.is_empty() else 1)

func test_basics(delta: float) -> void:
	for index in KINDS.size():
		var kit: String = KINDS[index]
		var id := "custom_qa_" + kit
		var a = spawn(id)
		var b = spawn("red",500)
		await settle(a,b)
		check(bool(a.definition.custom) and str(a.definition.kit) == kit and data.is_playable(id),kit+" joins the normal playable registry")
		check(a.start_attack(false) and is_equal_approx(float(a.attack_spec.windup),0.16),kit+" has a readable ground windup")
		var hits := 0
		for frame in range(ceili((a.duration()+delta)/delta)):
			await physics_frame
			a.tick(delta,{},b)
			b.invulnerable = 0
			b.position = Vector2(500,599)
			if a.try_hit(b): hits += 1
		check(hits == 1 and b.health == 100-EXPECTED[index],kit+" ground hit occurs once at delta="+str(delta))
		check(not a.hitbox().has_area(),kit+" clears its active box after recovery")
		await clean([a,b])
		a = spawn(id)
		b = spawn("red",500)
		await settle(a,b)
		await step(a,b,{"jump":true},delta)
		for frame in range(3): await step(a,b,{},delta)
		check(a.airborne_time > 0 and a.start_attack(false),kit+" starts its air variant")
		check(str(a.attack_spec.get("air_kind","")) != "" and int(a.attack_spec.damage) == EXPECTED[index],kit+" has authored air data")
		hits = 0
		for frame in range(ceili((a.duration()+delta)/delta)):
			await physics_frame
			a.tick(delta,{},b)
			a.position = Vector2(400,400)
			b.position = Vector2(500,400)
			b.invulnerable = 0
			if a.try_hit(b): hits += 1
		check(hits == 1 and b.health == 100-EXPECTED[index],kit+" air hit occurs once at delta="+str(delta))
		await clean([a,b])

func test_specials(delta: float) -> void:
	for kit in KINDS:
		var a = spawn("custom_qa_"+kit,400)
		var target_x := 510 if kit == "pixel_pick" else 620 if kit == "bone" else 540 if kit == "bat" else 675 if kit == "ball" else 520 if kit == "rubber_chicken" else 620
		var b = spawn("red",target_x)
		await settle(a,b)
		check(a.start_attack(true) and a.cooldown >= 6.0 and float(a.attack_spec.windup) >= 0.32,kit+" special starts with cooldown and long tell")
		var released: Array[String] = []
		a.released.connect(func(_fighter,kind): released.append(kind))
		var hits := 0
		var shot = null
		for frame in range(ceili((a.duration()+1.0)/delta)):
			await physics_frame
			a.tick(delta,{},b)
			b.invulnerable = 0
			if kit == "bat":
				b.position = Vector2(540,599)
				if a.try_hit(b): hits += 1
			elif released.size() > 0 and shot == null:
				shot = Shot.new()
				world.add_child(shot)
				shot.configure(a,released[0],a.facing,Layout.PLATFORMS)
			if is_instance_valid(shot) and not shot.consumed:
				b.position = Vector2(target_x,599)
				var before: int = b.health
				shot.tick(delta,b)
				if b.health < before: hits += 1
		check(released.size() == 1 and released[0] == str(a.definition.special),kit+" special releases exactly once")
		check(hits == 1 and b.health == 100-int(a.attack_spec.damage),kit+" special applies one payload at delta="+str(delta))
		if is_instance_valid(shot):
			shot.cleanup()
			check(a.active_custom_projectile_count == 0 and not a.thrown_weapon_hidden,kit+" projectile cleanup restores fighter art")
			shot.queue_free()
		check(a.cooldown > 0 and not a.start_attack(true),kit+" cannot skip special cooldown")
		await clean([a,b])

func test_bounces_and_reflection(delta: float) -> void:
	var thrower = spawn("custom_qa_ball",400)
	var target = spawn("red",1000)
	await settle(thrower,target)
	thrower.start_attack(true)
	var shot = Shot.new()
	world.add_child(shot)
	shot.configure(thrower,"swerve_shot",1,Layout.PLATFORMS)
	shot.position = Vector2(550,390)
	shot.velocity = Vector2(0,320)
	for frame in range(50):
		if shot.bounce_count > 0: break
		shot.tick(delta,target)
	check(shot.bounce_count == 1 and shot.position.y < 440, "ball bounces from a real platform top at delta="+str(delta))
	shot.position = Vector2(820,550)
	shot.velocity = Vector2(0,320)
	for frame in range(50):
		if shot.bounce_count > 1: break
		shot.tick(delta,target)
	check(shot.bounce_count == 2 and shot.position.y < 600, "ball bounces from the authoritative floor at delta="+str(delta))
	shot.position = Vector2(820,550)
	shot.velocity = Vector2(0,320)
	for frame in range(50):
		if shot.consumed: break
		shot.tick(delta,target)
	check(shot.consumed and shot.bounce_count == 2, "ball expires at third plane contact instead of bouncing forever")
	shot.queue_free()
	await clean([thrower,target])
	var hitter = spawn("custom_qa_bat",400)
	var attacker = spawn("custom_qa_ball",620)
	await settle(hitter,attacker)
	hitter.facing = 1
	check(hitter.start_attack(true),"bat prepares Home Run reflection")
	hitter.attack_time = float(hitter.attack_spec.windup)+0.01
	attacker.start_attack(true)
	shot = Shot.new()
	world.add_child(shot)
	shot.configure(attacker,"swerve_shot",-1,Layout.PLATFORMS)
	shot.position = hitter.position + Vector2(57,-80)
	shot.velocity = Vector2(-420,0)
	check(not shot.tick(delta,hitter) and shot.owner_fighter == hitter and shot.reflection_count == 1 and hitter.home_run_reflected and hitter.health == 100,
		"Home Run returns one incoming ball in its narrow active window at delta="+str(delta))
	check(not shot.reflect_from(attacker),"a returned projectile cannot reflect twice")
	var followup = ExistingShot.new()
	world.add_child(followup)
	followup.configure(attacker,"arrow",-1)
	check(hitter.take_hit(12,-1,310.0,-245.0,followup) and hitter.health == 88 and followup.reflection_count == 0,
		"Home Run reflects only one shot during one cast")
	followup.queue_free()
	shot.position = attacker.position + Vector2(-60,-80)
	shot.velocity = Vector2(420,0)
	shot.tick(delta,attacker)
	check(attacker.health == attacker.max_health-shot.damage and attacker.last_hit_source == shot and hitter.total_damage == shot.damage,
		"reflected ball retains new ownership and damage attribution")
	shot.cleanup()
	shot.queue_free()
	await clean([hitter,attacker])

func test_elevated_ground_specials(delta: float) -> void:
	for pairing in [["rubber_chicken","cluckquake",760.0,22], ["giant_crayon","rainbow_ruckus",840.0,22]]:
		var kit: String = pairing[0]
		var special_kind: String = pairing[1]
		var target_x: float = pairing[2]
		var expected_damage: int = pairing[3]
		var attacker = spawn("custom_qa_"+kit,640.0,440.0)
		var target = spawn("red",target_x,440.0)
		attacker.start_attack(true)
		var shot = Shot.new()
		world.add_child(shot)
		shot.configure(attacker,special_kind,1,Layout.PLATFORMS)
		check(is_equal_approx(shot.position.y,440.0),kit+" special anchors to the platform below its caster")
		var hits := 0
		for frame in range(ceili(0.55/delta)):
			await physics_frame
			target.invulnerable = 0
			var before: int = target.health
			shot.tick(delta,target)
			if target.health < before: hits += 1
		check(hits == 1 and target.health == 100-expected_damage,kit+" special damages an opponent on the same elevated platform")
		shot.cleanup()
		shot.queue_free()
		await clean([attacker,target])

func test_ai() -> void:
	for kit in KINDS:
		for difficulty in range(3):
			var a = spawn("custom_qa_"+kit,400)
			var enemy_x := 565 if kit == "rubber_chicken" else 660 if kit in ["pixel_pick","bone","ball"] else 680 if kit == "giant_crayon" else 605
			var b = spawn("red",enemy_x)
			await settle(a,b)
			var ai = AI.new()
			ai.configure(difficulty)
			ai.reset()
			ai.rest_time = 0
			ai.think_time = 0
			var tell: Dictionary = ai.read_input(0.02,a,b)
			check(ai.tell_time > 0 and not bool(tell.special),kit+" AI telegraphs at difficulty "+str(difficulty))
			var release: Dictionary = ai.read_input(2.0,a,b)
			check(bool(release.special),kit+" AI selects its kit special at range at difficulty "+str(difficulty))
			await clean([a,b])

func _spawn_match_shot(fighter, kind: String, shots: Array) -> void:
	if not kind in ["ore_pop","fossil_fetch","swerve_shot","cluckquake","rainbow_ruckus"]: return
	var projectile = Shot.new()
	world.add_child(projectile)
	projectile.configure(fighter,kind,fighter.facing,Layout.PLATFORMS)
	shots.append(projectile)

func test_bot_matches() -> void:
	var pairings := [["pixel_pick","bone"],["bone","bat"],["bat","ball"],["ball","rubber_chicken"],["rubber_chicken","giant_crayon"],["giant_crayon","pixel_pick"]]
	for difficulty in range(3):
		for pairing in pairings:
			var a = spawn("custom_qa_"+pairing[0],420)
			var b = spawn("custom_qa_"+pairing[1],750)
			await settle(a,b)
			var ai_a = AI.new()
			var ai_b = AI.new()
			ai_a.configure(difficulty)
			ai_b.configure(difficulty)
			ai_a.configure_difficulty(difficulty)
			ai_b.configure_difficulty(difficulty)
			ai_a.reset()
			ai_b.reset()
			ai_a.rng.seed = 711 + difficulty
			ai_b.rng.seed = 933 + difficulty
			var attacks_a := [0,0]
			var attacks_b := [0,0]
			var hits := [0]
			a.attacked.connect(func(_fighter,special): attacks_a[1 if special else 0] += 1)
			b.attacked.connect(func(_fighter,special): attacks_b[1 if special else 0] += 1)
			a.damaged.connect(func(_fighter,_amount,_direction): hits[0] += 1)
			b.damaged.connect(func(_fighter,_amount,_direction): hits[0] += 1)
			var shots: Array = []
			a.released.connect(_spawn_match_shot.bind(shots))
			b.released.connect(_spawn_match_shot.bind(shots))
			for frame in range(900):
				await physics_frame
				a.tick(1.0/60.0,ai_a.read_input(1.0/60.0,a,b),b)
				b.tick(1.0/60.0,ai_b.read_input(1.0/60.0,b,a),a)
				a.try_hit(b)
				b.try_hit(a)
				for shot in shots.duplicate():
					var target = b if shot.owner_fighter == a else a
					if shot.tick(1.0/60.0,target):
						shot.cleanup()
						shots.erase(shot)
						shot.queue_free()
				# Keep both opponents in the training loop after a near knockout.
				if a.health < 30: a.health = a.max_health
				if b.health < 30: b.health = b.max_health
			check(attacks_a[0]+attacks_a[1] > 0 and attacks_b[0]+attacks_b[1] > 0,
				"both bots attack in "+str(pairing)+" at difficulty "+str(difficulty))
			check(attacks_a[1]+attacks_b[1] > 0,
				"bot pair casts a kit special in "+str(pairing)+" at difficulty "+str(difficulty)+" counts="+str(attacks_a)+"/"+str(attacks_b))
			check(hits[0] > 0,"bot pair lands physical damage in "+str(pairing)+" at difficulty "+str(difficulty))
			for shot in shots: shot.queue_free()
			await clean([a,b])
