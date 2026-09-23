extends SceneTree
const Catalog = preload("res://scripts/arena_catalog.gd")
const Layout = preload("res://scripts/arena_layout.gd")
const Ladder = preload("res://scripts/solo_ladder.gd")
const Hazards = preload("res://scripts/hazards.gd")
var checks = 0
var failures = 0

class Target:
	extends RefCounted
	var definition = {"id":"orange"}
	var slot = 0
	var position = Vector2(640,599)
	var hits = 0
	var damage = 0
	func hurtbox() -> Rect2: return Rect2(position - Vector2(20,100),Vector2(40,100))
	func take_hit(amount: int, _direction: int, _force: float) -> void:
		hits += 1
		damage += amount

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	check(Catalog.ORDER.size() == 6,"Six selectable arenas")
	var expected = ["desktop","quarry","canopy","arcade","network","glitch"]
	for i in range(6):
		check(Ladder.stage(i).arena == expected[i],"Story arena progression " + str(i))
	for kind in Catalog.ORDER:
		check(ResourceLoader.exists("res://assets/arenas/" + kind + "_v2.png"),kind + " painted background is included")
		for hazard in Catalog.hazard_cycle(kind): check(Hazards.TYPES.has(hazard),kind + " hazard has a real implementation")
		var platforms = Layout.get_platforms(kind)
		# Repeated graph expansion covers platforms whose usable approach comes later in the list.
		var reachable: Array = []
		for pass_index in range(platforms.size()):
			for index in range(platforms.size()):
				var rect: Rect2 = platforms[index]
				var can_reach = rect.position.y >= 410
				for prior_index in reachable:
					var prior: Rect2 = platforms[prior_index]
					if rect.position.y >= prior.position.y - 190 and rect.position.x <= prior.end.x + 260 and rect.end.x >= prior.position.x - 260: can_reach = true
				if can_reach and not reachable.has(index): reachable.append(index)
		check(reachable.size() == platforms.size(),kind + " normal-jump platform route")
	for kind in ["paper_swarm","pixel_pinball","circuit_zip"]:
		for fps in [30,60,120]:
			var node = Hazards.new()
			var target = Target.new()
			node.mark_target(640,0,kind)
			var tell: float = Hazards.TYPES[kind].tell
			node.tick(tell - 0.05,[target])
			check(target.hits == 0,kind + " cannot hit before its warning finishes")
			for frame in range(fps * 2): node.tick(1.0/fps,[target])
			check(target.hits == 1 and target.damage == Hazards.TYPES[kind].damage,kind + " single fixed-time hit at " + str(fps))
			check(node.marks.is_empty(),kind + " clears after its active window")
			node.free()
	var queue_test = Hazards.new()
	var target = Target.new()
	queue_test.mark_target(640,0,"ink_geyser")
	queue_test.mark_target(640,0,"dark_rift","dark_lord")
	check(queue_test.marks.size()==1 and queue_test.pending.size()==1,"Boss signature queues behind a stage hazard")
	queue_test.tick(2.1,[])
	check(queue_test.marks.size()==1 and queue_test.marks[0].kind=="dark_rift" and queue_test.marks[0].age==0,"Queued signature starts with a fresh warning")
	queue_test.tick(1.14,[target])
	check(target.hits==0,"Queued boss warning never deals early damage")
	queue_test.tick(0.02,[target])
	check(target.hits==1 and target.damage==30,"Queued empowered boss signature still hits once")
	queue_test.mark_target(640,0,"camera","dark_lord")
	queue_test.clear()
	check(queue_test.marks.is_empty() and queue_test.pending.is_empty(),"Round reset clears active and queued hazards")
	queue_test.free()
	var art = load("res://scripts/arena_art.gd").new()
	root.add_child(art)
	art.reduced_motion = true
	art._process(1.0)
	check(art.elapsed == 0,"Reduced motion stops scenery animation")
	art.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("TEST_RESULT checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
