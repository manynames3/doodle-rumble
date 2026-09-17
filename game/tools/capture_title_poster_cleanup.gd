extends SceneTree
## Native title-screen QA capture for the intro-poster cleanup.
## Uses an isolated preference profile and the same 1280x720 viewport as the game.
var viewport: SubViewport
var game
var output: String

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Title capture requires isolated preferences")
		quit(1)
		return
	output = "res://../docs/test-results/v067/title"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			output = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.show_title()
	for _i in range(8):
		await process_frame
	var path := output.path_join("title_clean.png")
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Title capture failed: %s" % path)
	else:
		print("TITLE_CAPTURE_OK "+path)
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	quit(0)
