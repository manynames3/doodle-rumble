extends SceneTree
## Native hidden-viewport QA for a drawn fighter and an original synthetic photo cutout.
const Rig = preload("res://scripts/fighter_rig.gd")
const Layout = preload("res://scripts/arena_layout.gd")
const OUT_ROOT := "res://../docs/test-results/v074/weapon-art/"
const POSES := ["IDLE", "WALK", "JUMP", "ATTACK", "VICTORY", "DEFEAT"]
const PARTS := ["head", "body", "left_arm", "right_arm", "left_leg", "right_leg"]
const SKIN := Color("d9956b")
const SHIRT := Color("3c9dc3")
var out_dir := OUT_ROOT
var first_kit := "bat"
var second_kit := "bone"
var checks := 0
var failures: Array[String] = []
var contact: SubViewport
var contact_rigs: Array[Node2D] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--kit-p1="):
			first_kit = argument.trim_prefix("--kit-p1=")
		elif argument.begins_with("--kit-p2="):
			second_kit = argument.trim_prefix("--kit-p2=")
	if first_kit != "bat" or second_kit != "bone":
		out_dir = OUT_ROOT + first_kit + "-" + second_kit + "/"
	root.hide()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("CUSTOM_NATIVE_QA FAIL: " + message)

func _poly(image: Image, raw: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	var left := 511
	var right := 0
	var top := 511
	var bottom := 0
	for pair in raw:
		var point := Vector2(float(pair[0]),float(pair[1]))
		polygon.append(point)
		left = mini(left, floori(point.x))
		right = maxi(right, ceili(point.x))
		top = mini(top, floori(point.y))
		bottom = maxi(bottom, ceili(point.y))
	for y in range(maxi(0,top),mini(511,bottom)+1):
		for x in range(maxi(0,left),mini(511,right)+1):
			if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon): image.set_pixel(x,y,color)

func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	for y in range(maxi(0,floori(center.y-radius)),mini(511,ceili(center.y+radius))+1):
		for x in range(maxi(0,floori(center.x-radius)),mini(511,ceili(center.x+radius))+1):
			if Vector2(x+0.5,y+0.5).distance_squared_to(center) <= radius*radius: image.set_pixel(x,y,color)

func _photo_parts() -> Dictionary:
	return {
		"head":[[255,47],[222,51],[196,69],[189,99],[197,130],[217,154],[246,169],[272,166],[298,145],[313,117],[310,86],[291,60]],
		"body":[[227,167],[278,167],[301,186],[306,282],[282,308],[231,308],[205,283],[209,190]],
		"left_arm":[[231,177],[250,191],[202,246],[163,292],[143,275],[180,215]],
		"right_arm":[[267,190],[284,176],[336,218],[370,274],[350,293],[308,246]],
		"left_leg":[[230,292],[256,304],[229,392],[202,469],[178,464],[200,377]],
		"right_leg":[[258,303],[284,291],[314,378],[340,466],[317,471],[283,392]]
	}

func _make_source_image(parts: Dictionary) -> Image:
	var image := Image.create_empty(512,512,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_poly(image,parts.left_leg,Color("4e8f63"))
	_poly(image,parts.right_leg,Color("547aaf"))
	_poly(image,parts.left_arm,Color("e3a477"))
	_poly(image,parts.right_arm,Color("e3a477"))
	_poly(image,parts.body,SHIRT)
	_poly(image,parts.head,SKIN)
	# Original, deliberately varied source colors and small clothing details.
	_poly(image,[[221,53],[256,44],[292,56],[310,87],[294,79],[263,69],[228,76],[196,91],[201,72]],Color("624b40"))
	_disc(image,Vector2(229,111),8,Color("fff6d5"))
	_disc(image,Vector2(279,111),8,Color("fff6d5"))
	_disc(image,Vector2(231,111),3.4,Color("27252c"))
	_disc(image,Vector2(277,111),3.4,Color("27252c"))
	_poly(image,[[233,134],[251,140],[274,134],[268,147],[251,150],[237,145]],Color("803f3e"))
	_poly(image,[[220,191],[233,181],[244,260],[231,270]],Color("f5c45e"))
	_poly(image,[[272,181],[285,190],[278,268],[265,261]],Color("f5c45e"))
	_poly(image,[[221,273],[289,273],[286,286],[222,286]],Color("31536f"))
	_poly(image,[[180,448],[203,453],[201,471],[177,470]],Color("3b3a4e"))
	_poly(image,[[316,453],[340,447],[343,469],[317,473]],Color("3b3a4e"))
	return image

func _drawn_record() -> Dictionary:
	var record: Dictionary = root.get_node("Doodles").new_record()
	record.name = "Crayon Captain"
	record.color = "#f4a343"
	record.kit = first_kit
	var strokes: Array = record.strokes
	# Substantial hollow head and limb silhouette come from starter_strokes.
	for eye_x in [233,280]:
		strokes.append({"part":"head","color":"#171827","width":5,"points":[[eye_x,99],[eye_x+2,106]],"detail":true})
	strokes.append({"part":"head","color":"#171827","width":4,"points":[[229,129],[246,137],[266,136],[283,127]],"detail":true})
	for i in range(10):
		var y: int = 193+i*10
		strokes.append({"part":"body","color":"#e36c73" if i%2==0 else "#fff3ad","width":4,"points":[[239,y],[273,y-4]],"detail":true})
	for i in range(8):
		var along: float = float(i)/7.0
		for arm in ["left_arm","right_arm"]:
			var start := Vector2(256,185) if arm == "right_arm" else Vector2(256,185)
			var finish := Vector2(362,280) if arm == "right_arm" else Vector2(150,280)
			var center: Vector2 = start.lerp(finish,along)
			strokes.append({"part":arm,"color":"#26345b","width":3,"points":[[center.x-7,center.y-5],[center.x+5,center.y+5]],"detail":true})
	for i in range(7):
		var y: int = 322+i*18
		strokes.append({"part":"left_leg","color":"#ffffff","width":4,"points":[[231-i*5,y],[244-i*5,y+4]],"detail":true})
		strokes.append({"part":"right_leg","color":"#ffffff","width":4,"points":[[269+i*5,y],[281+i*5,y+4]],"detail":true})
	strokes.append({"part":"left_leg","color":"#171827","width":6,"points":[[175,459],[202,459]],"detail":true})
	strokes.append({"part":"right_leg","color":"#171827","width":6,"points":[[310,459],[340,459]],"detail":true})
	record.strokes = strokes
	return record

func _state(kind: String, time: float) -> Dictionary:
	var base := {"grounded":true,"facing":1,"reduced_motion":false}
	match kind:
		"WALK": base.velocity = Vector2(240,0)
		"JUMP":
			base.grounded = false
			base.velocity = Vector2(95,-340)
		"ATTACK":
			base.attack_progress = 0.32
			base.attack_windup_ratio = 0.20
			base.attack_active_ratio = 0.35
		"VICTORY":
			base.victory = true
			base.presentation_time = time
		"DEFEAT":
			base.defeated = true
			base.presentation_time = time
	return base

func _label(parent: Node, title: String, at: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = title
	label.position = at
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)

func _save_viewport(viewport: SubViewport, filename: String) -> void:
	for _i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(out_dir+filename)
	check(error == OK,"save " + filename)
	if error == OK: print("CUSTOM_NATIVE_CAPTURE ",out_dir+filename)

func _build_contact(drawn_id: String, photo_id: String) -> void:
	contact = SubViewport.new()
	contact.size = Vector2i(1920,820)
	contact.transparent_bg = false
	contact.disable_3d = true
	contact.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(contact)
	var paper := ColorRect.new()
	paper.color = Color("cabfa9")
	paper.size = Vector2(1920,820)
	contact.add_child(paper)
	for row in 2:
		var desk := ColorRect.new()
		desk.color = Color("6e6462")
		desk.position = Vector2(0,373+row*382)
		desk.size = Vector2(1920,5)
		contact.add_child(desk)
		_label(contact,"CRAYON CAPTAIN  /  DRAWN" if row == 0 else "PATCHWORK PAL  /  PHOTO CUTOUT",Vector2(24,72+row*382),25,Color("29212c"))
	for column in range(6):
		_label(contact,POSES[column],Vector2(107+column*303,18),22,Color("302832"))
		for row in 2:
			var rig: Node2D = Rig.new()
			contact.add_child(rig)
			rig.configure(root.get_node("Data").fighter(drawn_id if row == 0 else photo_id))
			rig.position = Vector2(158+column*303,370+row*382)
			rig.scale = Vector2.ONE * 1.44
			var state := _state(POSES[column],0.34 if POSES[column] == "VICTORY" else 0.43)
			for _step in 24: rig.pose(1.0/60.0,state)
			contact_rigs.append(rig)
			check(rig.custom_art != null and rig.custom_art.is_rendering(),"custom art rendered in " + POSES[column])

func _photo_pixels_preserved(photo_rig: Node2D) -> void:
	var art: Node2D = photo_rig.custom_art
	var image: Image = art.get_node("PosedCutoutComposite").get_texture().get_image()
	var head_at: Vector2 = art._viewport_point(art._deform("head",Vector2(256,105)))
	var shirt_at: Vector2 = art._viewport_point(art._deform("body",Vector2(249,238)))
	var head_color: Color = image.get_pixelv(Vector2i(head_at))
	var shirt_color: Color = image.get_pixelv(Vector2i(shirt_at))
	print("CUSTOM_PHOTO_SAMPLE head=",head_color," expected=",SKIN," shirt=",shirt_color," expected=",SHIRT," edge=",art.get_node("PaperCutout").material.get_shader_parameter("edge_pixels"))
	check(absf(head_color.r-SKIN.r)<0.07 and absf(head_color.g-SKIN.g)<0.07 and absf(head_color.b-SKIN.b)<0.07,"original skin color preserved")
	check(absf(shirt_color.r-SHIRT.r)<0.07 and absf(shirt_color.g-SHIRT.g)<0.07 and absf(shirt_color.b-SHIRT.b)<0.07,"original shirt color preserved")
	var neck_at: Vector2 = art._viewport_point(art._posed.head.lerp(art._posed.shoulder,0.60))
	check(image.get_pixelv(Vector2i(neck_at)).a > 0.8,"photo head and torso form one cutout without a white joint band")
	for part in ["left_arm","right_arm","left_leg","right_leg"]:
		var joint_name := "back_elbow" if part == "left_arm" else "front_elbow" if part == "right_arm" else "left_knee" if part == "left_leg" else "right_knee"
		var at: Vector2 = art._viewport_point(art._posed[joint_name])
		check(image.get_pixelv(Vector2i(at)).a > 0.35,"photo " + part + " joint remains joined")
	check(float(art.get_node("PaperCutout").material.get_shader_parameter("edge_pixels")) >= 5.5,"paper margin remains active on imported photo")

func _measure_native_frames(drawn_id: String, photo_id: String) -> Dictionary:
	var perf := SubViewport.new()
	perf.size = Vector2i(1280,720)
	perf.disable_3d = true
	perf.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(perf)
	var background := ColorRect.new()
	background.size = Vector2(1280,720)
	background.color = Color("cfc4ad")
	perf.add_child(background)
	var rigs: Array[Node2D] = []
	for index in 2:
		var rig: Node2D = Rig.new()
		perf.add_child(rig)
		rig.configure(root.get_node("Data").fighter(drawn_id if index == 0 else photo_id))
		rig.position = Vector2(370+index*480,570)
		rig.scale = Vector2.ONE * 1.2
		rigs.append(rig)
	var frame_ms: Array[float] = []
	var pose_ms: Array[float] = []
	for frame in range(300):
		var begin := Time.get_ticks_usec()
		var kind: String = ["IDLE","WALK","JUMP","ATTACK"][int(frame/30)%4]
		var state := _state(kind,float(frame)/60.0)
		for rig in rigs: rig.pose(1.0/60.0,state)
		pose_ms.append(float(Time.get_ticks_usec()-begin)/1000.0)
		await process_frame
		await RenderingServer.frame_post_draw
		frame_ms.append(float(Time.get_ticks_usec()-begin)/1000.0)
	frame_ms.sort()
	pose_ms.sort()
	await _save_viewport(perf,"custom_fighters_render_benchmark.png")
	var total := 0.0
	for value in frame_ms: total += value
	var summary := {"frames":300,"mean_ms":total/300.0,"median_ms":frame_ms[150],"p95_ms":frame_ms[284],"max_ms":frame_ms[-1],"pose_median_ms":pose_ms[150],"pose_p95_ms":pose_ms[284]}
	perf.queue_free()
	await process_frame
	return summary

func _capture_actual_scenes(drawn_id: String, photo_id: String) -> void:
	var scene_viewport := SubViewport.new()
	scene_viewport.size = Vector2i(1280,720)
	scene_viewport.disable_3d = true
	scene_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(scene_viewport)
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	scene_viewport.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.selected = [drawn_id,photo_id]
	game.selecting_player = 0
	game.selection_tab = "custom"
	game.open_selection("local")
	await _save_viewport(scene_viewport,"custom_fighters_my_doodles.png")
	game.mode = "local"
	game.arena_kind = "desktop"
	game.optional_hazards = false
	game.start_match()
	game.countdown = 0
	game._update_hud()
	game.first.reset_at(Vector2(425,599))
	game.second.reset_at(Vector2(851,599))
	game.first.rig.pose(0.016,{"grounded":true,"facing":1,"attack_progress":0.32,"attack_windup_ratio":0.20,"attack_active_ratio":0.35,"special":true,"reduced_motion":false})
	game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"reduced_motion":false})
	await _save_viewport(scene_viewport,"custom_fighters_actual_match.png")
	check(game.selected[0] == drawn_id and game.selected[1] == photo_id and game.first.rig.custom_art.is_rendering() and game.second.rig.custom_art.is_rendering(),"real main scene match uses both saved custom fighters")
	if first_kit == "rubber_chicken" and second_kit == "giant_crayon":
		# Show the new weapon specials on two real desktop platforms, not as a
		# detached effect sheet. The combat tests separately verify fixed-tick hits.
		game.first.reset_at(Vector2(250,480))
		game.second.reset_at(Vector2(1010,370))
		game.first.facing = 1
		game.second.facing = -1
		check(game.first.start_attack(true) and game.second.start_attack(true),"both new special poses start in the scene capture")
		game.first.rig.pose(0.016,{"grounded":true,"facing":1,"attack_progress":0.50,"attack_windup_ratio":0.37,"attack_active_ratio":0.13,"special":true,"reduced_motion":false})
		game.second.rig.pose(0.016,{"grounded":true,"facing":-1,"attack_progress":0.50,"attack_windup_ratio":0.35,"attack_active_ratio":0.13,"special":true,"reduced_motion":false})
		var chicken_fx = load("res://scripts/custom_projectile.gd").new()
		game.world.add_child(chicken_fx)
		chicken_fx.configure(game.first,"cluckquake",1,Layout.PLATFORMS)
		chicken_fx.elapsed = 0.18
		chicken_fx.z_index = 6
		var crayon_fx = load("res://scripts/custom_projectile.gd").new()
		game.world.add_child(crayon_fx)
		crayon_fx.configure(game.second,"rainbow_ruckus",-1,Layout.PLATFORMS)
		crayon_fx.elapsed = 0.20
		crayon_fx.z_index = 6
		check(is_equal_approx(chicken_fx.attack_surface_y,480.0) and is_equal_approx(crayon_fx.attack_surface_y,370.0),"special effects anchor to each fighter's own platform")
		check(chicken_fx.hitbox().has_area() and crayon_fx.hitbox().has_area(),"both signature effects render during their active damage window")
		await _save_viewport(scene_viewport,"custom_weapons_special_attacks.png")
		chicken_fx.cleanup()
		crayon_fx.cleanup()
		chicken_fx.queue_free()
		crayon_fx.queue_free()
	game.queue_free()
	scene_viewport.queue_free()
	await process_frame

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		push_error("Native custom capture requires an isolated QA profile and displayed renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var drawn := _drawn_record()
	check(drawn.strokes.size() >= 50,"drawn fighter has detailed strokes")
	var drawn_id: String = root.get_node("Doodles").save_record(drawn)
	check(not drawn_id.is_empty(),"drawn fighter saved in isolated sketchbook")
	var parts := _photo_parts()
	var source := _make_source_image(parts)
	check(source.save_png("user://synthetic_photo_source.png") == OK,"synthetic photo source created")
	check(source.save_png(out_dir+"synthetic_photo_source.png") == OK,"reviewable original source saved")
	var photo: Dictionary = root.get_node("Doodles").new_record()
	photo.name = "Patchwork Pal"
	photo.color = "#3c9dc3"
	photo.kit = second_kit
	photo.strokes = []
	photo.photo_path = "user://synthetic_photo_source.png"
	photo.source_path = "user://synthetic_photo_source.png"
	photo.photo_parts = parts
	photo.photo_settings = {"fixture":"original authored paper human","margin_world_px":2.5}
	var photo_id: String = root.get_node("Doodles").save_record(photo)
	check(not photo_id.is_empty(),"six-part photo cutout saved with owned source")
	if drawn_id.is_empty() or photo_id.is_empty():
		print("CUSTOM_NATIVE_QA_RESULT checks=%d failures=%d" % [checks,failures.size()])
		quit(1)
		return
	check(root.get_node("Doodles").get_record(drawn_id).strokes[-1].get("detail",false),"detail metadata survives save")
	check(root.get_node("Doodles").get_record(photo_id).photo_parts.size() == PARTS.size(),"all six photo parts survive save")
	_build_contact(drawn_id,photo_id)
	await _save_viewport(contact,"custom_fighters_six_poses.png")
	check(contact_rigs[0].custom_art.get_node("PaperCutout").material == null,"drawn fighter skips the paper shader")
	check(contact_rigs[0].custom_art.get_node("PosedCutoutComposite").render_target_update_mode == SubViewport.UPDATE_ONCE,"posed cutout updates only when requested")
	_photo_pixels_preserved(contact_rigs[1])
	# Free every contact-sheet rig and its nested art viewport before the timing
	# loop. UPDATE_DISABLED on the parent alone does not stop those children.
	contact.queue_free()
	contact_rigs.clear()
	await process_frame
	var perf: Dictionary = await _measure_native_frames(drawn_id,photo_id)
	await _capture_actual_scenes(drawn_id,photo_id)
	var report := "Native custom fighter QA\nHardware: %s\nOS: %s\nDisplay driver: %s\nRenderer: %s\nGPU adapter: %s\nIsolated QA: yes\nFighters: 2 detailed, drawn strokes=%d, photo parts=6\nBenchmark: two articulated fighters in an isolated hidden SubViewport (not the full game scene)\nFrames: %d\nFrame wall time including render/vsync (ms): mean=%.2f, median=%.2f, p95=%.2f, max=%.2f\nPose CPU per two rigs (ms): median=%.3f, p95=%.3f\nFull main scene captures: My Doodles selection and local match, both using saved custom fighter IDs.\nChecks: %d, failures: %d\n" % [OS.get_processor_name(),OS.get_name(),DisplayServer.get_name(),str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),RenderingServer.get_video_adapter_name(),drawn.strokes.size(),perf.frames,perf.mean_ms,perf.median_ms,perf.p95_ms,perf.max_ms,perf.pose_median_ms,perf.pose_p95_ms,checks,failures.size()]
	var file := FileAccess.open(out_dir+"custom_fighters_native_qa.txt",FileAccess.WRITE)
	if file != null:
		file.store_string(report)
		file.close()
	else: check(false,"write native performance report")
	print(report)
	print("CUSTOM_NATIVE_QA_RESULT checks=%d failures=%d" % [checks,failures.size()])
	root.get_node("Sound").shutdown()
	await process_frame
	quit(0 if failures.is_empty() else 1)
