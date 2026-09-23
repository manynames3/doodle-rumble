extends SceneTree
var game
var checks = 0
var failures = 0
const DT = 1.0/60
func _initialize(): call_deferred("run")
func check(value, label):
	checks += 1
	if not value: failures += 1; push_error("FAIL: "+label)
func step(n):
	for i in range(n):
		await physics_frame
		game._physics_process(DT)
func run():
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	check(game.optional_hazards,"stage hazards are on by default")
	game.mode = "arcade"
	var capacities = []
	for stage in [3,4,5]:
		game.arcade_stage = stage
		game.start_match()
		capacities.append(game.second.max_health)
		check(game.second.health == game.second.max_health,"boss starts at full larger health")
		check(game.health_bars[1].max_value == game.second.max_health,"boss health bar uses its real capacity")
	check(capacities == [150,190,240],"late bosses gain durability at each stage")
	var strength = load("res://scripts/boss_strength.gd")
	check(strength.damage("dark_lord",26) == 39 and strength.damage("h4ck3r",13) == 17 and strength.damage("red",20) == 20,"Dark lord has a higher damage tier while H4CK3R and other fighters keep their own values")
	game.countdown = 0
	game.first.reset_at(Vector2(400,599))
	game.second.reset_at(Vector2(680,599))
	var boss = game.second
	boss.start_attack(false)
	check(int(boss.attack_spec.damage) == 39,"Dark lord blade uses the final-boss damage tier")
	boss.attack_time = -1
	boss.start_attack(true)
	check(int(boss.attack_spec.damage) == 48,"Dark lord special attack payload uses the final-boss damage tier")
	var wave = load("res://scripts/attack_effect.gd").new()
	game.world.add_child(wave)
	wave.configure(boss,"shockwave",-1)
	check(wave.damage == 48,"Dark lord moving ground wave scales once")
	wave.queue_free()
	boss.attack_time = -1
	boss.guard_remaining = 1.0
	boss.boss_guard = true
	boss.start_attack(false)
	boss.take_hit(13,-1)
	check(boss.health == 227 and boss.attack_time >= 0 and boss.hurt_time == 0,"committed boss takes full damage without losing its signaled attack")
	for i in range(70):
		await physics_frame
		boss.tick(DT,{},game.first)
	check(boss.guard_remaining == 0 and not boss.boss_guard,"commitment armor always expires")
	boss.invulnerable = 0
	boss.start_attack(false)
	boss.take_hit(13,-1)
	check(boss.hurt_time>0 and boss.attack_time < 0,"boss recovery remains interruptible")
	game.start_match()
	game.countdown = 0
	var patterns = {}
	var shots = {}
	var hazard_kinds = {}
	var damage_dealt = 0
	for frame in range(2400):
		game.first.health = 100
		game.second.health = game.second.max_health
		await step(1)
		damage_dealt += 100-game.first.health
		if game.boss_ai.tell != "": patterns[game.boss_ai.tell] = true
		for projectile in game.projectiles: shots[projectile.kind] = true
		for mark in game.hazards.marks: hazard_kinds[mark.kind] = true
	check(patterns.size() == 8,"Dark lord naturally cycles eight distinct signaled patterns")
	check(shots.has("void_orb") and shots.has("eclipse_volley") and shots.has("shockwave"),"Dark lord launches an orb fan, a five-shard eclipse volley and ground waves")
	check(hazard_kinds.has("dark_rift") and hazard_kinds.has("eclipse_wave") and hazard_kinds.has("void_pillar"),"Dark lord cycles his rift, jumpable eclipse wave and sidestep pillar")
	check(damage_dealt >= 100,"passive standing player faces substantial boss pressure")
	print("DARK_PRESSURE damage_in_40_seconds=%d patterns=%d" % [damage_dealt,patterns.size()])
	# Verify projectile timing, damage, consumed state and off-target misses.
	for kind in ["void_orb","pellet_fan","eclipse_volley"]:
		var totals = []
		for delta in [1.0/30,1.0/60,1.0/120]:
			game.first.reset_at(Vector2(450,599))
			var shot = load("res://scripts/boss_projectile.gd").new()
			game.world.add_child(shot)
			shot.configure(game.second,kind,-1)
			shot.position = Vector2(670,520)
			for n in range(240):
				if shot.tick(delta,game.first): break
			totals.append(100-game.first.health)
			game.first.invulnerable = 0
			shot.tick(delta,game.first)
			check(100-game.first.health == totals[-1],kind+" cannot hit twice after consumption")
			shot.queue_free()
		var expected_damage: int = 36 if kind == "void_orb" else 27 if kind == "pellet_fan" else 23
		check(totals == [expected_damage,expected_damage,expected_damage],kind+" damage is stable across fixed-step sampling")
		game.first.reset_at(Vector2(450,350))
		var miss = load("res://scripts/boss_projectile.gd").new()
		game.world.add_child(miss)
		miss.configure(game.second,kind,-1)
		miss.position = Vector2(670,520)
		for n in range(200):
			if miss.tick(DT,game.first): break
		check(game.first.health == 100,kind+" can be avoided by jumping its path")
		miss.queue_free()
	game.hazards.clear()
	game.hazards.mark_target(450,0,"dark_rift","dark_lord")
	game.first.reset_at(Vector2(450,599))
	game.hazards.tick(1.14,[game.first,game.second])
	check(game.first.health==100,"rift has a full warning window")
	game.hazards.tick(0.02,[game.first,game.second])
	check(game.first.health==70,"Dark lord rift deals one scaled 30-point hit")
	game.hazards.clear()
	game.first.reset_at(Vector2(450,599))
	game.hazards.mark_target(450,0,"dark_rift")
	game.hazards.tick(1.17,[game.first,game.second])
	check(game.first.health==80,"an ordinary stage rift keeps its original 20-point payload")
	game.hazards.clear()
	game.first.reset_at(Vector2(450,599))
	game.hazards.mark_target(450,0,"camera","dark_lord")
	game.hazards.tick(1.34,[game.first,game.second])
	check(game.first.health==100,"Dark lord camera mark keeps its full warning")
	game.hazards.tick(0.02,[game.first,game.second])
	check(game.first.health==86,"Dark lord camera mark rounds its nine-point base payload to fourteen")
	for kind in ["eclipse_wave","void_pillar"]:
		game.hazards.clear()
		game.first.reset_at(Vector2(450,599))
		game.hazards.mark_target(450,0,kind,"dark_lord")
		var spec: Dictionary = game.hazards.warning_spec(kind)
		game.hazards.tick(float(spec.tell)-0.01,[game.first,game.second])
		check(game.first.health==100,kind+" shows its entire tell without dealing damage")
		game.hazards.tick(0.02,[game.first,game.second])
		var expected: int = ceili(float(spec.damage)*1.5)
		check(game.first.health==100-expected,kind+" deals its one-time final-boss payload")
	# Different maximum health should not unfairly decide a timeout.
	game.rules.reset()
	game.rules.remaining=0.001
	game.first.health=100
	game.second.health=240
	game.hazards.clear()
	game.countdown=0
	game._physics_process(DT)
	check(game.rules.last_winner == -1,"full-health timeout is a tie despite boss health capacity")
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	await create_timer(0.15).timeout
	print("TEST_RESULT checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
