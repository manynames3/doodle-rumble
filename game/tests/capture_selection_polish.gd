extends SceneTree
## Native-rendered selection review in an isolated QA profile.
const IDS = ["orange", "red", "green", "blue", "purple", "yellow"]
var viewport: SubViewport
var game
var output := "/tmp/doodle-selection-polish"

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Selection capture requires isolated QA preferences")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.mode = "local"
	for id in IDS:
		game.selected.assign([id,"yellow" if id != "yellow" else "purple"])
		game.selecting_player = 0
		game.open_selection("local")
		await _shot("selection_%s" % id,2.25)
	game.selecting_player = 1
	game.selected.assign(["orange","purple"])
	game.open_selection("local")
	await _shot("selection_player_2",2.25)
	root.get_node("Settings").reduced_motion = true
	game.open_selection("local")
	await _shot("selection_reduced_motion",2.25)
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("SELECTION_POLISH_CAPTURE_OK " + output)
	quit()

func _shot(label: String, showcase_time: float) -> void:
	var showcase: Control = _find_showcase(game)
	if showcase == null:
		push_error("No fighter showcase for " + label)
		return
	showcase.set_process(false)
	showcase.clock = showcase_time
	showcase._process(0.0)
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = viewport.get_texture().get_image().save_png(output.path_join(label+".png"))
	if error != OK: push_error("Could not save " + label + ": " + str(error))

func _find_showcase(parent: Node) -> Control:
	if parent.get_script() != null and parent.get_script().resource_path == "res://scripts/fighter_showcase.gd": return parent as Control
	for child in parent.get_children():
		var found: Control = _find_showcase(child)
		if found != null: return found
	return null
