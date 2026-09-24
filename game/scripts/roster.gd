extends Node
## Gameplay data is deliberately separate from both rig and controller.
const ORDER = ["orange", "red", "green", "blue", "purple", "yellow"]
const Kits = preload("res://scripts/custom_kits.gd")
var fighters: Dictionary
var weapons: Dictionary

func _ready() -> void:
	fighters = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json"))
	weapons = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))

func fighter(id: String) -> Dictionary:
	var record: Dictionary = Doodles.get_record(id)
	if not record.is_empty():
		return custom_definition(record)
	return fighters.get(id, fighters["orange"]).duplicate(true)

func playable_ids() -> Array:
	var result: Array = ORDER.duplicate()
	for record in Doodles.records(): result.append(str(record.id))
	return result

func is_playable(id: String) -> bool:
	return id in ORDER or Doodles.has(id)

func custom_definition(record: Dictionary) -> Dictionary:
	var kit := str(record.get("kit","pixel_pick"))
	var info: Dictionary = Kits.info(kit)
	return {"id":str(record.get("id","custom_preview")),"name":str(record.get("name","My Doodle")),
		"color":str(record.get("color","ffad42")),"custom":true,"custom_record":record,
		"kit":kit,"weapon":info.weapon,"special":info.special,"special_name":info.special_name,
		"head":"round","max_health":100,"move_multiplier":1.0,
		"description":info.description,"tagline":"Drawn by you. Ready to rumble."}

func weapon(id: String) -> Dictionary:
	return weapons[id].duplicate(true)
