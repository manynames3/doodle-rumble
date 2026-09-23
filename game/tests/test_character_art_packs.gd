extends SceneTree
## Asset wiring smoke test for source and exported PCK runs.
const Rig = preload("res://scripts/fighter_rig.gd")
const Card = preload("res://scripts/selection_card.gd")
const IDS = ["orange","red","green","blue","purple","yellow","pac_man","h4ck3r","dark_lord"]
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)

func run() -> void:
	await process_frame
	var data = root.get_node("Data")
	for id in IDS:
		var rig = Rig.new()
		root.add_child(rig)
		rig.configure(data.fighter(id))
		check(rig.has_packed_art(),id + " packed pose displays")
		var art = rig.packed_art
		var manifest: String = "res://assets/character_art/%s/art.json" % id
		check(FileAccess.file_exists(manifest),id + " runtime manifest in project/PCK")
		check(art.frames.size() >= 12,id + " mapped pose set")
		check(art.effects.size() == 5,id + " mapped effects")
		for item in art.frames.values():
			check(ResourceLoader.exists(str(item.path),"Texture2D"),id + " pose loads: " + str(item.path))
		for item in art.effects.values():
			check(ResourceLoader.exists(str(item.path),"Texture2D"),id + " effect loads: " + str(item.path))
		check(not rig.weapon.visible,id + " baked tool does not duplicate procedural tool")
		check(art.visual_height >= float(JSON.parse_string(FileAccess.get_file_as_string(manifest)).get("local_height",0.0)) * 1.20,id + " packed fighter matches the prior perceived size")
		rig.pose(0.016,{"grounded":true,"facing":1,"reduced_motion":false})
		var idle_position: Vector2 = art.body.position
		rig.pose(0.16,{"grounded":true,"facing":1,"reduced_motion":false})
		check(art.body.position.distance_to(idle_position) > 0.1,id + " breathing pose moves the packed body")
		rig.pose(0.016,{"grounded":true,"facing":1,"reduced_motion":true})
		var still_position: Vector2 = art.body.position
		rig.pose(0.20,{"grounded":true,"facing":1,"reduced_motion":true})
		check(art.body.position.distance_to(still_position) < 0.01,id + " reduced motion holds the packed body steady")
		rig.pose(0.016,{"grounded":true,"velocity":Vector2(250,0),"facing":1})
		check(art.shown_frame in ["run_start","run"],id + " run pose")
		rig.pose(0.016,{"grounded":false,"velocity":Vector2(0,-400),"facing":1})
		check(art.shown_frame == "jump_takeoff",id + " jump pose")
		rig.pose(0.016,{"grounded":true,"attack_progress":0.06,"attack_windup_ratio":0.20,"attack_active_ratio":0.40})
		check(art.shown_frame == "attack_windup",id + " anticipation pose")
		rig.pose(0.016,{"grounded":true,"attack_progress":0.32,"attack_windup_ratio":0.20,"attack_active_ratio":0.40,"special":true})
		check(art.shown_frame == ("heavy_impact" if id == "red" else "run_start" if id == "purple" else "special_impact"),id + " special pose")
		if id == "h4ck3r":
			rig.pose(0.016,{"grounded":true,"boss_cast":"firewall_scan","boss_charge":0.7})
			check(art.shown_frame == "attack_windup","H4CK3R scan holds the tell until release")
			rig.pose(0.016,{"grounded":true,"boss_cast":"firewall_scan","boss_charge":1.0})
			check(art.shown_frame == "special_impact" and art.in_front.visible,"H4CK3R scan impact begins on release")
			rig.pose(0.20,{"grounded":true,"boss_cast":"firewall_scan","boss_charge":1.0})
			check(art.shown_frame == "attack_recover" and not art.in_front.visible,"H4CK3R scan impact finishes after release")
			rig.pose(1.20,{"grounded":true,"boss_cast":"firewall_scan","boss_charge":1.0})
			check(not art.in_front.visible,"H4CK3R scan burst never repeats during execution")
			rig.pose(0.016,{"grounded":true,"boss_cast":"ink_geyser","boss_charge":0.8})
			check(art.shown_frame == "attack_windup","H4CK3R other commands hold their tell")
		if id == "dark_lord":
			rig.pose(0.016,{"grounded":true,"boss_cast":"void_orb","boss_charge":0.7})
			check(art.shown_frame == "attack_windup","Dark lord orb holds the tell until release")
			rig.pose(0.016,{"grounded":true,"boss_cast":"void_orb","boss_charge":1.0})
			check(art.shown_frame == "special_impact" and art.in_front.visible,"Dark lord orb impact begins on release")
			rig.pose(0.20,{"grounded":true,"boss_cast":"void_orb","boss_charge":1.0})
			check(art.shown_frame == "attack_recover" and not art.in_front.visible,"Dark lord orb impact finishes after release")
			rig.pose(0.016,{"grounded":true,"boss_cast":"rift","boss_charge":0.8})
			check(art.shown_frame == "attack_windup" and not art.in_front.visible,"Dark lord rift remains a telegraph before release")
			rig.pose(0.016,{"grounded":true,"boss_cast":"rift","boss_charge":1.0})
			check(art.shown_frame == "special_impact" and art.in_front.visible,"Dark lord rift impact begins on release")
			rig.pose(0.016,{"grounded":true,"boss_cast":"camera","boss_charge":0.8})
			check(art.shown_frame == "attack_windup","Dark lord other commands hold their tell")
		if id == "purple":
			rig.pose(0.016,{"grounded":true,"attack_progress":0.22,"attack_windup_ratio":0.20,"attack_active_ratio":0.40})
			check(art.shown_frame == "run_start","Purple shows the supplied empty-bow pose after release")
		rig.pose(0.016,{"grounded":true,"victory":true})
		check(rig.has_packed_art() and not rig.weapon.visible,id + " result stays in packed style")
		rig.pose(0.0,{"grounded":true,"victory":true,"presentation_time":12.5})
		var seek_position: Vector2 = art.body.position
		var seek_frame: String = art.shown_frame
		rig.pose(0.0,{"grounded":true,"victory":true,"presentation_time":12.8})
		check(art.body.position.distance_to(seek_position) > 0.1,id + " zero-delta cinematic seek animates packed victory")
		rig.pose(0.0,{"grounded":true,"victory":true,"presentation_time":12.5})
		check(art.shown_frame == seek_frame and art.body.position.distance_to(seek_position) < 0.01,id + " cinematic seek returns to the same packed pose")
		rig.pose(0.016,{"grounded":true,"defeated":true})
		check(rig.has_packed_art() and art.shown_frame == "idle",id + " fallen result uses packed fighter")
		rig.pose(0.016,{"grounded":true})
		check(rig.has_packed_art(),id + " restores pose after result")
		rig.queue_free()
		await process_frame
	for id in IDS.slice(0,6):
		var card = Card.new()
		root.add_child(card)
		card.configure(id,Color.WHITE,false)
		check(card.transparent_character_art,id + " menu uses transparent canonical art")
		card.queue_free()
		await process_frame
	print("CHARACTER_ART_PACK_TEST checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
