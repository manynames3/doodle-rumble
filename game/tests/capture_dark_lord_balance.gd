extends SceneTree
## Actual final-stage telegraphs, released projectiles and active hazard art.
const OUT := "res://../docs/test-results/v0610/visuals/"
var viewport: SubViewport
var game

func _initialize() -> void:
	root.hide()
	call_deferred("run")

func _save(name: String) -> void:
	for _frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = viewport.get_texture().get_image().save_png(OUT+name+".png")
	if error != OK: push_error("Dark lord capture failed: "+name)
	else: print("DARK_LORD_CAPTURE ",OUT+name+".png")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Dark lord capture requires isolated QA preferences")
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
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "arcade"
	game.selected[0] = "orange"
	game.optional_hazards = true
	game.arcade_stage = 5
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(360,599))
	game.second.reset_at(Vector2(900,599))
	game._update_hud()
	for pattern in ["eclipse_volley","eclipse_wave","void_pillar"]:
		game.hazards.clear()
		game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"boss_cast":pattern,"boss_charge":0.78})
		await _save(pattern+"_tell")
		game._boss_pattern(pattern)
		game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"boss_cast":pattern,"boss_charge":1.0})
		if pattern != "eclipse_volley" and not game.hazards.marks.is_empty():
			var mark: Dictionary = game.hazards.marks[0]
			mark.age = float(game.hazards.warning_spec(pattern).tell)+0.08
			game.hazards.queue_redraw()
		await _save(pattern+"_release")
	root.get_node("Sound").shutdown()
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()
