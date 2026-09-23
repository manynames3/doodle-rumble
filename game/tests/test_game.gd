extends SceneTree
## Full-scene integration. Run with --headless --path game --script res://tests/test_game.gd.
## Uses public game/input paths; forced KOs are limited to explicit scoring-path tests.
const DT = 1.0/60.0
const JOURNEY_OPPONENTS = ["blue", "red", "green", "pac_man", "h4ck3r", "dark_lord"]
const JOURNEY_ARENAS = ["desktop", "quarry", "canopy", "arcade", "network", "glitch"]
var game
var settings
var checks = 0
var failures: Array[String] = []
var config_existed = false
var config_bytes = PackedByteArray()
var config_path = "user://settings.cfg"
var saved_bindings: Dictionary
var saved_wins = 0
var saved_fighter = "orange"
var saved_motion = false
var saved_hold = false
var saved_celebration = "classic"
var bot_rounds = 0
var live_retries = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func release_inputs() -> void:
	for p in ["p1_","p2_"]:
		for action in ["move_left","move_right","jump","attack","special","dodge"]:
			Input.action_release(p+action)

func command(slot: int, move: float = 0, attack: bool = false, special: bool = false, jump: bool = false, dodge: bool = false) -> void:
	var prefix = "p%d_" % (slot+1)
	for action in ["move_left","move_right","attack","special","jump","dodge"]:
		Input.action_release(prefix+action)
	if move < 0: Input.action_press(prefix+"move_left",absf(move))
	if move > 0: Input.action_press(prefix+"move_right",absf(move))
	if attack: Input.action_press(prefix+"attack")
	if special: Input.action_press(prefix+"special")
	if jump: Input.action_press(prefix+"jump")
	if dodge: Input.action_press(prefix+"dodge")

func step(frames: int = 1) -> void:
	for i in range(frames):
		await physics_frame
		game._physics_process(DT)

func begin(mode: String, one: String = "orange", two: String = "blue", arena: String = "desktop") -> void:
	release_inputs()
	game.mode = mode
	game.selected = [one,two]
	game.arena_kind = arena
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0
	await process_frame
	await step(5)

func run() -> void:
	await process_frame
	settings = root.get_node("Settings")
	config_existed = FileAccess.file_exists(config_path)
	if config_existed: config_bytes = FileAccess.get_file_as_bytes(config_path)
	saved_bindings = settings._bindings.duplicate(true)
	saved_wins = settings.arcade_wins
	saved_fighter = settings.selected_fighter
	saved_motion = settings.reduced_motion
	saved_hold = settings.hold_to_attack
	saved_celebration = settings.celebration_style
	settings._bindings = settings._default_bindings()
	settings._rebuild_input_map()
	settings.reduced_motion = true
	settings.hold_to_attack = true
	var packed = load("res://scenes/main.tscn")
	if not packed or not packed.can_instantiate():
		check(false,"main scene compiles")
		finish()
		return
	game = packed.instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.set_process(false)
	await process_frame
	check(game.state == "title","full game opens on title screen")
	check(game.selected[0] == saved_fighter,"title restores selected fighter")
	await test_controls_and_pause()
	await test_platform_and_hazards()
	await test_platform_route()
	await test_specials()
	await test_training_and_ai()
	await test_difficulty_pressure()
	await test_round_paths()
	await test_arcade_paths_and_boss()
	await test_live_local()
	await test_live_arcade()
	finish()

func finish() -> void:
	release_inputs()
	paused = false
	if is_instance_valid(game):
		game.queue_free()
	settings._bindings = saved_bindings
	settings._rebuild_input_map()
	settings.arcade_wins = saved_wins
	settings.selected_fighter = saved_fighter
	settings.reduced_motion = saved_motion
	settings.hold_to_attack = saved_hold
	settings.celebration_style = saved_celebration
	if config_existed:
		var file = FileAccess.open(config_path,FileAccess.WRITE)
		file.store_buffer(config_bytes)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))
	root.get_node("Sound").shutdown()
	print("GAME_TEST_RESULT checks=%d failures=%d live_rounds=%d live_retries=%d" % [checks,failures.size(),bot_rounds,live_retries])
	for failure in failures: print("  " + failure)
	call_deferred("quit",0 if failures.is_empty() else 1)

func physical_key(key: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

func test_controls_and_pause() -> void:
	await begin("local")
	physical_key(KEY_D,true)
	await step(15)
	physical_key(KEY_D,false)
	check(game.first.position.x > 445 and absf(game.second.position.x-860)<2,"physical P1 D moves only first fighter")
	var first_x = game.first.position.x
	physical_key(KEY_LEFT,true)
	await step(15)
	physical_key(KEY_LEFT,false)
	check(game.second.position.x < 835 and game.first.position.x < first_x+35,"physical P2 Left moves second fighter independently")
	await step(15)
	game.first.cooldown = 3
	var hp = [game.first.health,game.second.health]
	var positions = [game.first.position,game.second.position]
	var seconds = game.rules.remaining
	game.pause_game()
	command(0,1,true,true,true)
	await step(30)
	check(game.state == "paused" and paused,"pause changes scene state")
	check(game.first.position == positions[0] and game.second.position == positions[1],"pause freezes movement")
	check(game.rules.remaining == seconds and game.first.cooldown == 3 and [game.first.health,game.second.health] == hp,"pause freezes round, cooldown and damage")
	release_inputs()
	game.resume_game()
	await step(2)
	check(game.state == "playing" and not paused and game.rules.remaining < seconds,"resume restarts physics and timer")
	print("PASS group: physical keyboard isolation and pause/resume")


func test_platform_and_hazards() -> void:
	for arena_kind in ["desktop","quarry","glitch"]:
		await begin("local","orange","blue",arena_kind)
		game.first.reset_at(Vector2(640,599))
		await step(5)
		command(0,0,false,false,true)
		await step()
		release_inputs()
		var landed_on_platform = false
		for frame in range(140):
			await step()
			if game.first.is_on_floor() and game.first.position.y < 520:
				landed_on_platform = true
				break
		check(landed_on_platform,arena_kind + " low platform can be reached with a normal jump")
	await begin("local","orange","blue","glitch")
	game.first.reset_at(Vector2(300,599))
	game.second.reset_at(Vector2(1000,599))
	await step(5)
	game.hazards.mark_target(300)
	await step(80)
	check(game.first.health == 100,"hazard warning gives over a second without damage")
	await step(5)
	check(game.first.health == 91,"active camera mark deals one nine-point hit")
	await step(35)
	check(game.first.health == 91 and game.hazards.marks.is_empty(),"hazard does not multi-hit and expires")
	print("PASS group: reachable low platforms and telegraphed hazard damage")

func test_platform_route() -> void:
	await begin("local","orange","blue","desktop")
	game.first.reset_at(Vector2(250,599))
	game.second.reset_at(Vector2(1180,599))
	await step(5)
	for destination in [Vector2(250,480),Vector2(570,440),Vector2(1010,370)]:
		if destination.y == 370:
			for frame in range(80):
				if game.first.position.x >= 735: break
				command(0,1,false,false,false)
				await step()
		command(0,0 if destination.y == 480 else 1,false,false,true)
		await step()
		var landed = false
		for frame in range(100):
			var moving: float = 0.0 if absf(game.first.position.x-destination.x)<12 else signf(destination.x-game.first.position.x)
			command(0,moving,false,false,false)
			await step()
			if frame>10 and game.first.is_on_floor() and absf(game.first.position.y-destination.y)<4:
				landed = true
				break
		release_inputs()
		check(landed,"normal movement climbs playable platform at y="+str(destination.y))
	check(game.first.health == 100,"platform route has safe footing without fall damage")
	print("PASS group: three-platform route from floor to the highest desk ledge")

func test_specials() -> void:
	for id in ["orange","red","green","blue"]:
		await begin("local",id,"orange")
		game.first.reset_at(Vector2(300,599))
		game.second.reset_at(Vector2(500,599)) # Leave visible travel after the larger projectile spawns.
		await step(5)
		command(0,0,false,true)
		await step()
		release_inputs()
		var saw_projectile = not game.projectiles.is_empty()
		for i in range(100):
			await step()
			saw_projectile = saw_projectile or not game.projectiles.is_empty()
		check(game.first.cooldown > 0,id + " special input starts cooldown")
		check(game.second.health < 100,id + " special damages opponent through full game")
		check(game.practice_special and game.practice_hits > 0,id + " special connects feedback counters")
		if id in ["red","blue"]: check(saw_projectile,id + " spawns reusable moving hitbox")
		check(game.projectiles.is_empty(),id + " projectile lifetime cleanup completes")
	print("PASS group: all four integrated specials and projectile cleanup")

func test_training_and_ai() -> void:
	await begin("training")
	var position = game.second.position
	await step(30)
	check(game.second.position.distance_to(position)<2,"training opponent stays passive")
	game.second.invulnerable = 0
	game.second.take_hit(100,1,0)
	await step(90)
	check(game.second.health == 100 and game.state == "playing","training dummy refills after KO")
	check(game.rules.remaining == 60 and game.rules.scores == [0,0],"training has no timer or scoring pressure")
	await begin("solo")
	game.ai.rng.seed = 7128
	var start_distance = absf(game.first.position.x-game.second.position.x)
	var saw_tell = false
	for i in range(480):
		await step()
		saw_tell = saw_tell or game.ai.tell_time > 0
	check(absf(game.first.position.x-game.second.position.x) < start_distance,"easy AI approaches opponent")
	check(saw_tell,"easy AI visibly telegraphs attacks")
	check(game.first.health < 100,"easy AI can land real damage")
	print("PASS group: training refill and easy AI")

func test_difficulty_pressure() -> void:
	# Equal geometry and RNG seeds isolate decision pressure from weapon damage.
	var counts: Array[int] = []
	var first_decisions: Array[int] = []
	var profiles: Array[Dictionary] = []
	game.start_arcade()
	for level in range(3):
		game.arcade_stage = level
		game.start_match()
		game.first.reset_at(Vector2(400,599))
		game.second.reset_at(Vector2(500,599))
		var brain = load("res://scripts/ai_controller.gd").new()
		brain.configure(level)
		brain.reset()
		brain.rng.seed = 2517
		check(game.ai.profile == brain.profile,"journey stage %d wires the corresponding AI difficulty" % (level+1))
		profiles.append(brain.profile.duplicate(true))
		var decisions = 0
		var first_decision = 1200
		for frame in range(1200):
			await physics_frame
			# Hold only geometry steady; actual attack duration and cooldown still run.
			game.first.position = Vector2(400,599)
			game.second.position = Vector2(500,599)
			var decision: Dictionary = brain.read_input(DT,game.second,game.first)
			if decision.get("attack",false) or decision.get("special",false):
				decisions += 1
				first_decision = mini(first_decision,frame)
			game.first.tick(DT,{},game.second)
			game.second.tick(DT,decision,game.first)
		counts.append(decisions)
		first_decisions.append(first_decision)
	check(first_decisions[0] > first_decisions[1] and first_decisions[1] > first_decisions[2],"Blue, Red and Green react strictly sooner at each stage")
	check(counts[0] < counts[1] and counts[1] < counts[2],"Blue, Red and Green produce strictly more attack decisions in the same twenty seconds")
	check(profiles[0] != profiles[1] and profiles[1] != profiles[2],"early journey stages use distinct challenge profiles")
	for increasing in ["speed", "approach", "special"]:
		check(profiles[0][increasing] < profiles[1][increasing] and profiles[1][increasing] < profiles[2][increasing],"early-stage challenge strictly increases " + increasing)
	for decreasing in ["think_min", "think_max", "rest_min", "rest_max", "tell"]:
		check(profiles[0][decreasing] > profiles[1][decreasing] and profiles[1][decreasing] > profiles[2][decreasing],"early-stage challenge strictly reduces " + decreasing)
	var ranks: Array[int] = []
	for stage in range(6): ranks.append(int(game.journey_stage_data(stage).challenge_rank))
	check(ranks == [1,2,3,4,5,6],"all six opponents have strictly rising challenge ranks")
	print("DIFFICULTY_PRESSURE attacks=%s first_attack_frames=%s" % [str(counts),str(first_decisions)])
	print("PASS group: actual early-stage difficulty wiring, reaction speed and attack pressure")

func test_round_paths() -> void:
	await begin("local")
	var normal_scales = [game.first.rig.scale, game.second.rig.scale]
	game.second.take_hit(100,1,0)
	await step()
	check(game.state == "round_over" and game.rules.scores == [1,0],"KO enters first-round result")
	check(game.camera.zoom == Vector2.ONE and game.first.visible and game.second.visible,"result keeps the arena camera and real fighters visible")
	check(game.first.rig.scale == normal_scales[0] and game.second.rig.scale == normal_scales[1],"result fighters stay at gameplay size")
	check(game.first.victory and game.second.result_defeated and game.second.rig.result_kind == "defeated","winner celebrates and KO loser collapses")
	game.next_round()
	game.countdown = 0
	await step()
	check(game.first.health == 100 and game.second.health == 100 and game.rules.round_number == 2,"next round resets fighters")
	game.rules.remaining = DT/2
	game.first.health = 35
	game.second.health = 20
	await step()
	check(game.state == "match_over" and game.rules.scores == [2,0],"timeout closes best-of-three at two wins")
	check(game.first.victory and game.second.result_defeated and game.second.rig.result_kind == "defeated","timeout loser gets the same floor pose")
	game.rematch()
	check(game.state == "playing" and game.rules.scores == [0,0] and game.rules.remaining == 60 and game.first.health == 100,"immediate rematch resets complete loop")
	game.countdown = 0
	game.rules.remaining = DT/2
	await step()
	check(game.state == "round_over" and game.rules.last_winner == -1 and game.rules.scores == [0,0],"equal-health timeout gives draw without scoring")
	check(not game.first.victory and not game.second.victory and not game.first.result_defeated and not game.second.result_defeated,"a tied round has no false celebration or knockout")
	print("PASS group: round endings, timeout, tie, immediate rematch")

func test_arcade_paths_and_boss() -> void:
	release_inputs()
	var prior_wins = settings.arcade_wins
	var pac_tell_count = 0
	game.selected[0] = "orange"
	game.optional_hazards = true
	game.start_arcade()
	game.countdown = 0
	game.advance_arcade()
	check(game.arcade_stage == 0 and game.selected[1] == "blue","journey cannot advance before winning its current stage")
	for stage in range(6):
		check(game.arcade_stage == stage and game.arena_kind == JOURNEY_ARENAS[stage],"journey enters arena " + str(stage+1))
		check(game.selected[1] == JOURNEY_OPPONENTS[stage],"journey selects required opponent " + str(stage+1))
		check(game.first.health == game.first.max_health and game.second.health == game.second.max_health,"journey stage %d starts both fighters at their full health" % (stage+1))
		if stage == 2:
			# Force a loss only here, to exercise the retry branch independently of skill.
			for round_index in range(2):
				game.first.health = 0
				game.second.health = 100
				await step()
				if round_index == 0:
					game.next_round()
					game.countdown = 0
			check(game.state == "match_over" and game.rules.last_winner == 1 and game.arcade_stage == stage,"losing a journey match keeps the earned stage")
			game.advance_arcade()
			check(game.arcade_stage == stage and game.selected[1] == "green","loss cannot use Next match to skip its opponent")
			check(settings.arcade_wins == prior_wins,"journey loss grants no completion reward")
			game.rematch()
			game.countdown = 0
			check(game.arcade_stage == stage and game.selected[1] == "green" and game.rules.scores == [0,0] and game.first.health == 100,"retry resets the fight while preserving stage and opponent")
		if stage == 3:
			game.first.reset_at(Vector2(300,599))
			game.second.reset_at(Vector2(425,599))
			var tells: Dictionary = {}
			var saw_damage = false
			var warning_visible = false
			for i in range(1100):
				game.first.health = 100
				game.second.health = 100
				await step()
				if game.pac_ai.tell != "": tells[game.pac_ai.tell] = true
				warning_visible = warning_visible or (game.enemy_warning_label.visible and game.enemy_warning_label.text == game.pac_ai.tell and game.pac_ai.tell != "")
				saw_damage = saw_damage or game.first.health < 100
			pac_tell_count = tells.size()
			check(tells.has("BITE!") and tells.has("CHARGE!"),"penultimate Pac-Man uses both telegraphed attack patterns through the real coordinator")
			check(saw_damage,"penultimate Pac-Man can land shared-rules combat damage")
			check(warning_visible,"Pac-Man warning is visible in the HUD above the arena artwork")
		if stage == 5:
			game.first.reset_at(Vector2(300,599))
			game.second.reset_at(Vector2(425,599))
			var tells: Dictionary = {}
			var saw_mark = false
			var saw_wave = false
			var warning_visible = false
			# Keep both fighters healthy to observe all complete patterns naturally.
			for i in range(1100):
				game.first.health = 100
				game.second.health = 100
				await step()
				if game.boss_ai.tell != "": tells[game.boss_ai.tell] = true
				warning_visible = warning_visible or (game.enemy_warning_label.visible and game.enemy_warning_label.text == game.boss_ai.tell and game.boss_ai.tell != "")
				saw_mark = saw_mark or not game.hazards.marks.is_empty()
				saw_wave = saw_wave or not game.projectiles.is_empty()
			check(tells.size() == 8,"boss cycles eight readable tells")
			check(tells.size() > pac_tell_count,"final boss has more attack patterns than Pac-Man")
			check(saw_wave and saw_mark,"boss wave and camera mark both release")
			check(game.hazards.camera_bugs,"boss arena enables camera bug visuals")
			check(warning_visible,"Dark lord warning is visible in the HUD above the arena artwork")
		for round_index in range(2):
			game.first.health = 100
			game.second.health = 0
			await step()
			if round_index == 0:
				game.next_round()
				game.countdown = 0
		check(game.state == "match_over" and game.rules.scores == [2,0],"journey stage %d requires and records two wins" % (stage+1))
		if stage < 5:
			check(settings.arcade_wins == prior_wins,"stage %d victory gives no premature final reward" % (stage+1))
			game.advance_arcade()
			game.countdown = 0
			if stage == 3:
				check(game.arcade_stage == 4 and game.second.definition.id == "h4ck3r","Pac-Man victory leads to H4CK3R before the final Dark lord")
	check(settings.arcade_wins == prior_wins+1,"only final Dark lord victory persists the journey completion reward")
	game._finish_round()
	check(settings.arcade_wins == prior_wins+1,"repeated final-result callback cannot award the journey twice")
	game.advance_arcade()
	check(game.arcade_stage == 5 and settings.arcade_wins == prior_wins+1,"final stage cannot advance out of bounds or award again")
	print("PASS group: six-stage journey, loss/retry, final boss patterns and single final reward")

func drive_bot(slot: int, frame: int, aggressive: bool = true) -> void:
	var fighter = game.first if slot == 0 else game.second
	var opponent = game.second if slot == 0 else game.first
	var dx = opponent.position.x-fighter.position.x
	var reach = float(fighter.weapon.reach)-18
	var move = signf(dx) if absf(dx)>reach else 0.0
	var attack = absf(dx)<reach+24 and (aggressive or frame%100 < 12)
	var jump = opponent.position.y < fighter.position.y-70 and fighter.is_on_floor()
	var special = aggressive and fighter.cooldown <= 0 and absf(dx)<175
	var dodge = false
	if slot == 0 and game.mode == "arcade" and game.arcade_stage >= 3:
		# A stronger boss requires spacing and reading its visible tells, not stationary spam.
		if opponent.definition.id == "pac_man":
			move = signf(dx) if absf(dx)>240 else -signf(dx) if absf(dx)<220 else 0.0
			attack = absf(dx)<252
			special = fighter.cooldown<=0 and absf(dx)<270
			if game.pac_ai.tell in ["CHARGE!","PELLET SPIT!"] and game.pac_ai.time_left<0.25:
				jump = fighter.is_on_floor()
			if game.pac_ai.state in ["leaping","leap_attack"]: move = -signf(dx)
		elif opponent.definition.id == "h4ck3r":
			# Orange's weapon must actually enter its scaled reach; hovering at
			# 220 pixels lets the enlarged cursor hit while our attacks whiff.
			var attack_reach: float = float(fighter.weapon.reach)-12.0
			move = signf(dx) if absf(dx)>attack_reach-16.0 else 0.0
			attack = absf(dx)<attack_reach+4.0
			special = fighter.cooldown<=0 and absf(dx)<attack_reach+10.0
			if game.hacker_ai.state == "tell":
				# The screen tell locks the cursor and packet facing. Run across
				# the caster during that full warning, then punish recovery.
				move = signf(dx)
				attack = false
				special = false
				if game.hacker_ai.tell == "PACKET BLAST!" and game.hacker_ai.time_left<0.24:
					jump = fighter.is_on_floor()
			elif game.hacker_ai.state == "executing" and opponent.attack_time>=0.12 and opponent.attack_time<0.21 and absf(dx)<float(opponent.weapon.reach)+20.0 and fighter.dodge_cooldown<=0:
				# A late physical sidestep can perfect-evade the committed strike
				# and prepare Orange's ordinary counter hit.
				dodge = true
				move = -signf(dx)
				attack = false
				special = false
		elif opponent.definition.id == "dark_lord":
			if opponent.boss_cast == "reaper" and (game.boss_ai.state == "tell" or (opponent.attack_time >= 0 and opponent.attack_time < float(opponent.attack_spec.windup)+float(opponent.attack_spec.active))):
				move = -opponent.facing
				attack = false
				special = false
				jump = fighter.is_on_floor() and absf(dx)<220
			elif game.boss_ai.tell == "JUMP THE WAVE!" and game.boss_ai.time_left<0.22:
				jump = fighter.is_on_floor()
		for projectile in game.projectiles:
			if projectile.owner_fighter != fighter and absf(projectile.position.x-fighter.position.x)<165:
				jump = jump or fighter.is_on_floor()
		for mark in game.hazards.marks:
			if absf(fighter.position.x-mark.x)<game.hazards.TYPES[mark.kind].width/2+50:
				move = -1 if fighter.position.x<mark.x else 1
				attack = false
				special = false
	if slot == 0 and game.mode == "arcade" and fighter.definition.id == "purple":
		# Switch to the unlocked ranged fighter for the final boss, using visible attack cues.
		move = signf(dx) if absf(dx)>435 else -signf(dx) if absf(dx)<410 else 0.0
		attack = absf(dx)<490
		special = fighter.cooldown<=0 and absf(dx)<650
		if game.boss_ai.tell == "REAPER SWEEP!":
			move = -signf(dx)
			attack = false
			special = false
		if game.boss_ai.tell == "JUMP THE WAVE!" and game.boss_ai.time_left<0.1: jump = fighter.is_on_floor()
		for mark in game.hazards.marks:
			if absf(fighter.position.x-mark.x)<game.hazards.TYPES[mark.kind].width/2+50:
				move = -1 if fighter.position.x<mark.x else 1
				attack = false
				special = false
	if slot == 0 and game.mode == "arcade" and opponent.definition.id == "pac_man":
		# Stay grounded to poke beyond the bite; evade the committed rush on contact.
		if game.pac_ai.tell == "CHARGE!":
			attack = false
			special = false
			jump = false
		if opponent.is_special and opponent.attack_time >= 0 and absf(dx)<280:
			attack = false
			special = false
			jump = false
			if opponent.attack_time >= float(opponent.attack_spec.windup)-0.08 and opponent.attack_time < float(opponent.attack_spec.windup)+float(opponent.attack_spec.active) and absf(dx)<330 and fighter.dodge_cooldown<=0:
				dodge = true
				move = signf(dx)
	command(slot,move,attack,special,jump,dodge)

func test_live_local() -> void:
	for pairing in [["orange","blue"],["purple","yellow"],["yellow","purple"]]:
		await begin("local",pairing[0],pairing[1])
		var frames = 0
		while game.state != "match_over" and frames < 5400:
			if game.state == "round_over":
				bot_rounds += 1
				game.next_round()
				game.countdown = 0
			drive_bot(0,frames,true)
			drive_bot(1,frames,false)
			await step()
			frames += 1
		release_inputs()
		if game.state == "match_over": bot_rounds += 1
		check(game.state == "match_over" and game.rules.finished,"live local input bots complete best-of-three: "+str(pairing))
		check(game.rules.scores[0] >= 2 or game.rules.scores[1] >= 2,"local match ends by actual attacks with two wins")
		print("LIVE_LOCAL fighters=%s frames=%d score=%s" % [str(pairing),frames,str(game.rules.scores)])

func test_live_arcade() -> void:
	release_inputs()
	game.selected[0] = "orange"
	game.optional_hazards = true
	game.start_arcade()
	game.countdown = 0
	var total_frames = 0
	var won_stages = 0
	var start_wins = settings.arcade_wins
	game.ai.rng.seed = 41903
	for stage in range(6):
		var stage_won = false
		for attempt in range(3):
			var frames = 0
			while game.state != "match_over" and frames < 18000:
				if game.state == "round_over":
					bot_rounds += 1
					game.next_round()
					game.countdown = 0
				drive_bot(0,frames,true)
				await step()
				frames += 1
				total_frames += 1
			release_inputs()
			if game.state == "match_over": bot_rounds += 1
			print("LIVE_JOURNEY stage=%d opponent=%s attempt=%d frames=%d score=%s hp=%d/%d" % [stage+1,JOURNEY_OPPONENTS[stage],attempt+1,frames,str(game.rules.scores),game.first.health,game.second.health])
			if game.state == "match_over" and game.rules.last_winner == 0:
				stage_won = true
				break
			if game.state != "match_over": break
			check(game.arcade_stage == stage and settings.arcade_wins == start_wins,"live journey loss retains stage and gives no final reward")
			if attempt < 2:
				live_retries += 1
				game.rematch()
				game.countdown = 0
		if not stage_won: break
		won_stages += 1
		check(game.second.definition.id == JOURNEY_OPPONENTS[stage],"live journey beats the required opponent at stage " + str(stage+1))
		check(root.get_node("Sound")._music_context == ["desktop","quarry","journey_green","pac_man","glitch","dark_lord"][stage],"journey stage uses its own music context")
		if stage < 5:
			check(settings.arcade_wins == start_wins,"live stage %d gives no reward before the final boss" % (stage+1))
			if stage == 4: game.selected[0] = "purple"
			game.advance_arcade()
			game.countdown = 0
	check(won_stages == 6,"live input bot wins all six journey matches through real combat")
	check(settings.arcade_wins == start_wins+1,"real combat six-stage journey completion triggers one final unlock")
	print("LIVE_JOURNEY total_frames=%d won_stages=%d retries=%d" % [total_frames,won_stages,live_retries])
