extends SceneTree

const Workshop = preload("res://scripts/doodle_workshop.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280,720)
	var work := Workshop.new()
	root.add_child(work)
	work.build(null)
	work._starter()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_draw.png")
	work._go_step(1)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_life.png")
	work._go_step(2)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_weapon.png")
	work._go_step(3)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_try.png")
	work._select_pose("Special")
	work._preview_clock = 0.65
	work._process(0.0)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_special.png")
	work._go_step(4)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_save.png")
	work._set_source_mode("import")
	work._go_step(0)
	var photo := Image.create_empty(512,512,false,Image.FORMAT_RGB8)
	photo.fill(Color.WHITE)
	for y in range(80,445):
		for x in range(235,278): photo.set_pixel(x,y,Color("#e66a4a"))
	photo.save_png("/tmp/doodle_workshop_photo_source.png")
	work._photo_selected("/tmp/doodle_workshop_photo_source.png")
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_photo.png")
	work._go_step(1)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/doodle_workshop_photo_parts.png")
	work.queue_free()
	await process_frame
	await process_frame
	var sound = root.get_node_or_null("/root/Sound")
	if sound != null: sound.shutdown()
	print("Workshop screenshots captured")
	quit(0)
