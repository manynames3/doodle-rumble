extends SceneTree
## Actual story-stage views of boss telegraph and fixed-controller release art.
const OUT = "res://../docs/test-results/v069-motion/"
var viewport: SubViewport
var game

func _initialize() -> void:
	root.hide()
	call_deferred("run")

func _save(name: String) -> void:
	for _frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var err: Error = viewport.get_texture().get_image().save_png(OUT+name+".png")
	if err != OK: push_error("Boss cue capture failed: " + name)
	else: print("BOSS_RELEASE_CAPTURE ", OUT+name+".png")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Boss cue capture requires isolated QA preferences")
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
	game.optional_hazards = false
	for pattern in ["firewall_scan","void_orb","rift"]:
		game.arcade_stage = 4 if pattern == "firewall_scan" else 5
		game.start_match()
		game.countdown = 0.0
		game._update_hud()
		game.first.reset_at(Vector2(362,599))
		game.second.reset_at(Vector2(886,599))
		game.first.rig.pose(0.016,{"grounded":true,"facing":1})
		game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"boss_cast":pattern,"boss_charge":0.75})
		await _save(pattern+"_tell")
		game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"boss_cast":pattern,"boss_charge":1.0})
		await _save(pattern+"_release")
	root.get_node("Sound").shutdown()
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()
