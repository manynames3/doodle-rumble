extends SceneTree
## Full Rally menus + real two-lap races in a deliberately isolated profile.
var checks := 0
var failures: Array[String] = []
var game
var rally
const DT := 1.0/60.0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, caption: String) -> void:
	checks += 1
	if not value:
		failures.append(caption)
		push_error("FAIL: "+caption)
func buttons(node: Node) -> Array[BaseButton]:
	var result: Array[BaseButton] = []
	if node is BaseButton: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result
func press(caption: String) -> void:
	for b in buttons(rally):
		if b.text==caption:
			b.pressed.emit()
			return
	check(false,"Button exists: "+caption)
func start_countdown() -> void:
	for i in range(181): rally.tick_race(DT,{})
	check(rally.race_state=="racing" and rally.race_time==0,"Count-in ends before race time advances")
func play_to_finish() -> void:
	var frames := 0
	while rally.race_state=="racing" and frames<18000:
		var c := {"move":sin(frames*0.017),"jump":frames%129==0,"special":frames%81==0,"attack":frames%210>170}
		var c2 := {"move":cos(frames*0.019),"jump":frames%141==0,"special":frames%98==0,"attack":frames%195>164}
		rally.tick_race(DT,c,c2)
		frames+=1
	check(rally.race_state=="results","Real input race reaches result screen")
	check(rally.sim.racers[0].finished and rally.sim.racers[0].finish_time>20,"Player completed two full laps")
func run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("QA"):
		push_error("Run with -- --isolated-qa --silent-qa")
		quit(1)
		return
	var settings = root.get_node("Settings")
	var sound = root.get_node("Sound")
	var original_bindings: Dictionary = settings._bindings.duplicate(true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_physics_process(false)
	game.set_process(false)
	game.start_racing()
	rally = game.ui.get_child(0)
	rally.test_mode=true
	rally.set_physics_process(false)
	rally.set_process(false)
	rally.library.save_path="user://rally_integration_test.json"
	if FileAccess.file_exists(rally.library.save_path): DirAccess.remove_absolute(rally.library.save_path)
	rally.library.load_data()
	rally.show_garage()
	check(game.state=="racing" and not game.world.visible,"Rally is mounted from the title and fighting is hidden")
	check(sound.external_music_active,"Rally suspends the title music")
	check(rally.library.courses.size()==3,"Three themed playgrounds available immediately")
	press("2P together")
	check(rally.mode=="local" and rally.human_count()==2,"Local mode selects two human drivers")
	press("PLAYER 2")
	var old_style: int = rally.styles[1]
	press(">")
	check(rally.styles[1] == (old_style+1)%3,"Second player chooses their own vehicle")
	press("Solo race")
	press("LET'S RACE!  >")
	check(rally.race_state=="countdown","Start button creates a real countdown")
	start_countdown()
	Input.action_press("p1_move_right")
	Input.action_press("p1_attack")
	settings.hold_to_attack=false
	var previous_lane: float = rally.sim.racers[0].lane
	rally._physics_process(DT)
	check(rally.sim.racers[0].lane>previous_lane,"Remapped input actions reach racing steering")
	check(rally.sim.racers[0]._drift_held,"Racing drift is held even when fighting repeat is disabled")
	Input.action_release("p1_move_right")
	Input.action_release("p1_attack")
	rally.pause_race()
	var paused_time: float = rally.race_time
	var paused_distance: float = rally.total_distance
	for i in range(60): rally.tick_race(DT,{"special":true})
	check(rally.race_time==paused_time and rally.total_distance==paused_distance,"Pause freezes simulation and progress")
	press("Settings")
	check(rally._settings_open,"Settings open from pause")
	press("Done")
	check(not rally._settings_open and rally.race_state=="paused","Settings close back to pause")
	press("Keep racing")
	play_to_finish()
	check(not rally.result_rewards.is_empty(),"Completed race records result and reward")
	check(rally.library.stickers.has("star"),"First finish earns a sticker")
	press("Race again!")
	check(rally.race_state=="countdown" and rally.total_distance==0,"Immediate rematch resets the whole race")
	rally.show_garage()
	press("Doodle Cup")
	press("START CUP  >")
	for stage in range(3):
		check(rally.cup_stage==stage and rally.sim.difficulty==stage,"Cup increases rival difficulty at stage %d"%stage)
		check(rally.course.id==["desk","castle","sky"][stage],"Cup visits a different playground")
		start_countdown()
		play_to_finish()
		if stage<2: press("Next playground  >")
	check(rally.cup_points[0]>0 and rally.cup_stage==2,"Cup accumulates standings through all three full races")
	check(rally.library.stickers.has("lightning"),"Repeated finishes unlock second decoration")
	rally.show_garage()
	press("2P together")
	press("LET'S RACE!  >")
	start_countdown()
	Input.action_press("p2_move_left")
	var lane1: float = rally.sim.racers[0].lane
	var lane2: float = rally.sim.racers[1].lane
	rally._physics_process(DT)
	Input.action_release("p2_move_left")
	check(is_equal_approx(rally.sim.racers[0].lane,lane1) and rally.sim.racers[1].lane<lane2,"Local P2 steering does not move P1")
	play_to_finish()
	check(rally.sim.racers[1].finished,"Local result waits for both humans to complete")
	rally.show_garage()
	var blank = rally.library.get_course("desk")
	blank.title="Test child's dream"
	var saved: Dictionary = rally.library.save_course(blank)
	check(not saved.is_empty() and str(saved.id).begins_with("custom_"),"Preset can be remixed into a named saved course")
	rally.selected_course_id = str(saved.id)
	rally.open_editor(saved)
	check(is_instance_valid(rally.editor) and rally.race_state=="editor","Saved course reopens in editor")
	rally.editor.race_requested.emit(saved)
	check(rally.course.id==saved.id and rally.race_state=="countdown","Creator sends the saved course directly into a race")
	start_countdown()
	play_to_finish()
	var reload = load("res://scripts/rally_library.gd").new()
	reload.save_path=rally.library.save_path
	reload.load_data()
	check(not reload.get_course(saved.id).is_empty() and not reload.records.is_empty(),"Courses and personal bests survive a fresh library load")
	rally.show_garage()
	press("Back")
	await process_frame
	check(game.state=="title" and not sound.external_music_active,"Returning to fighting restores title and music ownership")
	check(settings._bindings==original_bindings,"Racing leaves fighting bindings intact")
	game.queue_free()
	await process_frame
	sound.shutdown()
	print("RALLY INTEGRATION: %d checks, %d failures (six complete two-lap races)"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
