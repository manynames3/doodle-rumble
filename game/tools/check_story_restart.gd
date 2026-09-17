extends SceneTree
## Run twice with --isolated-qa --qa-profile=<unique-name> --phase=seed/read.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Restart check requires an isolated QA profile")
		quit(1)
		return
	var profile = root.get_node("Chronicle")
	if "--phase=seed" in OS.get_cmdline_user_args():
		profile.checkpoint(3,"purple",false)
		profile.completed.assign([0,1,2])
		if not profile.save_profile(): quit(1); return
		print("RESTART_SEED checks=1 failures=0")
	else:
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.test_mode=true
		game.set_physics_process(false)
		game.resume_story()
		if game.state!="select" or game.arcade_stage!=3 or game.selected[0]!="purple" or game.optional_hazards or profile.completed!=[0,1,2]:
			push_error("Saved chapter did not survive process restart")
			quit(1)
			return
		game.continue_journey()
		if game.state!="playing" or game.second.definition.id!="pac_man" or game.first.health!=game.first.max_health:
			push_error("Resumed chapter did not start a fresh healthy match")
			quit(1)
			return
		print("RESTART_READ checks=2 failures=0")
		game.queue_free()
		await process_frame
	root.get_node("Sound").shutdown()
	quit()
