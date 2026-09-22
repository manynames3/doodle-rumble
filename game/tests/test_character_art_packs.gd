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
		rig.pose(0.016,{"grounded":true,"velocity":Vector2(250,0),"facing":1})
		check(art.shown_frame in ["run_start","run"],id + " run pose")
		rig.pose(0.016,{"grounded":false,"velocity":Vector2(0,-400),"facing":1})
		check(art.shown_frame == "jump_takeoff",id + " jump pose")
		rig.pose(0.016,{"grounded":true,"attack_progress":0.06,"attack_windup_ratio":0.20,"attack_active_ratio":0.40})
		check(art.shown_frame == "attack_windup",id + " anticipation pose")
		rig.pose(0.016,{"grounded":true,"attack_progress":0.32,"attack_windup_ratio":0.20,"attack_active_ratio":0.40,"special":true})
		check(art.shown_frame == ("heavy_impact" if id == "red" else "special_impact"),id + " special pose")
		if id == "h4ck3r":
			rig.pose(0.016,{"grounded":true,"boss_cast":"firewall_scan","boss_charge":0.7})
			check(art.shown_frame == "special_impact","H4CK3R scan belongs to its existing cast")
		if id == "dark_lord":
			rig.pose(0.016,{"grounded":true,"boss_cast":"void_orb","boss_charge":0.7})
			check(art.shown_frame == "special_impact","Dark lord sigil belongs to its existing cast")
		rig.pose(0.016,{"grounded":true,"victory":true})
		check(not rig.has_packed_art(),id + " existing victory animation fallback")
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
