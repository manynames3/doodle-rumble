extends SceneTree
var game
var frames: Array[float] = []
var processes: Array[float] = []
var motion

func _initialize() -> void:
	root.visible = false
	call_deferred("run")

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		quit(1)
		return
	await process_frame
	root.get_node("Settings").reduced_motion = false
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.show_title()
	for child in game.ui.get_children():
		for candidate in child.get_children():
			if candidate.get_script() != null and candidate.get_script().resource_path == "res://scripts/title_motion.gd": motion = candidate
	if motion != null: motion.set_process(false)
	for i in range(60):
		await process_frame
		if motion != null: motion._process(1.0/60.0)
	var last := Time.get_ticks_usec()
	for i in range(1620):
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append(float(now-last)/1000.0)
		var begin_tick := Time.get_ticks_usec()
		if motion != null: motion._process(1.0/60.0)
		processes.append(float(Time.get_ticks_usec()-begin_tick)/1000.0)
		last = now
	print("TITLE_PROFILE frames=%d frame_ms=%s motion_tick_ms=%s renderer=%s" % [frames.size(),summary(frames),summary(processes),RenderingServer.get_video_adapter_name()])
	game.queue_free()
	motion = null
	game = null
	for i in range(3): await process_frame
	viewport.queue_free()
	for i in range(3): await process_frame
	root.get_node("Sound").shutdown()
	OS.delay_msec(150)
	quit()

func summary(values: Array[float]) -> Dictionary:
	values.sort()
	var total := 0.0
	for value in values: total += value
	return {"mean":total/values.size(),"median":values[values.size()/2],"p95":values[int(values.size()*0.95)],"max":values.back()}
