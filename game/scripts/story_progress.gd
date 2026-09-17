extends Node
## Separate, versioned fighting journal. Never touches Rally saves or bindings.
const Difficulty = preload("res://scripts/difficulty.gd")
const SAVE_PATH := "user://story_v1.cfg"
var active := false
var stage := 0
var fighter := "orange"
var hazards := true
var difficulty_level := Difficulty.EASY
var completed: Array[int] = []
var challenges: Array[int] = []
var runs := 0
var save_error := ""

func _ready() -> void:
	load_profile()

func load_profile(path: String = SAVE_PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK and cfg.load(path+".bak") != OK: return
	if cfg.get_value("meta","version",0) != 1: return
	var saved_stage = cfg.get_value("run","stage",0)
	var saved_fighter = cfg.get_value("run","fighter","orange")
	if not saved_stage is int or saved_stage < 0 or saved_stage > 5 or saved_fighter not in Data.ORDER: return
	stage = saved_stage
	fighter = saved_fighter
	active = cfg.get_value("run","active",false) == true
	hazards = cfg.get_value("run","hazards",true) != false
	var saved_difficulty = cfg.get_value("run","difficulty_level",Difficulty.EASY)
	difficulty_level = saved_difficulty if Difficulty.valid_level(saved_difficulty) else Difficulty.EASY
	completed = _valid_indices(cfg.get_value("book","completed",[]))
	challenges = _valid_indices(cfg.get_value("book","challenges",[]))
	var raw_runs = cfg.get_value("book","runs",0)
	runs = maxi(0,raw_runs) if raw_runs is int else 0

func _valid_indices(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			if item is int and item >= 0 and item < 6 and item not in result: result.append(item)
	return result

func save_profile(path: String = SAVE_PATH) -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("meta","version",1)
	for pair in [["active",active],["stage",stage],["fighter",fighter],["hazards",hazards],["difficulty_level",difficulty_level]]: cfg.set_value("run",pair[0],pair[1])
	for pair in [["completed",completed],["challenges",challenges],["runs",runs]]: cfg.set_value("book",pair[0],pair[1])
	var err := cfg.save(path+".tmp")
	if err == OK and FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(path+".bak")
		err = DirAccess.rename_absolute(path,path+".bak")
	if err == OK: err = DirAccess.rename_absolute(path+".tmp",path)
	save_error = "" if err == OK else "Could not save this chapter. Your current game is still available."
	return err == OK

func begin_run(id: String, use_hazards: bool, selected_difficulty: int = Difficulty.EASY) -> void:
	active = true
	stage = 0
	fighter = id if id in Data.ORDER else "orange"
	hazards = use_hazards
	difficulty_level = Difficulty.normalized_level(selected_difficulty)
	save_profile()

func checkpoint(index: int, id: String, use_hazards: bool, selected_difficulty: int = -1) -> void:
	active = true
	stage = clampi(index,0,5)
	fighter = id if id in Data.ORDER else "orange"
	hazards = use_hazards
	if selected_difficulty >= 0: difficulty_level = Difficulty.normalized_level(selected_difficulty)
	save_profile()

func finish_stage(index: int, bonus: bool) -> void:
	if index < 0 or index > 5: return
	if index not in completed: completed.append(index)
	if bonus and index not in challenges: challenges.append(index)
	if index == 5:
		if active: runs += 1
		active = false
	else:
		stage = index+1
		active = true
	save_profile()
