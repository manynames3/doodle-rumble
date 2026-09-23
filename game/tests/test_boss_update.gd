extends SceneTree
## Uses the same isolated preferences configuration as the other integration suites.
var checks = 0
var failures = 0
var game
const DT = 1.0/60
func _initialize(): call_deferred("run")
func check(value, label):
	checks += 1
	if not value: failures += 1; push_error("FAIL: "+label)
func step(frames):
	for i in range(frames):
		await physics_frame
		game._physics_process(DT)
func run():
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	var settings = root.get_node("Settings")
	var old_motion = settings.reduced_motion
	var old_wins = settings.arcade_wins
	game.mode = "arcade"
	game.optional_hazards = false
	game.arcade_stage = 4
	game.start_match()
	game.countdown = 0
	game.first.reset_at(Vector2(450,599))
	game.second.reset_at(Vector2(770,599))
	check(game.second.definition.id == "h4ck3r","sixth journey inserts H4CK3R at stage five")
	check(is_equal_approx(game.second.body_scale,game.first.BODY_SCALE*1.25) and is_equal_approx(absf(game.second.rig.scale.x),game.first.BODY_SCALE*1.25),"H4CK3R's body and rig render at 125 percent of standard scale")
	check(is_equal_approx(game.second.hurtbox().size.x,float(game.second.definition.get("hurtbox_width",46))*game.first.BODY_SCALE*1.25),"H4CK3R's hurtbox follows the enlarged body scale")
	check(not root.get_node("Data").ORDER.has("h4ck3r"),"six selectable fighters remain distinct from story bosses")
	check(root.get_node("Sound")._music_context == "glitch","H4CK3R receives the unique Glitch stage score")
	game.second.start_attack(false)
	check(int(game.second.attack_spec.damage) == 23,"H4CK3R cursor strike has 25 percent more damage")
	game.second.attack_time = -1
	game.second.start_attack(true)
	check(int(game.second.attack_spec.damage) == 33,"H4CK3R packet attack payload rounds up to 33")
	var packet = load("res://scripts/attack_effect.gd").new()
	game.world.add_child(packet)
	packet.configure(game.second,"signal",-1)
	check(packet.damage == 33,"the moving packet blast scales exactly once")
	packet.queue_free()
	game.second.attack_time = -1
	var tells = {}
	var kinds = {}
	var shots = {}
	var hacker_damage = 0
	for frame in range(2400):
		game.first.health = 100
		game.second.health = game.second.max_health
		await step(1)
		hacker_damage += 100-game.first.health
		if game.hacker_ai.tell != "": tells[game.hacker_ai.tell] = true
		for m in game.hazards.marks: kinds[m.kind] = true
		for projectile in game.projectiles: shots[projectile.kind] = true
	check(tells.size() == 7,"H4CK3R executes all seven warned patterns")
	check(kinds.has("cursor_stamp") and kinds.has("eraser_drop") and kinds.has("ink_geyser") and kinds.has("firewall_scan"),"H4CK3R uses all four creative hazards")
	check(shots.has("signal") and shots.has("checksum_volley"),"H4CK3R releases packet and checksum projectiles")
	game.hacker_ai.state = "tell"
	game.hacker_ai.tell = "PACKET BLAST!"
	game.hacker_ai.time_left = 0.1
	game.second.hurt_time = 0.18
	var decision = game.hacker_ai.read_input(DT,game.second,game.first)
	check(not decision.special and game.hacker_ai.tell == "" and game.hacker_ai.state == "rest","interrupting the boss cancels the tell and grants recovery")
	game.second.hurt_time = 0.0
	game.second.reset_at(Vector2(500,599))
	game.first.reset_at(Vector2(730,599))
	game.hacker_ai.reset()
	game.hacker_ai.pattern = 5
	game.hacker_ai.state = "approach"
	game.hacker_ai.read_input(DT,game.second,game.first)
	check(game.hacker_ai.tell == "CHECKSUM VOLLEY!" and game.second.boss_cast == "checksum_volley","volley starts with a distinctive visible cast")
	var shots_before: int = game.projectiles.size()
	game.first.position.x = 280
	for frame in range(46):
		game.hacker_ai.read_input(DT,game.second,game.first)
	check(game.projectiles.size() == shots_before,"crossing behind cannot skip the full checksum warning")
	for frame in range(3):
		game.hacker_ai.read_input(DT,game.second,game.first)
	check(game.projectiles.size() == shots_before+3 and game.second.facing == 1,"volley releases three non-homing shots in its committed direction")
	game.second.reset_at(Vector2(500,599))
	game.first.reset_at(Vector2(730,599))
	game.hacker_ai.reset()
	game.hacker_ai.pattern = 0
	game.hacker_ai.state = "approach"
	game.hacker_ai.time_left = 0.0
	game.hacker_ai.read_input(DT,game.second,game.first)
	check(game.hacker_ai.tell == "CURSOR STRIKE!","cursor lunge has a full visible pre-attack tell")
	game.first.position.x = 100
	var lunge_command: Dictionary = {}
	for frame in range(49):
		var read: Dictionary = game.hacker_ai.read_input(DT,game.second,game.first)
		if read.attack: lunge_command = read
	check(bool(lunge_command.get("attack",false)) and bool(lunge_command.get("lock_facing",false)) and game.second.facing == 1,"crossing behind the cursor warning cannot reverse the lunge")
	var lunge_start: float = game.second.position.x
	for frame in range(12):
		var read: Dictionary = lunge_command if frame == 0 else game.hacker_ai.read_input(DT,game.second,game.first)
		game.second.tick(DT,read,game.first)
	check(game.second.position.x > lunge_start+100 and game.first.health == 100,"committed cursor lunge travels forward and is avoided by crossing behind")
	game.hazards.clear()
	game.first.reset_at(Vector2(640,599))
	game.second.reset_at(Vector2(640,599))
	game.hazards.mark_target(640,0,"firewall_scan","h4ck3r")
	game.hazards.mark_target(760,0,"eraser_drop","h4ck3r")
	check(game.hazards.marks.size() == 1 and game.hazards.pending.size() == 1,"firewall still obeys the one-zone hazard rule")
	game.hazards.tick(1.24,[game.first,game.second])
	check(game.first.health == 100,"firewall has its full harmless warning")
	game.hazards.tick(0.02,[game.first,game.second])
	check(game.first.health == 77 and game.second.health == game.second.max_health,"firewall hits once for scaled 23 damage and spares its caster")
	game.first.invulnerable = 0.0
	game.hazards.tick(0.04,[game.first,game.second])
	check(game.first.health == 77,"firewall cannot repeat damage within one active zone")
	game.hazards.clear()
	game.first.reset_at(Vector2(640,599))
	game.hazards.mark_target(640,0,"firewall_scan","h4ck3r")
	game.first.position.x = 840
	game.hazards.tick(1.27,[game.first,game.second])
	check(game.first.health == 100,"player can sidestep the marked firewall")
	game.hazards.clear()
	for kind in ["cursor_stamp","ink_geyser","eraser_drop"]:
		game.first.reset_at(Vector2(640,599))
		game.hazards.mark_target(640,0,kind,"h4ck3r")
		var spec: Dictionary = game.hazards.TYPES[kind]
		game.hazards.tick(float(spec.tell)+0.02,[game.first,game.second])
		var baseline: int = int(game.hazards.HACKER_SIGNATURE_DAMAGE[kind])
		check(game.first.health == 100-ceili(float(baseline)*1.25),"H4CK3R's %s has its scaled boss-only payload" % kind)
		game.hazards.clear()
	var checksum_damage := []
	for delta in [1.0/30.0,1.0/60.0,1.0/120.0]:
		game.second.reset_at(Vector2(400,599))
		game.first.reset_at(Vector2(650,599))
		var shot = load("res://scripts/boss_projectile.gd").new()
		game.world.add_child(shot)
		shot.configure(game.second,"checksum_volley",1)
		for frame in range(160):
			if shot.tick(delta,game.first): break
		checksum_damage.append(100-game.first.health)
		game.first.invulnerable = 0.0
		shot.tick(delta,game.first)
		check(100-game.first.health == checksum_damage[-1],"checksum projectile is consumed after one hit")
		shot.queue_free()
	check(checksum_damage == [25,25,25],"scaled checksum damage is stable across fixed-step sampling")
	game.second.reset_at(Vector2(400,599))
	game.first.reset_at(Vector2(650,350))
	var jumping_shot = load("res://scripts/boss_projectile.gd").new()
	game.world.add_child(jumping_shot)
	jumping_shot.configure(game.second,"checksum_volley",1)
	for frame in range(160):
		if jumping_shot.tick(DT,game.first): break
	check(game.first.health == 100,"jumping completely above a checksum lane avoids the shot")
	jumping_shot.queue_free()
	game.arcade_stage = 3
	game.start_match()
	game.countdown = 0
	game.first.reset_at(Vector2(450,599))
	game.second.reset_at(Vector2(770,599))
	var pac_damage = 0
	for frame in range(2400):
		game.first.health = 100
		game.second.health = game.second.max_health
		await step(1)
		pac_damage += 100-game.first.health
	print("BOSS_STAGE_PRESSURE pac_40s=%d hacker_40s=%d" % [pac_damage,hacker_damage])
	check(hacker_damage > pac_damage,"H4CK3R deals more passive-opponent pressure than preceding Pac-Man stage")
	game.arcade_stage = 5
	game.start_match()
	game.countdown = 0
	game.first.reset_at(Vector2(450,599))
	game.second.reset_at(Vector2(770,599))
	var dark_damage: int = 0
	var dark_patterns := {}
	for frame in range(2400):
		game.first.health = 100
		game.second.health = game.second.max_health
		await step(1)
		dark_damage += 100-game.first.health
		if game.boss_ai.tell != "": dark_patterns[game.boss_ai.tell] = true
	print("BOSS_STAGE_PRESSURE hacker_40s=%d dark_lord_40s=%d patterns=%d" % [hacker_damage,dark_damage,dark_patterns.size()])
	check(dark_patterns.size() == 8,"Dark lord delivers all eight distinct attack patterns in the final-stage cycle")
	check(dark_damage > hacker_damage,"Dark lord exerts more pressure than H4CK3R in the same 40-second passive test")
	check(is_equal_approx(game.second.body_scale,game.first.body_scale*1.5),"Dark lord body is exactly fifty percent larger")
	check(is_equal_approx(absf(game.second.rig.scale.x),game.second.body_scale),"Dark lord rig matches his physical scale")
	check(is_equal_approx(game.second.hurtbox().size.y,game.first.hurtbox().size.y*1.5),"Dark lord hurtbox scales with his visible body")
	check(is_equal_approx(game.second.get_child(0).shape.height,110*game.second.body_scale),"Dark lord collision capsule scales with his body")
	game.mode = "training"
	game.selected = ["orange","blue"]
	game.start_match()
	game.countdown = 0
	await step(6)
	game.first.reset_at(Vector2(460,599))
	game.second.reset_at(Vector2(570,599))
	game.first.start_attack(false)
	await step(12)
	var numbers = game.juice.words.filter(func(w): return w.get("damage",false))
	check(numbers.size() == 1 and numbers[0].text == "−13","successful basic hit displays its actual attack damage")
	var before = numbers.size()
	game.second.take_hit(13,1)
	check(game.juice.words.filter(func(w): return w.get("damage",false)).size() == before,"blocked repeated contact does not show false damage")
	game.second.invulnerable = 0
	game.second.take_hit(24,1)
	check(game.juice.words.any(func(w): return w.get("damage",false) and w.text == "−24"),"special damage displays a numeric amount")
	game.juice.reduced_motion = true
	var p = game.juice.words[-1].p
	game.juice._process(0.1)
	check(game.juice.words[-1].p == p,"reduced motion holds numbers still while fading")
	for kind in ["camera","cursor_stamp","eraser_drop","ink_geyser"]:
		for reduced in [false,true]:
			var hz = game.hazards
			hz.clear()
			hz.camera_bugs = false
			hz.reduced_motion = reduced
			game.first.reset_at(Vector2(640,599))
			game.second.reset_at(Vector2(1000,599))
			hz.mark_target(640,0,kind)
			hz.mark_target(900,0,"camera")
			check(hz.marks.size() == 1,kind+" rejects unsafe simultaneous hazard spam")
			var spec = hz.TYPES[kind]
			hz.tick(spec.tell-0.01,[game.first,game.second])
			check(game.first.health == 100,kind+" complete warning is harmless")
			var age = hz.marks[0].age
			game.pause_game()
			game._physics_process(DT)
			check(hz.marks[0].age == age,kind+" warning is frozen on pause")
			game.resume_game()
			hz.tick(0.02,[game.first,game.second])
			check(game.first.health == 91 and game.second.health == 100,kind+" only damages inside the marked region")
			game.first.invulnerable = 0
			hz.tick(0.04,[game.first,game.second])
			check(game.first.health == 91,kind+" damages once even without recovery protection")
			hz.tick(1,[game.first,game.second])
			check(hz.marks.is_empty(),kind+" cleans up after its active window")
			hz.mark_target(640,0,kind,"orange")
			game.first.reset_at(Vector2(640,599))
			hz.tick(spec.tell+0.01,[game.first,game.second])
			check(game.first.health == 100,kind+" respects boss-owner immunity")
			hz.clear()
			# Jumping completely above a low hazard is safe, independent of artwork.
			if kind == "ink_geyser":
				game.first.reset_at(Vector2(640,530))
				hz.mark_target(640,0,kind)
				hz.tick(spec.tell+0.01,[game.first,game.second])
				check(game.first.health == 100,"ink is safely jumpable")
	check(settings.arcade_wins == old_wins,"boss and hazard QA grants no completion reward")
	settings.reduced_motion = old_motion
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	await create_timer(0.1).timeout
	print("TEST_RESULT checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
