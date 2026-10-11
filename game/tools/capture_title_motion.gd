extends SceneTree
## Native Godot renders only. Never loads or saves the family profile.
var viewport: SubViewport
var game
var output := "res://../docs/test-results/menu-motion"
var checks := 0
var captures := 0
var failures: Array[String] = []

func _initialize() -> void:
	root.visible = "--small-window-only" in OS.get_cmdline_user_args()
	if root.visible: root.title = "Doodle Rumble — isolated menu QA"
	call_deferred("run")

func capture_small_window() -> void:
	root.get_node("Settings").reduced_motion = true
	root.get_node("Settings").master_volume = 0.0
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.show_title()
	# Resize after project startup has applied its configured window overrides.
	root.size = Vector2i(854,480)
	for i in range(20): await process_frame
	var image := root.get_texture().get_image()
	check(root.size == Vector2i(854,480),"actual game window resized to 854x480")
	check(image.get_width() in [853,854] and image.get_height() == 480,"native keep-aspect render fits resized window")
	captures += 1
	if image.save_png(output.path_join("small_window.png")) != OK:
		failures.append("small window capture failed")
		push_error(failures.back())
	game.queue_free()
	for i in range(3): await process_frame
	root.get_node("Sound").shutdown()
	# Let the native audio mix thread release stopped WAV playback before exit.
	OS.delay_msec(150)
	print("TITLE_MOTION_SMALL_WINDOW checks=%d captures=%d failures=%d output=%s" % [checks,captures,failures.size(),output])
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func title_menu() -> Control:
	for child in game.ui.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://scripts/title_menu.gd":
			return child
	return null

func tap_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	viewport.push_input(event,true)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	viewport.push_input(event,true)
	await process_frame

func capture(path: String) -> Image:
	var image := viewport.get_texture().get_image()
	var saved_image: Image = image.get_region(Rect2i(0,630,1280,90)) if path.begins_with("frames/") or path.begins_with("mirror/") else image
	captures += 1
	if saved_image.save_png(output.path_join(path)) != OK:
		failures.append("capture failed: "+path)
		push_error(failures.back())
	return image

func run() -> void:
	if "--isolated-qa" not in OS.get_cmdline_user_args():
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	await process_frame
	if "--small-window-only" in OS.get_cmdline_user_args():
		await capture_small_window()
		return
	root.get_node("Settings").reduced_motion = false
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
	game.show_title()
	for i in range(8): await process_frame
	var menu := title_menu()
	check(menu != null,"title menu present")
	var positions: Array[Vector2] = []
	for button in menu.buttons: positions.append(button.position)
	var stable_positions := true
	# Actual 60-Hz menu frames. Captures sample every four frames (15 fps).
	for frame in range(1620):
		await process_frame
		if frame % 4 == 0: await capture("frames/%04d.png" % (frame/4))
		if frame in [40,400,650]: await capture("key_%04d.png" % frame)
		for i in range(menu.buttons.size()):
			if menu.buttons[i].position != positions[i]:
				stable_positions = false
	check(stable_positions,"button hitboxes stay fixed throughout animation")
	# Focus changes stay immediate and preserve every control's hit area.
	for i in range(menu.buttons.size()):
		menu.buttons[i].grab_focus()
		await process_frame
		check(menu.buttons[i].has_focus(),"focus reaches button %d" % i)
		await capture("focus_%d.png" % i)
	await tap_action("ui_right")
	check(menu.buttons[0].has_focus(),"right navigation wraps from Quit to Story Mode")
	await tap_action("ui_left")
	check(menu.buttons[5].has_focus(),"left navigation wraps from Story Mode to Quit")
	for i in range(menu.buttons.size()):
		var event := InputEventMouseMotion.new()
		event.position = menu.buttons[i].position + menu.buttons[i].size * 0.5
		viewport.push_input(event,true)
		await process_frame
		check(menu.buttons[i].has_focus(),"mouse hover focuses button %d" % i)
	var leave_hover := InputEventMouseMotion.new()
	leave_hover.position = Vector2(640,100)
	viewport.push_input(leave_hover,true)
	# Settings on the right makes the repeating choreography mirror to the left.
	DirAccess.make_dir_recursive_absolute(output.path_join("mirror"))
	menu.buttons[4].grab_focus()
	for frame in range(780):
		await process_frame
		if frame % 4 == 0: await capture("mirror/%04d.png" % (frame/4))
	for i in range(90):
		menu.buttons[i % menu.buttons.size()].grab_focus()
		await process_frame
	check(menu.buttons.back().has_focus(),"rapid focus ends at requested choice")
	root.get_node("Settings").reduced_motion = true
	await process_frame
	var still: Image = await capture("reduced_motion.png")
	for i in range(90): await process_frame
	var next: Image = await capture("reduced_motion_later.png")
	check(still.get_data() == next.get_data(),"reduced motion is visually static")
	menu.buttons[0].grab_focus()
	await process_frame
	check(menu.buttons[0].has_focus(),"reduced motion keeps instant focus")
	await capture("reduced_focus.png")
	var prior: WeakRef = weakref(menu)
	await tap_action("ui_accept")
	for i in range(3): await process_frame
	check(game.state == "journal","accept activates Story Mode without animation delay")
	check(prior.get_ref() == null,"menu and owned motion leave the tree on navigation")
	root.get_node("Settings").reduced_motion = false
	game.show_title()
	for i in range(3): await process_frame
	menu = title_menu()
	var baseline_count := menu.get_child_count()
	var baseline_nodes := get_node_count()
	for i in range(20):
		game.open_settings()
		for frame in range(3): await process_frame
		game.show_title()
		for frame in range(3): await process_frame
		check(title_menu().get_child_count() == baseline_count,"repeated entry keeps bounded child count")
	check(get_node_count() == baseline_nodes,"repeated entry keeps total scene node count stable")
	game.queue_free()
	game = null
	for frame in range(3): await process_frame
	viewport.queue_free()
	for frame in range(3): await process_frame
	root.get_node("Sound").shutdown()
	OS.delay_msec(150)
	print("TITLE_MOTION_CAPTURE checks=%d captures=%d failures=%d output=%s" % [checks,captures,failures.size(),output])
	quit(0 if failures.is_empty() else 1)
