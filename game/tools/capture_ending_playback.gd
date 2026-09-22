extends SceneTree
## Inspect actual Godot Theora decoding after re-encoding the movie.
const OUT = "res://../docs/test-results/asset-pack-ending/"

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Movie playback capture requires isolated QA preferences")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var player := VideoStreamPlayer.new()
	player.size = Vector2(1280,720)
	player.expand = true
	player.stream = load("res://assets/cinematics/ending.ogv")
	player.volume_db = -80.0
	viewport.add_child(player)
	player.play()
	for second in [3.0,11.5,21.5,27.5]:
		player.stream_position = second
		for _frame in range(14): await process_frame
		await RenderingServer.frame_post_draw
		var path: String = OUT+"movie_%02d.png" % int(second)
		var error: Error = viewport.get_texture().get_image().save_png(path)
		if error != OK: push_error("Cannot capture movie at %s" % second)
		else: print("ENDING_PLAYBACK_CAPTURE ",path)
	player.stop()
	root.get_node("Sound").shutdown()
	quit()
