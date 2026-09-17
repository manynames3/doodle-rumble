extends SceneTree
## Run: Godot --headless --path game --script res://tests/test_core.gd
## Uses real CharacterBody2D collisions; rendering is not needed.
var Fighter: GDScript
const Rules = preload("res://scripts/match_rules.gd")
const DT = 1.0 / 60.0
var world: Node2D
var checks = 0
var failures: Array[String] = []
var release_counts: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func spawn(id: String, slot: int, at: Vector2):
	var fighter = Fighter.new()
	world.add_child(fighter)
	fighter.setup(id,slot,true)
	fighter.reset_at(at)
	return fighter

func physics_tick(a, b, command: Dictionary = {}, delta: float = DT) -> void:
	await physics_frame
	a.tick(delta,command,b)
	b.tick(delta,{},a)

func settle(a, b) -> void:
	for i in range(5):
		await physics_tick(a,b)

func clean(a, b) -> void:
	a.queue_free()
	b.queue_free()
	await process_frame

func run() -> void:
	await process_frame # Data autoload reads weapon and character dictionaries.
	Fighter = load("res://scripts/fighter.gd")
	if not Fighter.can_instantiate():
		push_error("Core fighter failed to compile")
		quit(1)
		return
	world = Node2D.new()
	root.add_child(world)
	var floor_body = StaticBody2D.new()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(1280,100)
	collider.shape = shape
	floor_body.add_child(collider)
	floor_body.position = Vector2(640,650)
	world.add_child(floor_body)
	await physics_frame
	await test_motion()
	await test_attacks()
	await test_specials()
	await test_recovery()
	test_rounds()
	world.queue_free()
	await process_frame
	print("CORE_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		print("  " + failure)
	quit(0 if failures.is_empty() else 1)

func test_motion() -> void:
	var a = spawn("orange",1,Vector2(300,599))
	var b = spawn("red",2,Vector2(1000,599))
	await settle(a,b)
	check(a.is_on_floor(),"fighter lands on actual static floor")
	var start_x = a.position.x
	for i in range(30):
		await physics_tick(a,b,{"move":1.0})
	check(a.position.x > start_x + 100,"right movement covers useful distance")
	var ground_y = a.position.y
	await physics_tick(a,b,{"jump":true})
	for i in range(8):
		await physics_tick(a,b)
	check(a.position.y < ground_y - 50 and not a.is_on_floor(),"jump leaves floor")
	for i in range(60):
		await physics_tick(a,b)
	check(a.is_on_floor(),"jump returns to safe floor")
	a.reset_at(Vector2(80,599))
	for i in range(20):
		await physics_tick(a,b,{"move":-1.0})
	check(is_equal_approx(a.position.x,78),"left boundary clamps player")
	a.reset_at(Vector2(1200,599))
	for i in range(20):
		await physics_tick(a,b,{"move":1.0})
	check(is_equal_approx(a.position.x,1202),"right boundary clamps player")
	a.reset_at(Vector2(200,850))
	await physics_tick(a,b)
	check(a.position.y <= 600,"defensive out-of-arena recovery works")
	await clean(a,b)
	print("PASS group: movement, jumping, floor, boundaries")

func test_attacks() -> void:
	# Force victims' immunity off between hit attempts to prove per-swing deduplication.
	# Sample identical full attack sequences with 30/60/120 Hz simulation deltas.
	for id in ["orange","red","green","blue"]:
		var totals: Array[int] = []
		for delta in [1.0/30.0, 1.0/60.0, 1.0/120.0]:
			var a = spawn(id,1,Vector2(400,599))
			var b = spawn("orange",2,Vector2(480,599))
			await settle(a,b)
			var expected = int(a.weapon.damage)
			check(a.start_attack(false),id + " can start basic attack")
			var hit_count = 0
			var steps = ceili((a.duration()+delta*2.0)/delta)
			for i in range(steps):
				await physics_frame
				a.tick(delta,{},b)
				a.position = Vector2(400,599)
				b.position = Vector2(480,599)
				b.invulnerable = 0
				if a.try_hit(b): hit_count += 1
			check(hit_count == 1,id + " basic connects exactly once at delta=" + str(delta))
			check(b.health == 100-expected,id + " basic applies weapon damage")
			check(a.attack_time < 0,id + " basic recovers to idle")
			totals.append(100-b.health)
			await clean(a,b)
		check(totals[0] == totals[1] and totals[1] == totals[2],id + " damage invariant at 30/60/120 Hz")
	print("PASS group: all four basic attacks, duplicate-hit prevention, delta invariance")

func test_specials() -> void:
	for id in ["orange","red","green","blue"]:
		var a = spawn(id,1,Vector2(400,599))
		var b = spawn("orange",2,Vector2(480,599))
		await settle(a,b)
		release_counts[id] = 0
		a.released.connect(func(_fighter, _kind): release_counts[id] += 1)
		check(a.start_attack(true),id + " special starts")
		check(a.cooldown > 5.9,id + " special starts six-second cooldown")
		var saw_dash = false
		var hit_count = 0
		for i in range(70):
			await physics_tick(a,b)
			if a.is_active():
				if id == "green": saw_dash = saw_dash or absf(a.velocity.x) >= 750
				if id == "orange": b.position = a.position + Vector2(-90,0)
				if a.try_hit(b): hit_count += 1
		check(release_counts[id] == 1,id + " releases special exactly once")
		check(not a.start_attack(true),id + " cannot reuse special during cooldown")
		if id == "orange": check(hit_count == 1,"Orange spin hits behind the fighter once")
		if id == "green": check(saw_dash,"Green dash produces fast forward motion")
		if id in ["red","blue"]: check(hit_count == 0,id + " delegates special hitbox to projectile event")
		# A long isolated timer step verifies expiry without spending six real seconds per fighter.
		await physics_tick(a,b,{},6.01)
		check(is_zero_approx(a.cooldown),id + " cooldown expires")
		check(a.start_attack(true),id + " can use special after cooldown")
		await clean(a,b)
	print("PASS group: four specials, release events, cooldown and reuse")

func test_recovery() -> void:
	var a = spawn("orange",1,Vector2(400,599))
	var b = spawn("red",2,Vector2(900,599))
	await settle(a,b)
	check(a.start_attack(false),"recovery setup starts attack")
	check(a.take_hit(20,1,350),"fresh damage applies")
	check(a.attack_time < 0,"taking damage cancels attack")
	check(not a.start_attack(false),"hurt state blocks attack")
	check(not a.take_hit(20,1,350),"repeated damage blocked by immunity")
	check(a.health == 80,"blocked damage does not reduce health")
	for i in range(14):
		await physics_tick(a,b,{"move":-1.0})
	check(a.hurt_time <= 0 and a.invulnerable > 0,"protection outlasts hit stun")
	var recovery_x = a.position.x
	for i in range(12):
		await physics_tick(a,b,{"move":-1.0})
	check(a.position.x < recovery_x-15,"player regains movement during immunity to escape")
	check(not a.take_hit(20,1,350),"damage still blocked during recovery escape window")
	for i in range(24):
		await physics_tick(a,b)
	check(a.take_hit(20,1,350),"damage can apply again after protection expires")
	a.take_hit(500,1,350) # immunity intentionally rejects this attempt.
	a.invulnerable = 0
	check(a.take_hit(500,1,350) and a.health == 0,"lethal damage clamps health at zero")
	check(not a.start_attack(false) and not a.take_hit(10,1,350),"defeated fighters cannot attack or receive repeated damage")
	a.reset_at(Vector2(400,599))
	check(a.health == 100 and a.invulnerable == 0 and a.attack_time < 0 and a.cooldown == 0,"rematch restores health and combat timers")
	await clean(a,b)
	print("PASS group: hit stun, immunity, escape, knockout and reset")

func test_rounds() -> void:
	var rules = Rules.new()
	check(rules.remaining == 60 and rules.scores == [0,0],"fresh match starts at 60 seconds and zero score")
	check(not rules.tick(1.0,100,100) and rules.remaining == 59,"healthy round counts time")
	check(rules.tick(DT,100,0),"KO ends round")
	check(rules.scores == [1,0] and not rules.finished,"first KO awards one win")
	rules.next_round()
	check(rules.remaining == 60 and rules.round_number == 2,"next round resets timer and advances number")
	check(rules.tick(60,30,55) and rules.last_winner == 1,"timeout awards higher health")
	check(rules.scores == [1,1] and not rules.finished,"one win each requires third round")
	rules.next_round()
	check(rules.tick(DT,100,0) and rules.finished,"second win finishes best-of-three")
	var final_scores = rules.scores.duplicate()
	check(not rules.tick(60,0,100) and rules.scores == final_scores,"completed match ignores later ticks")
	rules.reset()
	check(not rules.finished and rules.scores == [0,0] and rules.remaining == 60 and rules.round_number == 1,"immediate rematch fully resets scoring")
	check(rules.tick(60,50,50) and rules.last_winner == -1 and rules.scores == [0,0],"timeout tie awards neither player")
	rules.next_round()
	check(rules.tick(DT,0,0) and rules.scores == [0,0],"double knockout tie awards neither player")
	print("PASS group: timer, KOs, ties, best-of-three, rematch")
