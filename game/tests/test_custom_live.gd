extends "res://tests/test_game.gd"
## Real physics and mapped player input; no forced health, damage or scoring.
func run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("QA"):
		quit(1)
		return
	settings=root.get_node("Settings")
	settings.hold_to_attack=true
	settings.reduced_motion=true
	var library=root.get_node("Doodles")
	var ids: Array[String]=[]
	for kit in ["bone","ball"]:
		var record: Dictionary=library.new_record()
		record.kit=kit
		ids.append(library.save_record(record))
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode=true
	game.set_process(false)
	game.set_physics_process(false)
	for pairing in [[ids[0],ids[1]],[ids[1],"blue"],["orange",ids[0]]]:
		await begin("local" if pairing[0]!= "orange" else "solo",pairing[0],pairing[1])
		var frames:=0
		while game.state!="match_over" and frames<12000:
			if game.state=="round_over":
				game.next_round()
				game.countdown=0
			drive_bot(0,frames,true)
			if game.mode=="local": drive_bot(1,frames,false)
			await step()
			frames+=1
		release_inputs()
		check(game.state=="match_over" and game.rules.finished,"Custom match finishes through real damage and round rules")
		check(game.first.total_damage+game.second.total_damage>0,"Mapped input lands real custom/original attacks")
		print("CUSTOM_LIVE mode=%s frames=%d score=%s" % [game.mode,frames,game.rules.scores])
		game.start_match()
		check(game.projectiles.is_empty() and not game.first.thrown_weapon_hidden,"Rematch clears returning/bouncing effects")
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("CUSTOM_LIVE_TEST_RESULT checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
