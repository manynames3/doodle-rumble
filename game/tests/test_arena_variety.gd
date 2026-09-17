extends SceneTree
## Run against an isolated project copy: Godot --headless --path copy --script res://tests/test_arena_variety.gd
const Layout = preload("res://scripts/arena_layout.gd")
const Interactions = preload("res://scripts/arena_interactions.gd")
var Fighter: GDScript
const DT = 1.0/60.0
var checks = 0
var failures: Array[String] = []
var world: Node2D
var bodies: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: "+message)

func _add_body(rect: Rect2, one_way: bool) -> StaticBody2D:
	var body = StaticBody2D.new()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	collider.one_way_collision = one_way
	body.add_child(collider)
	body.position = rect.get_center()
	world.add_child(body)
	return body

func _arena(kind: String, large_boss: bool = false) -> void:
	if is_instance_valid(world):
		world.queue_free()
		await process_frame
	world = Node2D.new()
	root.add_child(world)
	bodies = []
	_add_body(Layout.FLOOR,false)
	for rect in Layout.get_platforms(kind,large_boss):
		bodies.append(_add_body(rect,true))
	await physics_frame

func _fighter(id: String, x: float, y: float):
	var fighter = Fighter.new()
	world.add_child(fighter)
	fighter.setup(id,1,true)
	fighter.reset_at(Vector2(x,y))
	return fighter

func _step(controller, a, b, command: Dictionary = {}) -> void:
	await physics_frame
	var commands = controller.begin_tick(DT,[a,b],[command,{}])
	a.tick(DT,commands[0],b)
	b.tick(DT,commands[1],a)
	controller.end_tick(DT,[a,b])

func run() -> void:
	await process_frame
	var ArenaArt = load("res://scripts/arena_art.gd")
	check(ArenaArt.can_instantiate(),"illustrated arena renderer compiles")
	Fighter = load("res://scripts/fighter.gd")
	if not Fighter.can_instantiate():
		push_error("Fighter failed to compile")
		quit(1)
		return
	var desktop = Layout.get_platforms("desktop")
	var quarry = Layout.get_platforms("quarry")
	var glitch = Layout.get_platforms("glitch")
	check(desktop.size() == 3 and quarry.size() == 4 and glitch.size() == 4,"three arenas have distinct platform counts")
	check(desktop != quarry and quarry != glitch and desktop != glitch,"platform collision routes differ between arenas")
	check(Layout.get_platforms("glitch",true).size() == 3,"final boss arena retains three retreat ledges")
	check(Layout.get_platforms("glitch",true) != glitch,"final boss retreat route has its own silhouette")
	for kind in ["desktop","quarry","glitch"]:
		await _arena(kind)
		var platforms = Layout.get_platforms(kind)
		for i in range(platforms.size()):
			var collision: CollisionShape2D = bodies[i].get_child(0)
			check(is_equal_approx(bodies[i].position.y-collision.shape.size.y/2,platforms[i].position.y),kind+" illustrated top equals collision top " + str(i))
			check(platforms[i].position.x >= 78 and platforms[i].end.x <= 1202 and platforms[i].position.y >= 300 and platforms[i].position.y <= 510,kind+" platform stays inside reachable play area " + str(i))
		var start_height = 600.0
		var reachable: Array[bool] = []
		for i in range(platforms.size()):
			var rect: Rect2 = platforms[i]
			var can_reach = rect.position.y >= start_height-190.0 and (rect.position.x <= 860+240 and rect.end.x >= 420-240)
			for j in range(i):
				var prior: Rect2 = platforms[j]
				if reachable[j] and rect.position.y >= prior.position.y-190 and rect.position.x <= prior.end.x+260 and rect.end.x >= prior.position.x-260:
					can_reach = true
			reachable.append(can_reach)
			check(can_reach,kind+" platform has a normal-jump route " + str(i))
		var jumper = _fighter("orange",640,599)
		var witness = _fighter("blue",1120,599)
		for i in range(5):
			await physics_frame
			jumper.tick(DT,{},witness)
			witness.tick(DT,{},jumper)
		await physics_frame
		jumper.tick(DT,{"jump":true},witness)
		witness.tick(DT,{},jumper)
		for i in range(90):
			await physics_frame
			jumper.tick(DT,{},witness)
			witness.tick(DT,{},jumper)
		check(jumper.is_on_floor() and jumper.position.y < 520,kind+" central ledge is reached by a real standing jump")
	await _arena("desktop")
	var c = Interactions.new()
	world.add_child(c)
	c.configure("desktop",bodies)
	var a = _fighter("orange",640,599)
	var b = _fighter("blue",950,599)
	for i in range(5): await _step(c,a,b)
	check(a.is_on_floor(),"spring pad starts on safe floor")
	await _step(c,a,b,{"jump":true})
	check(a.velocity.y <= Interactions.SPRING_SPEED+1,"eraser pad boosts only an intentional jump")
	c.reset()
	a.reset_at(Vector2(640,599))
	for i in range(5): await _step(c,a,b)
	await _step(c,a,b)
	check(a.velocity.y >= 0,"eraser pad never launches without jump input")
	await _arena("quarry")
	c = Interactions.new()
	world.add_child(c)
	c.configure("quarry",bodies)
	a = _fighter("orange",605,464)
	b = _fighter("blue",950,599)
	for i in range(41): await _step(c,a,b)
	check(c.bridge_gone > 0,"standing on loose stone visibly drops its bridge")
	await physics_frame
	check(bodies[Layout.QUARRY_BRIDGE_INDEX].get_child(0).disabled,"crumbling bridge also removes collision")
	for i in range(145): await _step(c,a,b)
	check(c.bridge_gone == 0 and not bodies[Layout.QUARRY_BRIDGE_INDEX].get_child(0).disabled,"bridge reforms after finite cooldown")
	check(a.health == a.max_health and a.position.y <= 600,"crumble returns fighter to safe floor without damage")
	await _arena("glitch")
	c = Interactions.new()
	world.add_child(c)
	c.configure("glitch",bodies)
	a = _fighter("orange",200,599)
	b = _fighter("blue",1080,599)
	for i in range(5): await _step(c,a,b)
	await _step(c,a,b,{"jump":true})
	check(a.position.x > 900 and a.position.distance_to(b.position)>96,"explicit jump teleports to a safe unoccupied exit")
	var destination = a.position.x
	for i in range(20): await _step(c,a,b,{"jump":true})
	check(absf(a.position.x-destination)<2,"held jump and cooldown cannot create automatic teleport loops")
	check(a.is_on_floor() and absf(a.position.y-599)<2,"teleport consumes the held jump until release")
	check(c.teleport_cooldown[0] > 0 and c.teleport_cooldown[0] < Interactions.TELEPORT_COOLDOWN,"teleport cooldown advances in physics ticks")
	c.reset()
	check(c.teleport_cooldown[0] == 0 and c.jump_was_down == [false,false],"round reset clears interaction state")
	for locked_state in ["attack","hurt","dodge","defeated"]:
		c.reset()
		a.reset_at(Vector2(200,599))
		for i in range(5): await _step(c,a,b)
		match locked_state:
			"attack": a.start_attack(false)
			"hurt": a.hurt_time = 0.4
			"dodge": a.dodge_time = 0.0
			"defeated": a.health = 0
		await _step(c,a,b,{"jump":true})
		check(a.position.x < 300 and c.teleport_cooldown[0] == 0,locked_state+" cannot cancel into teleport")
	await _arena("glitch",true)
	check(bodies.size() == 3,"large boss collision matches its three drawn ledges")
	for body in bodies:
		check(body.get_child(0).one_way_collision,"boss retreat ledges do not block floor movement")
	var boss_route = Layout.get_platforms("glitch",true)
	check(boss_route[0].position.y >= 410 and boss_route[2].position.y >= 410 and boss_route[1].position.y >= boss_route[0].position.y-190 and boss_route[1].position.x <= boss_route[0].end.x+260,"boss retreat platforms form a reachable floor-to-center route")
	c = Interactions.new()
	world.add_child(c)
	c.configure("glitch",bodies,true)
	a = _fighter("orange",200,599)
	b = _fighter("blue",1060,599)
	for i in range(5): await _step(c,a,b)
	await _step(c,a,b,{"jump":true})
	check(a.position.x < 300 and c.teleport_cooldown[0] == 0,"boss portal art and teleport both stay inactive")
	for i in range(90): await _step(c,a,b)
	check(a.is_on_floor() and absf(a.position.y-boss_route[0].position.y)<4,"player reaches boss retreat ledge with an ordinary jump")
	world.queue_free()
	await process_frame
	print("ARENA_VARIETY_TEST_RESULT checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("  "+failure)
	quit(0 if failures.is_empty() else 1)
