extends SceneTree
## Native hidden-viewport captures of packed boss art in its actual story stages.
const OUT = "res://../docs/test-results/asset-pack-bosses/"
var viewport: SubViewport
var game

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func _save(name: String) -> void:
	for _frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = viewport.get_texture().get_image().save_png(OUT+name+".png")
	if error != OK: push_error("Cannot save boss pack capture: " + name)
	else: print("PACK_BOSS_CAPTURE ",name)

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Pack capture requires isolated QA preferences")
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
	for stage in [3,4,5]:
		game.arcade_stage = stage
		game.start_match()
		game.countdown = 0.0
		game._update_hud()
		game.first.reset_at(Vector2(362,599))
		game.second.reset_at(Vector2(886,599))
		game.first.rig.pose(0.016,{"grounded":true,"facing":1})
		var command := "" if stage == 3 else "firewall_scan" if stage == 4 else "void_orb"
		game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"boss_cast":command,"boss_charge":0.69,"attack_progress":0.37 if stage == 3 else -1.0,"attack_windup_ratio":0.2,"attack_active_ratio":0.4})
		await _save(["pac_man","h4ck3r","dark_lord"][stage-3])
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	quit()
