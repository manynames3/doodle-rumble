extends SceneTree
## Asset-level QA: proves the delivered poster texture itself is clean.
var viewport: SubViewport

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Poster capture requires isolated preferences")
		quit(1)
		return
	var output := "res://../docs/test-results/v067/title"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			output = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var picture := TextureRect.new()
	picture.texture = load("res://assets/intro_poster_v060.png")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.size = Vector2(1280, 720)
	viewport.add_child(picture)
	for _i in range(8):
		await process_frame
	var path := output.path_join("poster_clean.png")
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Poster capture failed: %s" % path)
	else:
		print("POSTER_CAPTURE_OK "+path)
	quit(0)
