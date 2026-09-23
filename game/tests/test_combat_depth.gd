extends SceneTree
## Run on a QA copy: Godot --headless --fixed-fps 60 --path game --script res://tests/test_combat_depth.gd
var Fighter: GDScript
const IDS = ["orange", "red", "green", "blue", "purple", "yellow"]
const AIR_KINDS = ["fork_sweep", "hammer_drop", "diagonal_slash", "pick_uppercut", "aimed_arrow", "staff_drop"]
const AIR_DAMAGE = [10, 22, 11, 15, 12, 13]
const DT = 1.0 / 60.0
var world: Node2D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)

func spawn(id: String, x: float = 500.0, y: float = 599.0):
	var fighter = Fighter.new()
	world.add_child(fighter)
	fighter.setup(id, 1, true)
	fighter.reset_at(Vector2(x,y))
	return fighter

func step(a, b, command: Dictionary = {}, delta: float = DT) -> void:
	await physics_frame
	a.tick(delta,command,b)
	b.tick(delta,{},a)

func settle(a, b) -> void:
	for frame in range(5):
		await step(a,b)

func clean(a, b) -> void:
	a.queue_free()
	b.queue_free()
	await process_frame

func run() -> void:
	await process_frame
	Fighter = load("res://scripts/fighter.gd")
	check(Fighter != null and Fighter.can_instantiate(), "combat fighter script compiles")
	if Fighter == null or not Fighter.can_instantiate():
		quit(1)
		return
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
	await test_dodge_access_and_input()
	await test_precise_evade_rates()
	await test_cancels_and_counter()
	await test_projectile_counter_and_protected_contact()
	await test_purple_directional_guard()
	await test_purple_projectile_reflection()
	await test_grounded_fighter_tradeoffs()
	await test_damage_attribution_at_signal_time()
	await test_ai_purple_guard_read()
	await test_air_basics()
	await test_air_damage_rates()
	world.queue_free()
	await process_frame
	print("COMBAT_DEPTH_TEST_RESULT checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("  " + failure)
	quit(0 if failures.is_empty() else 1)

func test_dodge_access_and_input() -> void:
	for id in IDS:
		var a = spawn(id,500)
		var b = spawn("red",800)
		await settle(a,b)
		var started: Array[int] = [0]
		a.dodge_started.connect(func(_fighter): started[0] += 1)
		await step(a,b,{"dodge":true})
		check(a.dodge_time >= 0 and a.dodge_direction == -1, id + " dodges away from opponent without movement input")
		check(a.dodge_cooldown > 1.0 and started[0] == 1, id + " starts one finite sidestep and cooldown")
		check(not a.start_attack(false) and not a.start_attack(true), id + " cannot attack through committed dodge")
		var start_x: float = a.position.x
		for frame in range(22):
			await step(a,b,{"dodge":true,"move":1.0,"attack":true,"jump":true})
		check(a.position.x < start_x - 95 and a.dodge_time < 0, id + " remains committed despite reverse, attack, and jump inputs")
		for frame in range(60): await step(a,b,{"dodge":true})
		check(a.dodge_cooldown == 0 and started[0] == 1, id + " held dodge does not auto-repeat after cooldown")
		await step(a,b)
		await step(a,b,{"dodge":true,"move":1.0})
		check(a.dodge_direction == 1 and started[0] == 2, id + " fresh press follows explicit direction")
		await clean(a,b)
	for id in ["pac_man", "h4ck3r", "dark_lord"]:
		var boss = spawn(id)
		var player = spawn("orange",800)
		await settle(boss,player)
		await step(boss,player,{"dodge":true})
		check(boss.dodge_time < 0 and boss.dodge_cooldown == 0 and not boss.start_dodge(-1,player), id + " cannot use player dodge")
		await clean(boss,player)
	print("PASS group: six player dodges, direction, committed motion, edge trigger, boss exclusion")

func test_precise_evade_rates() -> void:
	for delta in [1.0/30.0, 1.0/60.0, 1.0/120.0]:
		var early = spawn("orange")
		var other = spawn("red",800)
		await settle(early,other)
		check(early.start_dodge(-1,other), "dodge starts for early-window test")
		check(early.take_hit(9,1) and early.health == 91 and early.counter_time == 0, "dodge windup remains punishable at delta="+str(delta))
		check(early.dodge_time < 0 and early.invulnerable > 0, "real hit cancels dodge and keeps normal victim protection")
		await clean(early,other)
		var a = spawn("orange")
		var b = spawn("red",800)
		await settle(a,b)
		var perfects: Array[int] = [0]
		a.perfect_dodged.connect(func(_fighter): perfects[0] += 1)
		a.start_dodge(-1,b)
		while a.dodge_time < 0.09:
			await step(a,b,{},delta)
		check(a.dodge_invulnerable(), "precise evade window is reachable at delta="+str(delta))
		check(not a.take_hit(9,1) and a.health == 100 and perfects[0] == 1, "actual contact inside window perfect-dodges at delta="+str(delta))
		check(not a.take_hit(9,1) and perfects[0] == 1, "second contact in same dodge cannot farm perfect rewards")
		check(a.counter_time > 2.3 and not a.start_dodge(-1,b), "perfect earns one timed counter without resetting dodge cooldown")
		while a.dodge_time < 0.23:
			await step(a,b,{},delta)
		check(not a.dodge_invulnerable() and a.take_hit(9,1), "dodge recovery is punishable at delta="+str(delta))
		check(a.health == 91 and a.counter_time == 0 and a.hurt_time > 0, "recovery hit removes counter and enters fixed hit stun")
		check(not a.take_hit(9,1) and a.health == 91, "ordinary 0.68-second recovery protection still prevents repeated hits")
		await clean(a,b)
	print("PASS group: real-contact perfect dodge, finite evade window and vulnerable recovery at 30/60/120 Hz")

func test_cancels_and_counter() -> void:
	var a = spawn("orange")
	var b = spawn("red",800)
	await settle(a,b)
	check(a.start_attack(false), "basic begins for cancel test")
	check(not a.start_dodge(-1,b), "dodge cannot cancel attack windup")
	while a.attack_time < float(a.attack_spec.windup) + float(a.attack_spec.active) + 0.02:
		await step(a,b)
	check(a.attack_time >= 0 and not a.start_dodge(-1,b), "dodge cannot cancel attack recovery")
	while a.attack_time >= 0: await step(a,b)
	check(a.start_dodge(-1,b), "dodge can start once attack fully recovers")
	while a.dodge_time < 0.09: await step(a,b)
	check(not a.take_hit(12,1) and a.counter_time > 0, "one dodge contact earns counter")
	while a.dodge_time >= 0: await step(a,b)
	check(a.start_attack(true), "special can begin while counter is available")
	check(not bool(a.attack_spec.get("counter",false)) and int(a.attack_spec.damage) == 22 and a.counter_time > 0, "special retains base damage and does not consume basic counter")
	while a.attack_time >= 0: await step(a,b)
	check(a.start_attack(false), "next basic can spend counter")
	check(int(a.attack_spec.damage) == 17 and bool(a.attack_spec.get("counter",false)) and a.counter_time == 0, "counter boosts only next basic by rounded 25 percent")
	b.position = a.position + Vector2(90,0)
	var hit_count := 0
	for frame in range(50):
		await physics_frame
		a.tick(DT,{},b)
		b.position = a.position + Vector2(90,0)
		b.invulnerable = 0
		if a.try_hit(b): hit_count += 1
	check(hit_count == 1 and b.health == 83 and a.total_damage == 17, "boosted basic deals one authoritative hit")
	await clean(a,b)
	var expired = spawn("blue")
	var opponent = spawn("red",800)
	await settle(expired,opponent)
	expired.start_dodge(-1,opponent)
	while expired.dodge_time < 0.09: await step(expired,opponent)
	expired.take_hit(10,1)
	for frame in range(160): await step(expired,opponent)
	check(expired.counter_time == 0 and expired.start_attack(false), "unused counter expires in finite time")
	check(int(expired.attack_spec.damage) == int(expired.weapon.damage), "expired basic has normal damage")
	await clean(expired,opponent)
	print("PASS group: no recovery cancel, special exclusion, one-hit counter damage and expiry")

func test_projectile_counter_and_protected_contact() -> void:
	var fresh = spawn("red")
	check(fresh.airborne_time == 0 and fresh.start_attack(false) and not fresh.attack_spec.has("air_kind"), "fresh grounded spawn cannot receive an air variant before first collision tick")
	fresh.queue_free()
	await process_frame
	var a = spawn("purple")
	var b = spawn("red",800)
	await settle(a,b)
	a.invulnerable = 0.68
	check(a.start_dodge(-1,b), "Purple can start dodge during existing victim protection")
	while a.dodge_time < 0.09: await step(a,b)
	check(not a.take_hit(12,-1) and not a.dodge_perfected and a.counter_time == 0, "already protected hit cannot create a false perfect dodge")
	a.invulnerable = 0
	check(not a.take_hit(12,-1) and a.dodge_perfected and a.counter_time > 0, "new front contact creates one Purple counter")
	while a.dodge_time >= 0: await step(a,b)
	check(a.start_attack(false), "Purple can fire rewarded basic after evade recovery")
	check(int(a.attack_spec.projectile_damage) == 15 and bool(a.attack_spec.counter) and a.counter_time == 0, "Purple counter travels in arrow projectile damage data")
	while not a.is_active(): await step(a,b)
	check(not a.hitbox().has_area(), "counter arrow still has no melee damage box")
	await clean(a,b)
	print("PASS group: fresh grounded data, existing protection, Purple counter projectile payload")

func test_purple_directional_guard() -> void:
	for delta in [1.0/30.0,1.0/60.0,1.0/120.0]:
		var purple = spawn("purple",500)
		var red = spawn("red",590)
		await settle(purple,red)
		check(purple.facing == 1 and red.facing == -1, "opponents face across the guard test")
		check(purple.start_dodge(-1,red), "Purple starts existing dodge input as shield")
		while purple.dodge_time < 0.09: await step(purple,red,{},delta)
		red.position = purple.position + Vector2(90,0)
		red.facing = -1
		check(red.start_attack(false), "Red begins a real melee swing into Purple's face")
		red.attack_time = float(red.attack_spec.windup)
		var guard_events: Array[bool] = []
		purple.guarded.connect(func(_fighter,reflected): guard_events.append(reflected))
		check(not red.try_hit(purple) and purple.health == 100 and purple.counter_time > 0, "front melee is blocked and rewards a counter at delta="+str(delta))
		check(guard_events == [false] and red.total_damage == 0, "guard emits blocked contact without damage or projectile reflection")
		check(not red.try_hit(purple) and guard_events.size() == 1, "one melee attack cannot generate repeated guard contacts")
		while purple.dodge_time < 0.23: await step(purple,red,{},delta)
		check(purple.take_hit(9,-1) and purple.health == 91 and purple.counter_time == 0, "shield recovery is punishable and clears counter at delta="+str(delta))
		check(not purple.take_hit(9,-1) and purple.health == 91, "normal post-hit protection remains active after guard recovery")
		await clean(purple,red)
		var rear = spawn("purple",500)
		var backstabber = spawn("green",350)
		await settle(rear,backstabber)
		rear.facing = 1
		rear.start_dodge(1,backstabber)
		while rear.dodge_time < 0.09: await step(rear,backstabber,{},delta)
		rear.facing = 1 # Fixed facing for the flank test; a lock-facing input has the same effect.
		check(rear.take_hit(12,1) and rear.health == 88 and rear.counter_time == 0, "Purple shield cannot defend from behind at delta="+str(delta))
		await clean(rear,backstabber)
	print("PASS group: Purple front melee guard, one counter, rear vulnerability, recovery at 30/60/120 Hz")

func test_purple_projectile_reflection() -> void:
	for data in [{"kind":"arrow","caster":"purple","script":"attack_effect.gd","damage":12},
			{"kind":"signal","caster":"h4ck3r","script":"attack_effect.gd","damage":33},
			{"kind":"void_orb","caster":"dark_lord","script":"boss_projectile.gd","damage":36},
			{"kind":"pellet_fan","caster":"pac_man","script":"boss_projectile.gd","damage":18}]:
		for delta in [1.0/30.0,1.0/60.0,1.0/120.0]:
			var purple = spawn("purple",500)
			var caster = spawn(str(data.caster),300)
			await settle(purple,caster)
			purple.facing = -1
			check(purple.start_dodge(1,caster), "Purple starts shield against "+str(data.kind))
			while purple.dodge_time < 0.09: await step(purple,caster,{},delta)
			purple.facing = -1
			var shot = load("res://scripts/"+str(data.script)).new()
			world.add_child(shot)
			shot.configure(caster,str(data.kind),1)
			shot.position = purple.position + Vector2(-45,-80)
			var blocked = shot.tick(delta,purple)
			check(not blocked and shot.owner_fighter == purple and shot.reflection_count == 1 and purple.health == 100,
				str(data.kind)+" reflects once with no guard damage at delta="+str(delta))
			check(shot.velocity.x < 0 and shot.damage == ceili(float(data.damage)*0.75), str(data.kind)+" reverses with limited reflected damage")
			var reached_caster = false
			for frame in range(220):
				if shot.tick(delta,caster):
					reached_caster = true
					break
			check(reached_caster and caster.health == caster.max_health - shot.damage and purple.total_damage == shot.damage,
				str(data.kind)+" returns one physical hit to its owner at delta="+str(delta))
			check(caster.last_hit_source == shot and caster.last_hit_air_kind == "reflect" and caster.last_hit_attack_serial == -1,
				str(data.kind)+" damage retains reflected source attribution")
			shot.tick(delta,caster)
			check(caster.health == caster.max_health - shot.damage, str(data.kind)+" consumed reflection cannot damage twice")
			shot.queue_free()
			await clean(purple,caster)
	var late = spawn("purple",500)
	var attacker = spawn("h4ck3r",300)
	await settle(late,attacker)
	late.facing = -1
	late.start_dodge(1,attacker)
	while late.dodge_time < 0.18: await step(late,attacker)
	late.facing = -1
	var late_shot = load("res://scripts/attack_effect.gd").new()
	world.add_child(late_shot)
	late_shot.configure(attacker,"signal",1)
	late_shot.position = late.position + Vector2(-54,-80)
	check(late_shot.tick(DT,late) and late_shot.consumed and late_shot.owner_fighter == attacker and late.health == 100,
		"late shield face blocks a projectile but does not reflect it")
	late_shot.queue_free()
	await clean(late,attacker)
	var fan_guard = spawn("purple",500)
	var fan_caster = spawn("pac_man",300)
	await settle(fan_guard,fan_caster)
	fan_guard.facing = -1
	fan_guard.start_dodge(1,fan_caster)
	while fan_guard.dodge_time < 0.09: await step(fan_guard,fan_caster)
	fan_guard.facing = -1
	var fan_shots = []
	for i in range(2):
		var pellet = load("res://scripts/boss_projectile.gd").new()
		world.add_child(pellet)
		pellet.configure(fan_caster,"pellet_fan",1)
		pellet.position = fan_guard.position + Vector2(-45,-80)
		fan_shots.append(pellet)
	check(not fan_shots[0].tick(DT,fan_guard) and fan_guard.shield_reflected, "one timed guard reflects the first fan pellet")
	check(fan_shots[1].tick(DT,fan_guard) and fan_shots[1].consumed and fan_guard.health == 100 and fan_shots[1].owner_fighter == fan_caster,
		"remaining fan pellets are safely blocked without multiplying reflected damage")
	for pellet in fan_shots: pellet.queue_free()
	await clean(fan_guard,fan_caster)
	var left_guard = spawn("purple",500)
	var right_guard = spawn("purple",300)
	await settle(left_guard,right_guard)
	left_guard.facing = -1
	left_guard.start_dodge(1,right_guard)
	while left_guard.dodge_time < 0.09: await step(left_guard,right_guard)
	left_guard.facing = -1
	var single_bounce = load("res://scripts/attack_effect.gd").new()
	world.add_child(single_bounce)
	single_bounce.configure(right_guard,"arrow",1)
	single_bounce.position = left_guard.position + Vector2(-45,-80)
	check(not single_bounce.tick(DT,left_guard) and single_bounce.owner_fighter == left_guard, "first Purple shield sends an arrow back")
	right_guard.facing = 1
	right_guard.start_dodge(-1,left_guard)
	right_guard.dodge_time = 0.09
	var second_contact = false
	for frame in range(100):
		if single_bounce.tick(DT,right_guard):
			second_contact = true
			break
	check(second_contact and right_guard.health == 100 and single_bounce.reflection_count == 1 and single_bounce.owner_fighter == left_guard,
		"a second Purple shield blocks the returning arrow without infinite ping-pong")
	single_bounce.queue_free()
	await clean(left_guard,right_guard)
	print("PASS group: arrow, signal and boss shots reflect once at 30/60/120 Hz; late guard blocks")

func test_grounded_fighter_tradeoffs() -> void:
	var travel: Dictionary = {}
	var timings: Dictionary = {}
	var basics: Dictionary = {}
	for id in IDS:
		var fighter = spawn(id,350)
		var opponent = spawn("dark_lord",1000)
		await settle(fighter,opponent)
		var start_x: float = fighter.position.x
		for frame in range(45): await step(fighter,opponent,{"move":1.0})
		travel[id] = fighter.position.x - start_x
		fighter.velocity.x = 0
		check(fighter.start_attack(false), id + " starts a grounded basic")
		basics[id] = fighter.attack_spec.duplicate(true)
		var elapsed: float = 0.0
		var first_active: float = -1.0
		while fighter.attack_time >= 0:
			await step(fighter,opponent)
			elapsed += DT
			if fighter.is_active() and first_active < 0: first_active = elapsed
		timings[id] = {"windup":first_active,"total":elapsed}
		await clean(fighter,opponent)
	check(travel.green > travel.yellow and travel.yellow > travel.orange and travel.orange > travel.purple and travel.purple > travel.blue and travel.blue > travel.red,
		"actual grounded movement separates fast Green/Yellow from heavy Red/Blue")
	check(float(travel.green) > float(travel.red) + 30.0, "mobility tradeoff remains visible over three quarters of a second")
	check(int(basics.red.damage) > int(basics.blue.damage) and int(basics.blue.damage) > int(basics.green.damage),
		"slower heavy weapons pay off with stronger direct hits")
	check(float(basics.orange.reach) > float(basics.yellow.reach) * 1.25 and float(basics.red.recovery) > float(basics.green.recovery) + 0.14,
		"Orange owns melee reach while Red's heavy commitment has a longer punishable recovery")
	check(float(timings.red.windup) > float(timings.green.windup) + 0.10 and float(timings.red.total) > float(timings.green.total) + 0.25,
		"measured Red hammer attack is slower to connect and recover than Green blade")
	check(str(basics.purple.get("air_kind","")) == "" and int(basics.purple.projectile_damage) == 12,
		"Purple trades a grounded melee hitbox for its timed arrow release")
	print("PASS group: six grounded mobility, reach, hit strength and measured timing tradeoffs")

func test_damage_attribution_at_signal_time() -> void:
	var attacker = spawn("green",500)
	var victim = spawn("red",590)
	await settle(attacker,victim)
	attacker.facing = 1
	var seen: Array = []
	victim.damaged.connect(func(_fighter,_amount,_direction): seen.append([victim.last_hit_source,victim.last_hit_attack_serial,victim.last_hit_special,victim.last_hit_air_kind]))
	check(attacker.start_attack(false), "attribution melee attack begins")
	attacker.attack_time = float(attacker.attack_spec.windup)
	check(attacker.try_hit(victim), "attribution melee contact deals damage")
	check(seen.size() == 1 and seen[0][0] == attacker and int(seen[0][1]) == attacker.attack_serial and not bool(seen[0][2]),
		"unchanged damaged signal can inspect melee source and serial synchronously")
	victim.invulnerable = 0
	victim.hurt_time = 0
	victim.take_hit(9,1,210)
	check(seen.size() == 2 and seen[1][0] == null and int(seen[1][1]) == -1,
		"hazard contact clears prior attacker rather than falsely crediting damage")
	await clean(attacker,victim)
	print("PASS group: melee, reflected projectile and environmental damage source attribution")

func test_ai_purple_guard_read() -> void:
	var AI = load("res://scripts/ai_controller.gd")
	var ai = AI.new()
	ai.configure(2)
	ai.reset()
	var purple = spawn("purple",500)
	var red = spawn("red",590)
	await settle(purple,red)
	for threat in range(2):
		check(red.start_attack(false), "hard AI reads announced hammer threat "+str(threat+1))
		var ignored: Dictionary = ai.read_input(DT,purple,red)
		check(not bool(ignored.dodge) and not ai.guard_pending, "hard AI does not parry every threat")
		red.attack_time = -1
	check(red.start_attack(false), "third announced hammer swing begins")
	var first_read: Dictionary = ai.read_input(DT,purple,red)
	check(not bool(first_read.dodge) and ai.guard_pending and ai.guard_reaction >= 0.10,
		"hard Purple AI first schedules a visible reaction delay")
	var dodge_after: float = -1.0
	for frame in range(15):
		var command: Dictionary = ai.read_input(DT,purple,red)
		if bool(command.dodge): dodge_after = float(frame+1)*DT
		await step(purple,red,command)
		if dodge_after >= 0: break
	check(dodge_after >= 0.09 and dodge_after <= 0.19 and purple.dodge_time >= 0 and ai.guard_cooldown > 3.0,
		"hard AI guard uses the same dodge input after a fair delay and starts a real cooldown")
	red.attack_time = -1
	red.start_attack(false)
	check(not bool(ai.read_input(DT,purple,red).dodge) and not ai.guard_pending,
		"follow-up swing cannot force a second immediate AI shield")
	await clean(purple,red)
	var easy = AI.new()
	easy.configure(0)
	easy.reset()
	var easy_purple = spawn("purple",500)
	var easy_attacker = spawn("red",590)
	await settle(easy_purple,easy_attacker)
	for threat in range(6):
		easy_attacker.start_attack(false)
		easy.read_input(DT,easy_purple,easy_attacker)
		check(easy.guard_pending == (threat == 5), "easy Purple AI only considers a shield on a rare sixth visible threat")
		easy_attacker.attack_time = -1
	check(easy.guard_reaction >= 0.19, "easy guard has slower reaction than hard guard")
	await clean(easy_purple,easy_attacker)
	var fast_ai = AI.new()
	fast_ai.configure(2)
	fast_ai.reset()
	var target = spawn("purple",500)
	var green = spawn("green",590)
	await settle(target,green)
	for threat in range(2):
		green.start_attack(false)
		fast_ai.read_input(DT,target,green)
		green.attack_time = -1
	green.start_attack(false)
	fast_ai.read_input(DT,target,green)
	for frame in range(12):
		var response: Dictionary = fast_ai.read_input(DT,target,green)
		await step(target,green,response)
		green.try_hit(target)
		if target.health < 100: break
	check(target.health == 88 and target.dodge_time < 0,
		"Green's fast blade reaches Purple before even hard AI can raise its guard")
	await clean(target,green)
	var shot_ai = AI.new()
	shot_ai.configure(2)
	shot_ai.reset()
	var shot_guard = spawn("purple",600)
	var archer = spawn("purple",300)
	await settle(shot_guard,archer)
	for threat in range(2):
		archer.start_attack(false)
		shot_ai.read_input(DT,shot_guard,archer)
		archer.attack_time = -1
	var shots: Array = []
	archer.released.connect(func(_fighter,kind):
		if kind == "arrow":
			var shot = load("res://scripts/attack_effect.gd").new()
			world.add_child(shot)
			shot.configure(archer,"arrow",1)
			shots.append(shot))
	archer.start_attack(false)
	var announced: Dictionary = shot_ai.read_input(DT,shot_guard,archer)
	check(shot_ai.guard_pending and shot_ai.guard_reaction > 0.26 and not bool(announced.dodge),
		"AI schedules a distant arrow guard from visible release and travel time")
	var chose_dodge = false
	var reflected_arrow = false
	for frame in range(100):
		var response: Dictionary = shot_ai.read_input(DT,shot_guard,archer)
		chose_dodge = chose_dodge or bool(response.dodge)
		await step(shot_guard,archer,response)
		if not shots.is_empty() and not shots[0].consumed:
			var arrow = shots[0]
			arrow.tick(DT,shot_guard if arrow.owner_fighter == archer else archer)
			if arrow.owner_fighter == shot_guard:
				reflected_arrow = true
				break
	check(chose_dodge and reflected_arrow and shot_guard.health == 100,
		"hard AI can meet a telegraphed arrow with the same physical reflection as a player")
	for shot in shots: shot.queue_free()
	await clean(shot_guard,archer)
	print("PASS group: Purple AI watches announced threats, guards rarely on easy, waits on hard, and loses to fast timing")

func test_air_basics() -> void:
	for index in range(IDS.size()):
		var id: String = IDS[index]
		var a = spawn(id)
		var b = spawn("red",850)
		await settle(a,b)
		check(a.is_on_floor() and a.airborne_time == 0, id + " starts grounded before variant selection")
		check(a.start_attack(false) and not a.attack_spec.has("air_kind"), id + " grounded basic remains unchanged")
		while a.attack_time >= 0: await step(a,b)
		await step(a,b,{"jump":true})
		for frame in range(3): await step(a,b)
		check(a.airborne_time > 0 and not a.is_on_floor(), id + " has confirmed airborne state")
		check(a.start_attack(false), id + " can start basic in air")
		check(str(a.attack_spec.get("air_kind","")) == AIR_KINDS[index] and int(a.attack_spec.damage) == AIR_DAMAGE[index], id + " selects its own air attack data")
		check(not a.hitbox().has_area(), id + " has no hitbox during air windup")
		while not a.is_active(): await step(a,b)
		var box: Rect2 = a.hitbox()
		if id == "purple":
			check(not box.has_area() and int(a.attack_spec.projectile_damage) == 12, "Purple air arrow has projectile damage only and no phantom melee")
		else:
			check(box.has_area(), id + " airborne basic has an active melee shape")
		if id == "orange":
			check(box.position.x < a.position.x and box.end.x > a.position.x, "Orange air sweep covers both sides")
		if id in ["red","yellow"]:
			check(box.end.y > a.position.y and a.velocity.y > 290, id + " air attack reaches below while descending")
		if id == "green":
			check(a.velocity.x > 350 and box.end.y > a.position.y, "Green air slash lunges forward and down")
		if id == "blue":
			check(box.position.y < a.position.y - 200, "Blue air pick reaches substantially above")
		while a.attack_time >= 0: await step(a,b)
		check(not a.hitbox().has_area(), id + " air hitbox clears after active frames")
		await clean(a,b)
	print("PASS group: six authored air variants, distinct vertical/forward geometry and cleared hitboxes")

func test_air_damage_rates() -> void:
	for index in range(IDS.size()):
		var id: String = IDS[index]
		for delta in [1.0/30.0,1.0/60.0,1.0/120.0]:
			var a = spawn(id)
			var b = spawn("red",800)
			await settle(a,b)
			await step(a,b,{"jump":true})
			for frame in range(3): await step(a,b)
			check(a.start_attack(false), id + " air damage run begins at delta="+str(delta))
			var hit_count := 0
			var release_count: Array[int] = [0]
			a.released.connect(func(_fighter,_kind): release_count[0] += 1)
			var frames := ceili((a.duration()+delta*2.0)/delta)
			for frame in range(frames):
				await physics_frame
				a.tick(delta,{},b)
				a.position = Vector2(500,400)
				b.position = Vector2(580,400)
				b.invulnerable = 0
				if a.try_hit(b): hit_count += 1
			if id == "purple":
				check(hit_count == 0 and release_count[0] == 1 and b.health == 100, "Purple air arrow releases once without melee damage at delta="+str(delta))
			else:
				check(hit_count == 1 and b.health == 100-AIR_DAMAGE[index], id + " air attack hits exactly once at delta="+str(delta))
			if id == "red": check(is_equal_approx(b.velocity.y,240.0), "Red air hammer knocks target down at delta="+str(delta))
			if id == "blue": check(is_equal_approx(b.velocity.y,-390.0), "Blue air pick launches target up at delta="+str(delta))
			if id == "yellow": check(is_equal_approx(b.velocity.y,140.0), "Yellow air staff nudges target down at delta="+str(delta))
			check(a.attack_time < 0 and not a.hitbox().has_area(), id + " air attack recovers cleanly at delta="+str(delta))
			await clean(a,b)
	print("PASS group: air damage, release and active-window invariance at 30/60/120 Hz")
