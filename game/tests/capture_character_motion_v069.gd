extends SceneTree
## Hidden native contact sheets for the v0.6.9 packed-fighter motion pass.
const Rig = preload("res://scripts/fighter_rig.gd")
const IDS = ["orange","red","green","blue","purple","yellow","pac_man","h4ck3r","dark_lord"]
const OUT = "res://../docs/test-results/v069-motion/"
var viewport: SubViewport
var rigs: Array[Node2D] = []

func _initialize() -> void:
	root.hide()
	call_deferred("run")

func _save(name: String) -> void:
	for _i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var err: Error = viewport.get_texture().get_image().save_png(OUT+name+".png")
	if err != OK: push_error("Motion capture failed: " + name)
	else: print("MOTION_CAPTURE ", OUT+name+".png")

func _pose_all(state: Dictionary, steps: int) -> void:
	for _step in range(steps):
		for rig in rigs:
			rig.pose(1.0/60.0,state)

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Motion capture requires isolated QA preferences")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var paper := ColorRect.new()
	paper.color = Color("e4d7bc")
	paper.size = Vector2(1280,720)
	viewport.add_child(paper)
	for row in range(3):
		var floor := ColorRect.new()
		floor.color = Color("675e60")
		floor.position = Vector2(0,217+row*235)
		floor.size = Vector2(1280,4)
		viewport.add_child(floor)
	for i in range(IDS.size()):
		var rig: Node2D = Rig.new()
		viewport.add_child(rig)
		rig.configure(root.get_node("Data").fighter(IDS[i]))
		rig.position = Vector2(205+float(i%3)*420,218+float(i/3)*235)
		rigs.append(rig)
	_pose_all({"grounded":true,"facing":1},25)
	await _save("idle")
	_pose_all({"grounded":true,"facing":1,"velocity":Vector2(240,0)},24)
	await _save("run")
	_pose_all({"grounded":true,"facing":1,"attack_progress":0.16,"attack_windup_ratio":0.20,"attack_active_ratio":0.40},1)
	await _save("windup")
	_pose_all({"grounded":true,"facing":1,"attack_progress":0.24,"attack_windup_ratio":0.20,"attack_active_ratio":0.40},1)
	await _save("released")
	for rig in rigs:
		rig.pose(0.016,{"grounded":true,"facing":1,"dodging":rig.fighter_id in IDS.slice(0,6),"dodge_invulnerable":true})
	await _save("dodge")
	for rig in rigs:
		rig.pose(0.016,{"grounded":true,"facing":1,"counter_ready":rig.fighter_id == "purple"})
	await _save("counter")
	_pose_all({"grounded":true,"facing":1,"victory":true},20)
	await _save("victory")
	_pose_all({"grounded":true,"facing":1,"defeated":true},27)
	await _save("defeat")
	for rig in rigs: rig.queue_free()
	viewport.queue_free()
	await process_frame
	quit()
