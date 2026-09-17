extends SceneTree
## Hidden native screenshots of the actual match result, with isolated preferences.
const OUT = "res://../docs/test-results/v064/"
const DT = 1.0 / 60.0
var viewport: SubViewport
var game

func _initialize() -> void:
	root.unfocusable = true
	root.hide()
	call_deferred("run")

func _save(name: String, frames: int = 5) -> void:
	for i in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	var path: String = OUT + name + ".png"
	var error: Error = image.save_png(path)
	if error != OK: push_error("Could not capture " + path)
	else: print("RESULT_CAPTURE ", path, " ", image.get_size())

func _begin(first_id: String, second_id: String, stage: int = -1) -> void:
	game.mode = "arcade" if stage >= 0 else "local"
	game.arcade_stage = stage if stage >= 0 else 0
	game.selected = [first_id, second_id]
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0.0
	game.first.position = Vector2(250,599)
	game.second.position = Vector2(1000,599)
	game.first.update_art(0.0)
	game.second.update_art(0.0)
	game._update_hud()

func _finish(winner: int) -> void:
	if winner == 0: game.second.health = 0
	else: game.first.health = 0
	game._physics_process(DT)
	if game.state != "round_over": push_error("Round did not finish for capture")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Result capture requires isolated QA preferences")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	_begin("orange","blue")
	await _save("round_playing",8)
	_finish(0)
	await _save("round_result_orange_wins",24)
	await _save("round_result_orange_wins_later",34)
	_begin("red","dark_lord",5)
	_finish(0)
	await _save("round_result_dark_lord_loses",24)
	_begin("red","dark_lord",5)
	_finish(1)
	await _save("round_result_dark_lord_wins",24)
	root.get_node("Settings").reduced_motion = true
	game.first.update_art(0.0)
	game.second.update_art(0.0)
	await _save("round_result_reduced_motion",5)
	root.get_node("Sound").shutdown()
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()
