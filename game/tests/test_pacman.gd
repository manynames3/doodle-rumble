extends SceneTree
## Pac-Man uses the shared combat rules; tests exercise his actual bite and rush.
const DT = 1.0 / 60.0
var Fighter: GDScript
var PacAI: GDScript
var world: Node2D
var checks = 0
var failures: Array[String] = []

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

func run() -> void:
	await process_frame
	Fighter = load("res://scripts/fighter.gd")
	PacAI = load("res://scripts/pacman_controller.gd")
	if not Fighter or not Fighter.can_instantiate() or not PacAI or not PacAI.can_instantiate():
		push_error("Pac-Man dependencies failed to compile")
		quit(1)
		return
	check(root.get_node("Data").fighter("pac_man").id == "pac_man","Pac-Man has his own opponent data")
	check(not "pac_man" in root.get_node("Data").ORDER,"boss does not replace any starting selectable fighter")
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
	await test_bite()
	await test_rush()
	await test_controller()
	world.queue_free()
	root.get_node("Sound").shutdown()
	await process_frame
	print("PACMAN_TEST_RESULT checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func test_bite() -> void:
	var damage_totals: Array[int] = []
	for delta in [1.0/30.0,1.0/60.0,1.0/120.0]:
		var pac = spawn("pac_man",2,Vector2(400,599))
		var player = spawn("orange",1,Vector2(480,599))
		pac.facing = 1
		check(pac.start_attack(false),"bite starts")
		check(not pac.try_hit(player),"bite cannot deal damage during windup")
		var hits = 0
		for frame in range(ceili((pac.duration()+0.1)/delta)):
			await physics_frame
			pac.tick(delta,{},player)
			pac.position = Vector2(400,599)
			player.position = Vector2(480,599)
			player.invulnerable = 0
			if pac.try_hit(player): hits += 1
		check(hits == 1,"one bite never reapplies damage within its active window")
		check(player.health == 100-int(pac.weapon.damage),"bite uses the actual chomp damage value")
		check(pac.attack_time < 0,"bite ends with control returned")
		damage_totals.append(100-player.health)
		pac.queue_free()
		player.queue_free()
		await process_frame
	check(damage_totals[0] == damage_totals[1] and damage_totals[1] == damage_totals[2],"bite damage is independent of render/simulation sampling rate")
	print("PASS group: Pac-Man bite windup, active window, recovery and single hit")

func test_rush() -> void:
	var pac = spawn("pac_man",2,Vector2(400,599))
	var player = spawn("orange",1,Vector2(540,599))
	pac.facing = 1
	check(pac.start_attack(true),"charged rush starts")
	var start_x = pac.position.x
	var hits = 0
	for frame in range(75):
		await physics_frame
		pac.tick(DT,{},player)
		player.tick(DT,{},pac)
		if pac.try_hit(player): hits += 1
	check(pac.position.x > start_x+100,"rush travels a useful distance through real physics")
	check(hits == 1 and player.health == 70,"rush connects once using shared special damage")
	check(not pac.start_attack(true),"rush cannot ignore its six-second cooldown")
	check(pac.attack_time < 0,"rush recovers instead of remaining a contact hazard")
	var hp = player.health
	for frame in range(20):
		await physics_frame
		pac.position = player.position
		pac.tick(DT,{},player)
		pac.try_hit(player)
	check(player.health == hp,"touching idle Pac-Man never deals unavoidable contact damage")
	pac.queue_free()
	player.queue_free()
	await process_frame
	print("PASS group: Pac-Man rush, cooldown, escape and no idle contact damage")

func test_controller() -> void:
	var pac = spawn("pac_man",2,Vector2(400,599))
	var player = spawn("orange",1,Vector2(485,599))
	var controller = PacAI.new()
	controller.reset()
	var warned_for = 0.0
	var bites = 0
	var rushes = 0
	var unsafe_release = false
	var rest_frames = 0
	for frame in range(1800):
		await physics_frame
		var previous_tell = controller.tell
		var command = controller.read_input(DT,pac,player)
		if previous_tell != "" or controller.tell != "": warned_for += DT
		if command.get("attack",false) or command.get("special",false):
			unsafe_release = unsafe_release or warned_for < (0.60 if command.get("special",false) else 0.30)
			if command.get("special",false): rushes += 1
			else: bites += 1
			warned_for = 0
		elif controller.tell == "" and absf(float(command.get("move",0.0))) < 0.01:
			rest_frames += 1
		pac.tick(DT,command,player)
		player.tick(DT,{},pac)
		# Keep opponents in range to measure decision timing, not chase distance.
		pac.position = Vector2(400,599)
		player.position = Vector2(485,599)
	check(bites >= 2,"Pac-Man repeatedly uses normal bites")
	check(rushes >= 2,"Pac-Man mixes charged rushes into the fight")
	check(not unsafe_release,"every controller attack has a visible warning before release")
	check(rest_frames >= 90,"the controller leaves recovery windows for retaliation")
	controller.reset()
	check(controller.tell == "","reset clears stale warning text")
	pac.queue_free()
	player.queue_free()
	await process_frame
	print("PASS group: Pac-Man pattern variety, readable warnings and retaliation windows")
