extends SceneTree
## Native-rendered stills from the same source used for the encoded movie.
const Story = preload("res://scripts/ending_storyboard.gd")
const OUT = "res://../docs/test-results/ending_review_"
var viewport: SubViewport
var story: Node2D

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		push_error("Ending capture requires isolated QA preferences")
		quit(1)
		return
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	story = Story.new()
	story.manual = true
	viewport.add_child(story)
	var captions = load("res://scripts/ending_captions.gd").new()
	captions.story = story
	viewport.add_child(captions)
	for shot in range(6):
		story.seek(shot*5.0+2.5)
		for frame in range(4): await process_frame
		var path := OUT + str(shot) + ".png"
		var error := viewport.get_texture().get_image().save_png(path)
		if error != OK: push_error("Capture failed: %s" % path)
		else: print("CAPTURE ", path)
	quit()
