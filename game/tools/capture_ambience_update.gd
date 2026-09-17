extends SceneTree
## Native stills of the ambient arena layer at two points in each animation loop.
## Combat clocks are disabled; this script only verifies the visual pass.
const ARENAS := ["arcade", "desktop", "quarry", "glitch", "canopy"]
const OUT := "res://../docs/test-results/v066/arena-ambience/"
var viewport: SubViewport
var game: Node2D


func _initialize() -> void:
	root.visible = false
	call_deferred("run")


func _save(arena_id: String, moment: String) -> void:
	for _frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var path := OUT + arena_id + "_" + moment + ".png"
	var error: Error = viewport.get_texture().get_image().save_png(path)
	if error != OK: push_error("Could not capture %s: %s" % [path,error])
	else: print("AMBIENCE_CAPTURE ",path)


func _scene(arena_id: String) -> void:
	game.arena_kind = arena_id
	game.selected = ["orange","blue"]
	game.mode = "local"
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0.0
	game.countdown_label.text = ""
	game.set_process(false)
	game.set_physics_process(false)
	game.arena.set_process(false)
	game.arena.reduced_motion = false
	game.arena.elapsed = 0.0
	game.arena.queue_redraw()
	game._process(0.0)
	await _save(arena_id,"rest")
	game.arena.elapsed = 6.0
	game.arena.queue_redraw()
	game._process(0.0)
	await _save(arena_id,"motion")


func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Ambience capture requires isolated preferences")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.test_mode = true
	for arena_id in ARENAS:
		await _scene(arena_id)
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("AMBIENCE_CAPTURE_OK ",OUT)
	quit()
