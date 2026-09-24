extends SceneTree
## Frame capture for the composite paper edge and joint-deformed source colors.
const Art = preload("res://scripts/custom_art.gd")
const Library = preload("res://scripts/custom_library.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	root.size = Vector2i(640, 540)
	var image := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(145, 175, 119, 115), Color("27a45a"))
	image.fill_rect(Rect2i(208, 61, 96, 92), Color("dd3929"))
	image.fill_rect(Rect2i(242, 177, 28, 125), Color("3875d9"))
	var path := "user://custom_art_test_%d.png" % Time.get_ticks_usec()
	image.save_png(path)
	var record_library := Library.new()
	var record: Dictionary = record_library.new_record()
	record.strokes = []
	record.photo_path = path
	record.photo_parts = {"head":[[208,61],[304,61],[304,153],[208,153]],
		"left_arm":[[251,175],[264,187],[158,291],[144,279]],
		"body":[[242,177],[270,177],[270,302],[242,302]]}
	var canvas := ColorRect.new()
	canvas.color = Color("5c6670")
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var art := Art.new()
	art.position = Vector2(320, 468)
	art.scale = Vector2.ONE * 2.0 # Enlarge the QA capture to inspect joint edges.
	canvas.add_child(art)
	art.configure(record)
	art.pose_preview({"reduced_motion":true})
	for bind_sample in [
		["head",Vector2(270,110)], ["body",Vector2(270,235)],
		["left_arm",Vector2(205,220)], ["right_arm",Vector2(310,220)],
		["left_leg",Vector2(230,355)], ["right_leg",Vector2(290,355)],
		["left_arm",Vector2(160,270)], ["right_leg",Vector2(315,430)]]:
		var part: String = bind_sample[0]
		var sample: Vector2 = bind_sample[1]
		if art._deform(part,sample,art._is_distal(part,sample)).distance_to(art._canvas_to_local(sample)) > 0.01:
			push_error("Bind pose mirrors or shifts %s" % part)
			quit(1)
			return
	var initial_head: Vector2 = art._deform("head", Vector2(256, 105))
	art._posed.head += Vector2(12, -4)
	art.refresh_art()
	var moved_head: Vector2 = art._deform("head", Vector2(256, 105))
	if moved_head.distance_to(initial_head + Vector2(12, -4)) > 0.01 or art._photo == null:
		push_error("Custom photo did not bind to the posed head")
		quit(1)
		return
	var elbow := Vector2(327, 235)
	var before_joint: Vector2 = art._deform("right_arm", elbow, false)
	var after_joint: Vector2 = art._deform("right_arm", elbow, true)
	if before_joint.distance_to(after_joint) > 0.01 or not art._is_distal("right_arm", Vector2(350, 265)):
		push_error("Upper and lower photo cutouts tore at the elbow")
		quit(1)
		return
	art._posed.head = Vector2(0, -145)
	art._posed.front_hand = Vector2(88, -50)
	art.refresh_art()
	var raised_top: Vector2 = art._viewport_point(art._deform("head", Vector2(256, 61)))
	var extended_hand: Vector2 = art._viewport_point(art._deform("right_arm", Vector2(362, 280), true))
	if raised_top.y < 12 or extended_hand.x > 628:
		push_error("Padded cutout clips a victory or extended attack pose")
		quit(1)
		return
	art.pose_preview()
	var drawn_record: Dictionary = record_library.new_record()
	drawn_record.name = "Cache QA"
	var first_drawn := Art.new()
	canvas.add_child(first_drawn)
	first_drawn.configure(drawn_record)
	for _frame in 32: await process_frame
	var cache: Dictionary = root.get_meta("custom_art_texture_cache",{})
	var cached_entry: Dictionary = cache.get(first_drawn._art_cache_key,{})
	var baked_segments := 0
	for key in cached_entry.keys():
		if key != "_strokes_by_segment": baked_segments += 1
	var all_visible := true
	for node in first_drawn._segment_nodes.values(): all_visible = all_visible and node.visible
	var second_drawn := Art.new()
	canvas.add_child(second_drawn)
	second_drawn.configure(drawn_record)
	var reused_pages := second_drawn._static_viewports.is_empty()
	for node in second_drawn._segment_nodes.values(): reused_pages = reused_pages and node.visible
	if baked_segments < 6 or not all_visible or not reused_pages:
		push_error("Custom segment cache did not finish and reuse the drawn fighter pages")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		print("CUSTOM_ART_TEST_RESULT checks=12 failures=0 geometry=pass source_photo=pass segment_cache=pass render=requires_display")
		canvas.queue_free()
		record_library.free()
		root.get_node("Sound").shutdown()
		await process_frame
		quit(0)
		return
	for i in 4: await process_frame
	for i in 2: await process_frame
	var output := OS.get_environment("CUSTOM_ART_SCREENSHOT")
	if not output.is_empty(): root.get_texture().get_image().save_png(output)
	var composed: Image = art.get_node("PosedCutoutComposite").get_texture().get_image()
	var display: Image = root.get_texture().get_image()
	var red_found := false
	var paper_found := false
	for y in range(display.get_height()):
		for x in range(display.get_width()):
			var color := display.get_pixel(x, y)
			if color.r > 0.65 and color.g < 0.35 and color.b < 0.30: red_found = true
			if color.r > 0.90 and color.g > 0.88 and color.b > 0.85: paper_found = true
	var head_sample: Vector2 = art._viewport_point(art._deform("head",Vector2(255,105)))
	var body_sample: Vector2 = art._viewport_point(art._deform("body",Vector2(255,235)))
	var ok := composed.get_pixelv(Vector2i(head_sample)).a > 0.8 and composed.get_pixelv(Vector2i(body_sample)).a > 0.8 and red_found and paper_found
	art._posed.head = Vector2(0,-145)
	art._posed.back_elbow = Vector2(-65,-93)
	art._posed.back_hand = Vector2(-83,-62)
	art.refresh_art()
	for i in 3: await process_frame
	var extreme: Image = art.get_node("PosedCutoutComposite").get_texture().get_image()
	var head_center: Vector2 = art._viewport_point(art._posed.head)
	ok = ok and extreme.get_pixelv(Vector2i(head_center)).a > 0.8
	var extreme_output := OS.get_environment("CUSTOM_ART_EXTREME_SCREENSHOT")
	if not extreme_output.is_empty(): root.get_texture().get_image().save_png(extreme_output)
	var plain_record: Dictionary = record.duplicate(true)
	plain_record.photo_settings = {"paper_edge":false}
	art.configure(plain_record)
	var no_edge: bool = is_zero_approx(float(art.get_node("PaperCutout").material.get_shader_parameter("edge_opacity")))
	ok = ok and no_edge
	print("CUSTOM_ART_TEST_RESULT checks=9 failures=%d size=%s head_alpha=%.2f body_alpha=%.2f paper=%s edge_off=%s" % [0 if ok else 1, str(composed.get_size()), composed.get_pixelv(Vector2i(head_sample)).a, composed.get_pixelv(Vector2i(body_sample)).a, str(paper_found), str(no_edge)])
	canvas.queue_free()
	record_library.free()
	root.get_node("Sound").shutdown()
	await process_frame
	quit(0 if ok else 1)
