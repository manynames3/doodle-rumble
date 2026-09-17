extends SceneTree
## Deterministic art contact sheet. Run with -- --isolated-qa --silent-qa.
const Rig = preload("res://scripts/fighter_rig.gd")
const IDS = ["orange","red","green","blue","purple","yellow"]
const OUT = "res://../docs/test-results/"
var viewport: SubViewport
var rigs: Array[Node2D] = []

func _initialize() -> void:
	# The capture has its own hidden renderer; never take focus from a played game.
	root.visible = false
	call_deferred("run")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		push_error("Art capture requires isolated QA preferences.")
		quit(1)
		return
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var page := Node2D.new()
	viewport.add_child(page)
	var paper := ColorRect.new()
	paper.color = Color("e5d8c4")
	paper.size = Vector2(1280,720)
	page.add_child(paper)
	var floor := ColorRect.new()
	floor.color = Color("403951")
	floor.position = Vector2(0,440)
	floor.size = Vector2(1280,280)
	page.add_child(floor)
	for i in range(IDS.size()):
		var id: String = IDS[i]
		var rig: Node2D = Rig.new()
		page.add_child(rig)
		rig.configure(root.get_node("Data").fighter(id))
		rig.position = Vector2(112+float(i)*209,442)
		rig.scale = Vector2(1.56,1.56)
		rig.pose(0.016,{"grounded":true,"facing":1,"reduced_motion":true})
		rigs.append(rig)
	await _save("fighter_acting_idle.png")
	for i in range(rigs.size()):
		var state := {"grounded":true,"facing":1,"attack_progress":0.35,"attack_windup_ratio":0.22,"attack_active_ratio":0.38,"special":i==0,"reduced_motion":false}
		if i == 4:
			state["attack_progress"] = -1.0
			state["shield_guard"] = true
			state["shield_perfect"] = true
			state["shield_progress"] = 0.45
		rigs[i].pose(0.016,state)
	await _save("fighter_acting_action.png")
	# Draw through the short and folded poses that can expose invalid geometry.
	for variant in range(9):
		for i in range(rigs.size()):
			var state := {"grounded":variant != 2,"facing":-1 if variant%2 == 0 else 1,"reduced_motion":variant == 8}
			match variant:
				1: state["velocity"] = Vector2(260,0)
				3: state["attack_progress"] = 0.04
				4: state["attack_progress"] = 0.68
				5: state["dodging"] = true; state["dodge_progress"] = 0.48
				6: state["hurt"] = true
				7: state["victory"] = true
				8: state["defeated"] = true
			if variant in [3,4]:
				state["attack_windup_ratio"] = 0.22
				state["attack_active_ratio"] = 0.39
			rigs[i].pose(0.016,state)
		await process_frame
		if variant == 3: await _save("fighter_acting_windup.png")
		if variant == 4: await _save("fighter_acting_recovery.png")
		if variant == 7: await _save("fighter_acting_victory.png")
		if variant == 8: await _save("fighter_acting_defeat.png")
	print("POSE_STRESS 9 states x 6 fighters")
	quit()

func _save(name: String) -> void:
	for frame in range(5): await process_frame
	var path: String = OUT+name
	var error: Error = viewport.get_texture().get_image().save_png(path)
	if error != OK: push_error("Could not capture %s: %s" % [path,error])
	else: print("CAPTURE ",path)
