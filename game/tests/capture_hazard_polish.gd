extends SceneTree
## Native game-frame evidence. Run with -- --isolated-qa --silent-qa.

const OUT = "res://../docs/test-results/"
var viewport: SubViewport
var game: Node2D

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Hazard capture requires isolated QA preferences.")
		quit(1)
		return
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
	game.mode = "local"
	game.optional_hazards = false
	await _scene("canopy", ["orange","green"], "paper_swarm", 640, "hazard_canopy_warning_after.png")
	await _scene("canopy", ["orange","green"], "paper_swarm", 640, "hazard_canopy_active_after.png", 1.67)
	await _scene("canopy", ["orange","green"], "", 640, "story_route_canopy.png")
	await _scene("arcade", ["orange","blue"], "", 640, "story_route_arcade.png")
	await _scene("network", ["orange","purple"], "circuit_zip", 837, "hazard_network_warning_after.png")
	await _scene("network", ["orange","purple"], "", 640, "story_route_network.png")
	await _scene("quarry", ["blue","red"], "eraser_drop", 640, "hazard_quarry_warning_after.png")
	game.queue_free()
	await process_frame
	quit()

func _scene(arena: String, fighters: Array, kind: String, x: float, filename: String, age: float = 0.64) -> void:
	game.arena_kind = arena
	game.selected = fighters
	game.start_match()
	game.countdown = 0.0
	game.countdown_label.text = ""
	game.first.reset_at(Vector2(410,599))
	game.second.reset_at(Vector2(862,599))
	game.hazards.clear()
	if not kind.is_empty():
		game.hazards.mark_target(x,0,kind)
		game.hazards.marks[0].age = age
	game.hazards.queue_redraw()
	game.hazards.warning_overlay.queue_redraw()
	for frame in range(6): await process_frame
	var path: String = OUT + filename
	var err: Error = viewport.get_texture().get_image().save_png(path)
	if err != OK: push_error("Could not capture %s: %s" % [path,err])
	else: print("CAPTURE ",path)
