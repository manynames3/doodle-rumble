extends Node
## Isolated native-rendered sweep of every live selection special. The probe
## disables the outer clip so any paint outside the intended page is visible.
const Showcase = preload("res://scripts/fighter_showcase.gd")
const IDS = ["orange", "red", "green", "blue", "purple", "yellow"]
const CAPTURE_FRAMES = [0, 93, 111, 123, 135, 147, 159, 174, 183]
const OUT = "res://../docs/test-results/showcase-fit/"
var viewport: SubViewport

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Showcase capture requires isolated QA preferences.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(1100, 720)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	get_tree().root.add_child(viewport)
	var failures := 0
	for id in IDS:
		var demo = Showcase.new()
		demo.position = Vector2(200, 160)
		demo.size = Vector2(455, 390)
		viewport.add_child(demo)
		demo.configure(id)
		demo.set_process(false)
		# Deliberately expose any paint outside the panel for envelope measurement.
		demo.clip_contents = false
		if "--unclipped-probe" in OS.get_cmdline_user_args(): demo.art_clip.clip_contents = false
		for warmup in range(2): await get_tree().process_frame
		for reduced in ([false] if "--unclipped-probe" in OS.get_cmdline_user_args() else [false,true]):
			get_tree().root.get_node("Settings").reduced_motion = reduced
			demo.clock = 0.0
			var bounds := Rect2i()
			for frame in range(265):
				demo._process(1.0/60.0)
				await get_tree().process_frame
				var image: Image = viewport.get_texture().get_image()
				var used: Rect2i = image.get_used_rect()
				bounds = used if frame == 0 else bounds.merge(used)
				if used.size != Vector2i.ZERO and (used.position.x < 200 or used.position.y < 245 or used.end.x > 655 or used.end.y > 507):
					failures += 1
					if failures <= 8: push_error("%s reduced=%s frame=%d spilled: %s" % [id,reduced,frame,used])
				if (not reduced and frame in CAPTURE_FRAMES) or (reduced and frame == 135):
					var path: String = OUT+"%s_%s_%03d.png" % [id,"reduced" if reduced else "normal",frame]
					var error: Error = image.save_png(path)
					if error != OK: push_error("Cannot save %s: %s" % [path,error])
			print("SHOWCASE_BOUNDS %s reduced=%s %s" % [id,reduced,bounds])
		demo.queue_free()
		await get_tree().process_frame
	if not "--unclipped-probe" in OS.get_cmdline_user_args():
		await _capture_selection_pages()
	print("SHOWCASE_CAPTURE %d fighters x 2 complete 4.4s cycles; spills=%d" % [IDS.size(),failures])
	get_tree().quit(1 if failures > 0 else 0)

func _capture_selection_pages() -> void:
	get_tree().root.get_node("Settings").reduced_motion = false
	viewport.size = Vector2i(1280,720)
	var game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	viewport.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for id in IDS:
		game.selected[0] = id
		game.open_selection("solo")
		var demo: Control = _find_showcase(game)
		if demo == null:
			push_error("Selection page has no showcase for %s" % id)
			continue
		demo.set_process(false)
		demo.clock = 2.25
		demo._process(0.0)
		for warmup in range(3): await get_tree().process_frame
		var path: String = OUT+"selection_full_%s.png" % id
		var error: Error = viewport.get_texture().get_image().save_png(path)
		if error != OK: push_error("Cannot save %s: %s" % [path,error])
	game.queue_free()

func _find_showcase(parent: Node) -> Control:
	if parent.get_script() == Showcase: return parent as Control
	for child in parent.get_children():
		var found := _find_showcase(child)
		if found != null: return found
	return null
