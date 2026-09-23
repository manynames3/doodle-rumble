extends SceneTree
## Native round_over captures and geometry checks at the real result spawns.
const OUT = "res://../docs/test-results/v069-motion/"
const DT = 1.0/60.0
var viewport: SubViewport
var game
var failures: int = 0

func _initialize() -> void:
	root.hide()
	call_deferred("run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Result edge: " + message)

func _save(name: String) -> void:
	for _i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var err: Error = viewport.get_texture().get_image().save_png(OUT+name+".png")
	_check(err == OK,"capture " + name)
	if err == OK: print("RESULT_EDGE_CAPTURE ",OUT+name+".png")

func _begin() -> void:
	game.mode = "arcade"
	game.arcade_stage = 5
	game.selected = ["red","dark_lord"]
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
	_check(game.state == "round_over","actual match enters round_over")

func _advance(seconds: float) -> void:
	for _i in range(ceili(seconds/DT)):
		game._process(DT)

func _check_fallen_inside(fighter, label: String) -> void:
	var body: Sprite2D = fighter.rig.packed_art.body
	var xf: Transform2D = body.get_global_transform()
	var pixels: Image = body.texture.get_image()
	var min_x: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	for y in range(0,pixels.get_height(),4):
		for x in range(0,pixels.get_width(),4):
			if pixels.get_pixel(x,y).a < 0.08: continue
			var point: Vector2 = xf*Vector2(x,y)
			min_x = minf(min_x,point.x)
			max_x = maxf(max_x,point.x)
			max_y = maxf(max_y,point.y)
	_check(min_x >= 0.0 and max_x <= 1280.0,label + " sprite stays inside both screen edges (%.1f..%.1f)" % [min_x,max_x])
	_check(max_y <= 610.0 and max_y >= 570.0,label + " silhouette meets the arena floor (%.1f)" % max_y)
	var star_x: float = fighter.position.x + fighter.rig.scale.x * fighter.rig.packed_art.visual_head.x
	_check(star_x >= 60.0 and star_x <= 1220.0,label + " orbiting stars stay in view")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Result edge capture requires isolated QA preferences")
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
	_begin()
	_finish(0)
	_check(absf(game.second.rig.packed_art.result_age) < 0.03,"Dark lord fall begins at age zero")
	_advance(0.72)
	_check_fallen_inside(game.second,"Right-side Dark lord")
	_check(game.first.rig.packed_art.shown_frame == "idle","winner rests between hops")
	await _save("right_fallen_dark_lord")
	_advance(0.67)
	_check(game.first.rig.packed_art.shown_frame == "jump_takeoff","round_over loop repeats the winner hop")
	await _save("right_fallen_dark_lord_later")
	var winner_age: float = game.first.rig.packed_art.result_age
	game.set_process(true)
	await create_timer(0.18).timeout
	game.set_process(false)
	_check(game.first.rig.packed_art.result_age > winner_age+0.08,"native automatic round_over processing advances celebration")
	_begin()
	_finish(1)
	_check(absf(game.first.rig.packed_art.result_age) < 0.03,"Red fall begins at age zero")
	_advance(0.72)
	_check_fallen_inside(game.first,"Left-side Red")
	await _save("left_fallen_red")
	_advance(0.67)
	_check(game.second.rig.packed_art.shown_frame == "jump_takeoff","Dark lord winner hops again in round_over")
	await _save("left_fallen_red_later")
	root.get_node("Sound").shutdown()
	game.queue_free()
	viewport.queue_free()
	await process_frame
	print("RESULT_EDGE_TEST failures=%d" % failures)
	quit(0 if failures == 0 else 1)
