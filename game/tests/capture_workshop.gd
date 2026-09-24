extends SceneTree

const Workshop = preload("res://scripts/doodle_workshop.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _stroke(image: Image, start: Vector2, finish: Vector2, width: float, color: Color) -> void:
	var radius := width * 0.5
	var left := maxi(0,floori(minf(start.x,finish.x)-radius))
	var right := mini(image.get_width()-1,ceili(maxf(start.x,finish.x)+radius))
	var top := maxi(0,floori(minf(start.y,finish.y)-radius))
	var bottom := mini(image.get_height()-1,ceili(maxf(start.y,finish.y)+radius))
	var delta := finish-start
	for y in range(top,bottom+1):
		for x in range(left,right+1):
			var point := Vector2(x,y)
			var t := clampf((point-start).dot(delta)/maxf(0.001,delta.length_squared()),0.0,1.0)
			if point.distance_squared_to(start+delta*t) <= radius*radius:
				image.set_pixel(x,y,color)

func _paper_fighter() -> Image:
	var photo := Image.create_empty(512,512,false,Image.FORMAT_RGBA8)
	photo.fill(Color.WHITE)
	var ink := Color("d2a620")
	var center := Vector2(256,100)
	var last := center+Vector2(45,0)
	for i in range(1,49):
		var angle := TAU*float(i)/48.0
		var next := center+Vector2(cos(angle),sin(angle))*45.0
		_stroke(photo,last,next,12.0,ink)
		last = next
	for limb in [
		[Vector2(256,146),Vector2(256,205),Vector2(256,305)],
		[Vector2(256,174),Vector2(195,215),Vector2(158,267)],
		[Vector2(256,174),Vector2(320,214),Vector2(357,265)],
		[Vector2(256,300),Vector2(216,365),Vector2(185,444)],
		[Vector2(256,300),Vector2(296,365),Vector2(327,444)]
	]:
		for i in range(limb.size()-1):
			_stroke(photo,limb[i],limb[i+1],12.0,ink)
	return photo

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
	var photo := _paper_fighter()
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
