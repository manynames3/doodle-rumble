extends SceneTree
## Hidden native-rendered match stills using isolated settings and silent audio.
const OUT = "res://../docs/test-results/"
var viewport: SubViewport
var game: Node2D

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Match capture requires isolated QA preferences.")
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
	game.selected = ["orange","blue"]
	game.open_selection("local")
	await _save("fighter_selection_ink.png")
	game.mode = "local"
	game.arena_kind = "desktop"
	game.selected = ["orange","blue"]
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0
	game._update_hud()
	game.first.reset_at(Vector2(408,599))
	game.second.reset_at(Vector2(856,599))
	game.first.rig.pose(0.016,{"grounded":true,"facing":1,"attack_progress":0.35,"attack_windup_ratio":0.20,"attack_active_ratio":0.45,"special":true,"reduced_motion":false})
	game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"reduced_motion":false})
	await _save("fighter_match_spin.png")
	game.selected = ["purple","red"]
	game.start_match()
	game.countdown = 0
	game._update_hud()
	game.first.reset_at(Vector2(408,599))
	game.second.reset_at(Vector2(856,599))
	game.first.rig.pose(0.016,{"grounded":true,"facing":1,"dodging":true,"dodge_progress":0.35,"shield_guard":true,"shield_perfect":true,"shield_progress":0.45,"reduced_motion":false})
	game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"attack_progress":0.32,"attack_windup_ratio":0.18,"attack_active_ratio":0.40,"special":false,"reduced_motion":false})
	await _save("fighter_match_guard.png")
	quit()

func _save(name: String) -> void:
	for frame in range(5): await process_frame
	var path: String = OUT+name
	var texture: Texture2D = viewport.get_texture()
	if texture == null:
		push_error("Capture viewport has no texture")
		return
	var error: Error = texture.get_image().save_png(path)
	if error != OK: push_error("Could not capture %s: %s" % [path,error])
	else: print("CAPTURE ",path)
