extends SceneTree
## Native-only QA with its own viewport and preferences. Never opens a player window.
var viewport: SubViewport
var game
var output: String
func _initialize() -> void:
	root.visible = false
	call_deferred("run")
func shot(label: String) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Capture requires isolated preferences")
		quit(1)
		return
	output = OS.get_user_data_dir().path_join("selection-captures")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.selected.assign(["orange","purple"])
	game.open_selection("solo")
	await shot("Fighters_easy")
	game.selected.assign(["green","yellow"])
	game.open_selection("solo")
	await shot("Fighters_green_yellow")
	game.difficulty_level = 2
	game.open_selection("solo")
	await shot("Fighters_hard")
	game.open_stage_selection()
	await shot("Stages_quick")
	game.mode = "local"
	game.arena_kind = "canopy"
	game.open_stage_selection()
	await shot("Stages_2p")
	game.new_journey_selection()
	await shot("Story_difficulty")
	var chronicle = root.get_node("Chronicle")
	chronicle.active = true
	chronicle.stage = 5
	chronicle.fighter = "yellow"
	chronicle.completed.assign([0,1,2,3,4])
	chronicle.challenges.assign([0,2,4])
	game.show_story_hub()
	await shot("Story_progress")
	chronicle.active = false
	chronicle.completed.clear()
	chronicle.challenges.clear()
	game.show_story_hub()
	await shot("Story_empty")
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("SELECTION_CAPTURE_OK "+output)
	quit()
