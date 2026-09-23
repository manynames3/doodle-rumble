extends SceneTree
## Render corrected Pac-Man frames in the real fourth-stage fight scene.
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
	if error != OK: push_error("Pac-Man capture failed: "+name)
	else: print("PACMAN_CAPTURE ",OUT+name+".png")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Pac-Man capture requires isolated QA preferences")
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
	game.arcade_stage = 3
	game.start_match()
	game.countdown = 0.0
	if game.second.definition.id != "pac_man":
		push_error("Fourth story stage did not load Pac-Man")
		quit(1)
		return
	game.first.reset_at(Vector2(360,599))
	game.second.reset_at(Vector2(880,599))
	game.second.facing = -1
	game.second.rig.scale.x = -game.second.body_scale
	game._update_hud()
	var idle := {"grounded":true,"facing":-1,"reduced_motion":false}
	game.second.rig.pose(0.016,idle)
	await _save("pacman_idle")
	var run: Dictionary = idle.duplicate()
	run["velocity"] = Vector2(-280,0)
	game.second.rig.pose(0.016,run)
	await _save("pacman_run")
	var bite: Dictionary = idle.duplicate()
	bite["attack_progress"] = 0.34
	bite["attack_windup_ratio"] = 0.20
	bite["attack_active_ratio"] = 0.40
	bite["special"] = true
	game.second.rig.pose(0.016,bite)
	await _save("pacman_bite")
	var smash: Dictionary = bite.duplicate()
	smash["attack_progress"] = 0.48
	smash["special"] = false
	game.second.rig.pose(0.016,smash)
	await _save("pacman_heavy")
	root.get_node("Sound").shutdown()
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()
