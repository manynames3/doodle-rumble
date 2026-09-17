extends Node
## Gameplay data is deliberately separate from both rig and controller.
const ORDER = ["orange", "red", "green", "blue", "purple", "yellow"]
var fighters: Dictionary
var weapons: Dictionary

func _ready() -> void:
	fighters = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json"))
	weapons = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))

func fighter(id: String) -> Dictionary:
	return fighters.get(id, fighters["orange"]).duplicate(true)

func weapon(id: String) -> Dictionary:
	return weapons[id].duplicate(true)
