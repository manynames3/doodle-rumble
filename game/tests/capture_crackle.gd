extends SceneTree
## Real physics frames for Crackle's tells, projectiles, story, journal and results.
const OUT := "res://../docs/test-results/crackle/"
const DT := 1.0 / 60.0
var viewport: SubViewport
var game

func _initialize() -> void:
	root.hide()
	call_deferred("run")

func _save(name: String) -> void:
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = viewport.get_texture().get_image().save_png(OUT + name + ".png")
	if error != OK: push_error("Crackle capture failed: " + name)
	else: print("CRACKLE_CAPTURE ", OUT + name + ".png")

func _step(frames: int) -> void:
	for frame in range(frames):
		await physics_frame
		game._physics_process(DT)

func _prepare_pattern(index: int) -> void:
	for shot in game.projectiles: game._discard_projectile(shot)
	game.projectiles.clear()
	game.first.reset_at(Vector2(360, 599))
	game.second.reset_at(Vector2(890, 599))
	game.crackle_ai.reset()
	game.crackle_ai.pattern = index
	game.crackle_ai.state = "approach"
	game.crackle_ai.time_left = 0.0

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Crackle capture requires isolated QA preferences")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
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
	game.mode = "arcade"
	game.selected[0] = "orange"
	game.optional_hazards = false
	game.arcade_stage = 3
	game.start_match()
	game.countdown = 0.0
	game.first.reset_at(Vector2(360, 599))
	game.second.reset_at(Vector2(890, 599))
	await _step(18)
	game._update_hud()
	await _save("idle")
	for index in range(3):
		var pattern: String = ["rocket_single", "firecracker_arc", "firework_fan"][index]
		_prepare_pattern(index)
		await _step(35)
		game._update_hud()
		await _save(pattern + "_tell")
		for frame in range(40):
			await _step(1)
			if game.crackle_ai.state == "released": break
		await _step(2)
		game._update_hud()
		await _save(pattern + "_release")
		if index == 2:
			var old_motion: bool = root.get_node("Settings").reduced_motion
			root.get_node("Settings").reduced_motion = true
			game._process(DT)
			game.first.update_art(0.0)
			game.second.update_art(0.0)
			await _save("firework_fan_reduced_motion")
			root.get_node("Settings").reduced_motion = old_motion
			game._process(DT)
		if index == 1:
			await _step(27)
			game._update_hud()
			await _save("firecracker_pop")
		else:
			await _step(10)
			game._update_hud()
			await _save(pattern + "_in_flight")
		game._update_hud()
		await _save(pattern + "_recovery")
		if index == 0:
			for frame in range(75):
				await _step(1)
				if game.first.health < game.first.max_health:
					await _save("rocket_single_impact")
					break
	_prepare_pattern(3)
	game.first.reset_at(Vector2(750, 599))
	game.second.reset_at(Vector2(890, 599))
	await _step(28)
	game._update_hud()
	await _save("spear_tell")
	for frame in range(30):
		await _step(1)
		if game.crackle_ai.state == "executing": break
	await _step(12)
	game._update_hud()
	await _save("spear_impact")
	for frame in range(48):
		await _step(1)
		if game.crackle_ai.state == "recovery": break
	game._update_hud()
	await _save("spear_recovery")
	var original_motion: bool = root.get_node("Settings").reduced_motion
	for winner in [0, 1, 2]:
		root.get_node("Settings").reduced_motion = winner == 2
		game.start_match()
		game.countdown = 0.0
		game._process(DT)
		game.first.position = Vector2(250, 599)
		game.second.position = Vector2(1000, 599)
		game.first.update_art(0.0)
		game.second.update_art(0.0)
		if winner == 0: game.second.health = 0
		else: game.first.health = 0
		game._physics_process(DT)
		for frame in range(42): game._process(DT)
		await _save("defeated" if winner == 0 else "victory_reduced_motion" if winner == 2 else "victory")
	root.get_node("Settings").reduced_motion = original_motion
	var journal: Node = root.get_node("Chronicle")
	var saved_completed: Array[int] = journal.completed.duplicate()
	var saved_active: bool = journal.active
	var saved_stage: int = journal.stage
	journal.completed.assign([0, 1, 2])
	journal.active = true
	journal.stage = 3
	game.show_story_hub()
	await _save("journal_eight_chapters")
	journal.completed.assign(saved_completed)
	journal.active = saved_active
	journal.stage = saved_stage
	game._show_story_scene(false, func(): pass, 3)
	await _save("story_before")
	game.story_scene.index = 2
	game.story_scene._show_line()
	await _save("story_before_final_line")
	game._show_story_scene(true, func(): pass, 3)
	await _save("story_after")
	game.story_scene.index = 2
	game.story_scene._show_line()
	await _save("story_after_final_line")
	root.get_node("Sound").shutdown()
	game.queue_free()
	viewport.queue_free()
	await process_frame
	quit()
