extends Control
## Rally coordinates menus, saved creations and the pure fixed-step race simulation.
const RacerArt = preload("res://scripts/racer_art.gd")
const Library = preload("res://scripts/rally_library.gd")
const Editor = preload("res://scripts/rally_editor.gd")
const Simulation = preload("res://scripts/rally_sim.gd")
const World = preload("res://scripts/rally_world.gd")
const RallyAudio = preload("res://scripts/rally_audio.gd")
const CourseCard = preload("res://scripts/rally_course_card.gd")
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const INK := Color("263e4d")
const PAPER := Color("fff7e5")
const ORANGE := Color("f5a23f")
const MUTED := Color("687e88")
const PAINTS := [Color("f59736"),Color("72bccc"),Color("abca78"),Color("df8eac")]
const CAR_NAMES := ["Dragon Wagon","Rocket Bug","Cloud Cruiser"]
const TRAITS := ["Tough little dragon. Shrugs off bumps and keeps rolling.","A pocket rocket. Save turbo for a long straight!","A floating daydream. Longer hops sail over trouble."]
const MODE_NAMES := ["Solo race","2P together","Doodle Cup"]
const MODES := ["solo","local","cup"]
var library = Library.new()
var sim
var race_world
var audio
var editor
var race_state := "garage"
var test_mode := false
var mode := "solo"
var assist := true
var difficulty := 0
var styles: Array = [0,1]
var colors: Array = [0,1]
var selected_slot := 0
var selected_course_id := ""
var course: Dictionary = {}
var cup_stage := 0
var cup_points: Array[int] = [0,0,0]
var cup_active := false
var countdown := 3.0
var total_distance := 0.0
var race_time := 0.0
var track_length := 0.0
var stars := 0
var finish_rank := 1
var result_rewards: Dictionary = {}
var _on_exit: Callable
var _ui: Control
var _modal: Control
var _hud: Array[Label] = []
var _meters: Array[ProgressBar] = []
var _challenge_label: Label
var _timer_label: Label
var _message_label: Label
var _prompt_labels: Array[Label] = []
var _garage_preview
var _editor_page := 0
var _settings_open := false
var _resume_state := "racing"
var _message_time := 0.0
var _clock := 0.0
var _closed := false
var _background_focus: Array[Dictionary] = []
var _modal_focus: Array[Dictionary] = []
var _last_devices := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	Settings.controller_lost.connect(func(slot: int):
		if slot < human_count() and race_state in ["countdown","racing"]:
			pause_race("Controller disconnected. Keyboard controls still work."))

func open_game(on_exit: Callable) -> void:
	_on_exit = on_exit
	library.load_data()
	styles[0] = library.selected_style
	colors[0] = library.selected_color
	selected_course_id = library.selected_course_id
	if library.get_course(selected_course_id).is_empty(): selected_course_id = str(library.courses[0].id)
	_block_focus(get_parent(),_background_focus)
	audio = RallyAudio.new()
	add_child(audio)
	Sound.set_external_music_active(true)
	show_garage()

func _block_focus(node: Node, storage: Array[Dictionary]) -> void:
	if node == self: return
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		storage.append({"node":weakref(node),"mode":node.focus_mode})
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): _block_focus(child,storage)

func _restore_focus(storage: Array[Dictionary]) -> void:
	for item in storage:
		var node = item.node.get_ref()
		if is_instance_valid(node): node.focus_mode = item.mode
	storage.clear()

func _exit_tree() -> void:
	_restore_focus(_background_focus)
	Sound.set_external_music_active(false)

func _close() -> void:
	if _closed: return
	_closed = true
	_save_preferences()
	if is_instance_valid(audio): audio.stop()
	var callback := _on_exit
	get_parent().remove_child(self)
	queue_free()
	if callback.is_valid(): callback.call()

func _save_preferences() -> void:
	library.selected_style = styles[0]
	library.selected_color = colors[0]
	library.selected_course_id = selected_course_id
	library.save_data()

func human_count() -> int:
	return 2 if mode == "local" else 1

func _clear_screen() -> void:
	_modal_focus.clear()
	for child in get_children():
		if child == audio: continue
		remove_child(child)
		child.queue_free()
	race_world = null
	editor = null
	_modal = null
	_garage_preview = null
	_timer_label = null
	_challenge_label = null
	_message_label = null
	_hud.clear()
	_meters.clear()
	_prompt_labels.clear()
	_ui = Control.new()
	_ui.z_index = 10
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)

func _box(color: Color, border: Color = INK, width: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_corner_radius_all(12)
	box.set_border_width_all(width)
	return box

func _panel(at: Vector2, dimensions: Vector2, color: Color = PAPER, parent: Control = null) -> Panel:
	var node := Panel.new()
	node.position = at
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel",_box(color))
	(parent if parent != null else _ui).add_child(node)
	return node

func _label(caption: String, at: Vector2, dimensions: Vector2, font_size: int = 18, color: Color = INK, handwritten: bool = false, parent: Control = null) -> Label:
	var node := Label.new()
	node.text = caption
	node.clip_text = true
	node.position = at
	node.size = dimensions
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	if handwritten: node.add_theme_font_override("font",FONT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else _ui).add_child(node)
	return node

func _button(caption: String, at: Vector2, dimensions: Vector2, callback: Callable, primary: bool = false, parent: Control = null) -> Button:
	var node := Button.new()
	node.text = caption
	node.clip_text = true
	node.position = at
	node.size = dimensions
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size",18)
	node.add_theme_color_override("font_color",INK)
	for state in ["normal","hover","pressed","focus"]:
		node.add_theme_color_override("font_"+state+"_color",INK)
	node.add_theme_stylebox_override("normal",_box(ORANGE if primary else PAPER))
	node.add_theme_stylebox_override("hover",_box(Color("ffe2a5")))
	node.add_theme_stylebox_override("pressed",_box(Color("f1c26b")))
	node.add_theme_stylebox_override("focus",_box(Color(0,0,0,0),Color("2895aa"),4))
	node.pressed.connect(func():
		Sound.play("ui")
		callback.call())
	(parent if parent != null else _ui).add_child(node)
	return node

func show_garage() -> void:
	race_state = "garage"
	cup_active = false
	_clear_screen()
	_label("BENJAM GAMES  /  THE IMAGINATION GARAGE",Vector2(38,20),Vector2(800,24),13,MUTED)
	_label("Doodle Rally",Vector2(34,42),Vector2(430,66),48,INK,true)
	_label("Draw it. Drive it. Dream bigger.",Vector2(40,108),Vector2(360,28),18,MUTED)
	_button("Settings",Vector2(1001,35),Vector2(113,43),_open_settings)
	_button("Back",Vector2(1130,35),Vector2(108,43),_close)
	for i in range(3):
		_button(MODE_NAMES[i],Vector2(414+i*276,95),Vector2(262,48),func():
			mode = MODES[i]
			selected_slot = 0
			show_garage(),mode == MODES[i])
	_panel(Vector2(36,169),Vector2(354,409),Color("f5e8c5"))
	if mode == "local":
		for i in range(2):
			_button("PLAYER %d"%(i+1),Vector2(53+i*165,184),Vector2(158,35),func():
				selected_slot = i
				show_garage(),selected_slot == i)
	else:
		_label("YOUR HAPPY LITTLE ENGINE",Vector2(58,182),Vector2(310,27),14,MUTED)
	_label(CAR_NAMES[styles[selected_slot]],Vector2(57,228),Vector2(315,48),31,INK,true)
	_garage_preview = RacerArt.new()
	_garage_preview.configure(styles[selected_slot],PAINTS[colors[selected_slot]])
	_garage_preview.position = Vector2(211,335)
	_garage_preview.scale = Vector2.ONE*2.7
	_garage_preview.heading = -0.12
	_garage_preview.sticker = library.selected_sticker
	_ui.add_child(_garage_preview)
	_button("<",Vector2(56,317),Vector2(42,47),func(): _cycle_car(-1))
	_button(">",Vector2(327,317),Vector2(42,47),func(): _cycle_car(1))
	var description := _label(TRAITS[styles[selected_slot]],Vector2(58,414),Vector2(304,55),16,MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(4):
		var b := _button("✓" if colors[selected_slot] == i else "",Vector2(58+i*79,481),Vector2(69,35),func():
			colors[selected_slot] = i
			show_garage())
		b.add_theme_stylebox_override("normal",_box(PAINTS[i],INK,3 if colors[selected_slot]==i else 1))
	var decal := str(library.selected_sticker).capitalize()
	_button("Sticker: "+decal,Vector2(58,532),Vector2(225,32),_cycle_sticker)
	_label("★ %d"%library.coins,Vector2(296,538),Vector2(76,27),16,MUTED)
	for i in range(mini(3,library.courses.size())):
		var card = CourseCard.new()
		card.course = library.courses[i]
		card.chosen = selected_course_id == card.course.id
		var key := "%s|%s_%s_%d_%d"%[card.course.id,mode,"gentle" if assist else "skillful",difficulty,styles[0]]
		card.personal_best = float(library.records.get(key,{}).get("best_time",0.0))
		card.position = Vector2(414+i*276,169)
		card.size = Vector2(262,231)
		card.pressed.connect(func():
			selected_course_id = str(card.course.id)
			show_garage())
		_ui.add_child(card)
	_label("MY LITTLE WORLDS",Vector2(419,416),Vector2(580,32),22,INK,true)
	if selected_course_id.begins_with("custom_"):
		_button("Erase course",Vector2(1100,409),Vector2(140,35),_confirm_erase)
	var customs: Array = library.courses.slice(3)
	_editor_page = clampi(_editor_page,0,maxi(0,(customs.size()-1)/3))
	for i in range(3):
		var index := _editor_page*3+i
		if index >= customs.size(): break
		var c: Dictionary = customs[index]
		_button(str(c.title),Vector2(414+i*234,457),Vector2(223,39),func():
			selected_course_id = str(c.id)
			show_garage(),selected_course_id == c.id)
	if customs.is_empty():
		_label("A blank page can become your favorite racetrack.",Vector2(418,462),Vector2(782,31),17,MUTED)
	elif customs.size()>3:
		_button("More",Vector2(1135,457),Vector2(107,39),func():
			_editor_page = (_editor_page+1)%int(ceil(customs.size()/3.0))
			show_garage())
	_button("+ Sketch a course",Vector2(414,519),Vector2(236,44),func(): open_editor({}))
	_button("Edit / remix",Vector2(661,519),Vector2(150,44),func(): open_editor(library.get_course(selected_course_id)))
	_button("Driving: "+("Gentle" if assist else "Skillful"),Vector2(824,519),Vector2(211,44),func():
		assist = not assist
		show_garage())
	_button(["Easy rivals","Lively rivals","Fast rivals"][difficulty],Vector2(1046,519),Vector2(196,44),func():
		difficulty = (difficulty+1)%3
		show_garage())
	var hint := "Hold drift on a bend; release for turbo. Hop trouble. Chase stars!"
	if mode == "local": hint = "Two drivers, one screen. P1 picks first; tap PLAYER 2 to choose their car."
	elif mode == "cup": hint = "Three playgrounds, faster rivals each race. Your trophy is waiting."
	_label(hint,Vector2(42,596),Vector2(1160,29),18,INK)
	_label("Stars earn stickers. Courses and personal bests stay saved.",Vector2(42,641),Vector2(855,30),17,MUTED)
	var start := _button("START CUP  >" if mode == "cup" else "LET'S RACE!  >",Vector2(965,633),Vector2(276,57),_start_selected,true)
	start.add_theme_font_override("font",FONT)
	start.add_theme_font_size_override("font_size",27)
	start.grab_focus()
	if not library.last_error.is_empty(): _label(library.last_error,Vector2(42,682),Vector2(1150,25),13,Color("a4423c"))
	if is_instance_valid(audio): audio.play_theme(str(library.get_course(selected_course_id).get("theme","desk")))
	queue_redraw()

func _cycle_car(direction: int) -> void:
	styles[selected_slot] = posmod(int(styles[selected_slot])+direction,3)
	show_garage()

func _cycle_sticker() -> void:
	var decals: Array = ["plain"]
	for unlocked in library.stickers:
		if unlocked in ["star","lightning"]: decals.append(unlocked)
	var index := decals.find(library.selected_sticker)
	library.selected_sticker = decals[(index+1)%decals.size()]
	show_garage()

func _start_selected() -> void:
	_save_preferences()
	cup_active = mode == "cup"
	cup_stage = 0
	cup_points.assign([0,0,0])
	if cup_active: selected_course_id = str(library.courses[0].id)
	start_race()

func start_race() -> void:
	course = library.get_course(selected_course_id).duplicate(true)
	if course.is_empty(): course = library.courses[0].duplicate(true)
	var curve: Curve2D = Library.build_curve(course)
	sim = Simulation.new()
	var race_styles: Array = [styles[0],styles[1],2,0] if human_count()==2 else [styles[0],1,2]
	var race_colors: Array = [PAINTS[colors[0]],PAINTS[colors[1]],PAINTS[2],PAINTS[3]] if human_count()==2 else [PAINTS[colors[0]],PAINTS[(colors[0]+1)%4],PAINTS[(colors[0]+2)%4]]
	sim.setup(curve,course,race_styles,race_colors,human_count(),cup_stage if cup_active else difficulty,assist)
	if human_count()==1:
		sim.start_challenge("drifts" if course.theme=="castle" else "stars",90.0,2 if course.theme=="castle" else 5)
	for racer in sim.racers: racer["sticker"] = library.selected_sticker if racer.get("human",false) else "plain"
	race_state = "countdown"
	countdown = 3.0
	race_time = 0.0
	total_distance = 0.0
	track_length = sim.track_length
	_message_time = 0.0
	result_rewards.clear()
	_clear_screen()
	race_world = World.new()
	add_child(race_world)
	move_child(race_world,0)
	race_world.setup(curve,course)
	_build_race_ui()
	_update_race_view()
	if is_instance_valid(audio): audio.play_theme(str(course.theme))
	Sound.play("round")
	queue_redraw()

func _build_race_ui() -> void:
	_label(str(course.title),Vector2(34,18),Vector2(700,44),30,INK,true)
	var caption := "CUP %d / 3  •  %s"%[cup_stage+1,["EASY","LIVELY","FAST"][cup_stage]] if cup_active else ("TWO FRIENDS. FOUR LITTLE ENGINES." if mode=="local" else "YOUR NEXT PERSONAL BEST STARTS HERE.")
	_label(caption,Vector2(36,65),Vector2(790,25),12,MUTED)
	_timer_label = _label("0:00.0",Vector2(1009,27),Vector2(126,41),26,INK,true)
	_button("II",Vector2(1161,25),Vector2(74,44),pause_race)
	for i in range(human_count()):
		var x := 36.0+i*608
		_hud.append(_label("",Vector2(x,92),Vector2(414,30),19,INK,true))
		var meter := ProgressBar.new()
		meter.position = Vector2(x+425,100)
		meter.size = Vector2(139,16)
		meter.show_percentage = false
		meter.max_value = 100
		meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meter.add_theme_stylebox_override("background",_box(Color("dcd9c8"),INK,1))
		meter.add_theme_stylebox_override("fill",_box(PAINTS[colors[i]],INK,1))
		_ui.add_child(meter)
		_meters.append(meter)
		_label("TURBO",Vector2(x+426,122),Vector2(140,20),10,MUTED)
	if human_count()==1:
		_challenge_label = _label("",Vector2(666,96),Vector2(563,30),17,Color("438b85"),true)
	_message_label = _label("",Vector2(350,137),Vector2(580,46),25,INK,true)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(human_count()):
		_prompt_labels.append(_label("",Vector2(33,642+i*28),Vector2(1210,27),15,INK))
	_last_devices = ""
	_refresh_prompts()

func _refresh_prompts() -> void:
	_last_devices = Settings.device_label(0)+Settings.device_label(1)
	for i in range(_prompt_labels.size()):
		var prefix := "p%d_"%(i+1)
		if Settings.device_label(i).begins_with("Controller"):
			_prompt_labels[i].text = "P%d   Stick: steer   •   Bottom: hop   •   Hold left face: drift, release to charge   •   Right face: turbo   •   Start: pause"%(i+1)
		else:
			_prompt_labels[i].text = "P%d   %s / %s steer   •   %s hop   •   Hold %s drift, release to charge   •   %s turbo   •   Esc pause"%[i+1,Settings.binding_label(prefix+"move_left"),Settings.binding_label(prefix+"move_right"),Settings.binding_label(prefix+"jump"),Settings.binding_label(prefix+"attack"),Settings.binding_label(prefix+"special")]

func _physics_process(delta: float) -> void:
	if race_state in ["countdown","racing"] and not _settings_open:
		var commands: Array[Dictionary] = []
		for i in range(human_count()):
			var command: Dictionary = Settings.read_player(i)
			# Drifting is held even if the fighting game's repeat-attack preference is off.
			command.attack = Input.is_action_pressed("p%d_attack"%(i+1))
			commands.append(command)
		tick_race(delta,commands[0],commands[1] if commands.size()>1 else {})

func _process(delta: float) -> void:
	if race_state != "paused" and not Settings.reduced_motion:
		_clock += delta
	if is_instance_valid(_garage_preview):
		_garage_preview.rotation = 0.0 if Settings.reduced_motion else sin(_clock*1.8)*0.04
	if _last_devices != Settings.device_label(0)+Settings.device_label(1) and not _prompt_labels.is_empty(): _refresh_prompts()
	if race_state == "garage": queue_redraw()

func tick_race(delta: float, command: Dictionary, command2: Dictionary = {}) -> void:
	if race_state not in ["countdown","racing"] or not is_finite(delta) or delta<=0: return
	var dt := minf(delta,0.1)
	if race_state == "countdown":
		var old_count := ceili(countdown)
		countdown = maxf(0.0,countdown-dt)
		if ceili(countdown)!=old_count: Sound.play("round" if countdown<=0 else "ui")
		_message_label.text = "%d… READY TO DOODLE?"%maxi(1,ceili(countdown))
		if countdown<=0:
			race_state = "racing"
			_feedback("GO! Make some happy tire tracks.",2.2)
		return
	var commands: Array[Dictionary] = [command]
	if human_count()==2: commands.append(command2)
	sim.tick(dt,commands)
	_message_time = maxf(0.0,_message_time-dt)
	for event in sim.drain_events():
		if is_instance_valid(race_world): race_world.add_event(event)
		if is_instance_valid(audio): audio.event(str(event.get("kind","")),int(sim.racers[clampi(int(event.get("racer",0)),0,sim.racers.size()-1)].style))
		if int(event.get("racer",0))<human_count():
			var messages := {"drift":"NICE DRIFT! Turbo earned.","drift_charge":"NICE DRIFT! Turbo earned.","boost":"CRAYON TURBO!","ramp":"WHEEEE!","gate_warning":"The gate is closing. Hop or steer around!","lap":"LAST LAP! One more happy scribble."}
			if event.has("message"): _feedback(str(event.message),1.25)
			elif messages.has(event.kind): _feedback(messages[event.kind],1.2)
	_update_race_view()
	if sim.finished: finish_race()

func _update_race_view() -> void:
	if sim == null: return
	race_time = sim.race_time
	total_distance = float(sim.racers[0].distance)
	stars = int(sim.racers[0].stars)
	if is_instance_valid(race_world):
		race_world.stamps = sim.stamps
		race_world.update_race(sim.racers,sim.race_time,Settings.reduced_motion)
	if is_instance_valid(_challenge_label) and not sim.challenge.is_empty():
		var goal := "good drifts" if sim.challenge.kind=="drifts" else "stars"
		_challenge_label.text = "★ GOAL COMPLETE!" if sim.challenge.state=="complete" else "Bonus goal: %d / %d %s"%[sim.challenge.score,sim.challenge.target,goal]
	if is_instance_valid(_timer_label): _timer_label.text = "%d:%04.1f"%[int(race_time)/60,fmod(race_time,60)]
	for i in range(_hud.size()):
		var racer: Dictionary = sim.racers[i]
		var lap := mini(2,int(float(racer.distance)/maxf(1,track_length))+1)
		_hud[i].text = "P%d  %s   •   %s   •   %s   ★%d"%[i+1,CAR_NAMES[int(racer.style)].get_slice(" ",0),"FINISHED" if racer.finished else "LAP %d/2"%lap,_ordinal(_rank(i)),int(racer.stars)]
		_meters[i].value = racer.boost
	if is_instance_valid(_message_label) and _message_time<=0 and race_state=="racing":
		_message_label.text = ""
		for i in range(human_count()):
			if sim.racers[i].finished: _message_label.text = "P%d FINISHED! Cheering the other driver on…"%(i+1)

func _rank(index: int) -> int:
	var rank := 1
	var racer: Dictionary = sim.racers[index]
	for i in range(sim.racers.size()):
		if i==index: continue
		var other: Dictionary = sim.racers[i]
		if (other.finished and not racer.finished) or (other.finished and racer.finished and float(other.finish_time)<float(racer.finish_time)) or (not other.finished and not racer.finished and float(other.distance)>float(racer.distance)):
			rank += 1
	return rank

func _ordinal(rank: int) -> String:
	return ["1st","2nd","3rd","4th"][clampi(rank-1,0,3)]

func _feedback(message: String, duration: float) -> void:
	_message_time = duration
	if is_instance_valid(_message_label): _message_label.text = message

func _make_modal() -> void:
	_block_focus(_ui,_modal_focus)
	_modal = Control.new()
	_modal.z_index = 20
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var shade := ColorRect.new()
	shade.color = Color(0.05,0.10,0.15,0.58)
	shade.size = Vector2(1280,720)
	_modal.add_child(shade)
	_panel(Vector2(305,151),Vector2(670,423),PAPER,_modal)

func pause_race(reason: String = "Your doodles can catch their breath.") -> void:
	if race_state not in ["racing","countdown"]: return
	_resume_state = race_state
	race_state = "paused"
	if is_instance_valid(race_world): race_world.set_process(false)
	_make_modal()
	_label("PIT STOP",Vector2(342,181),Vector2(590,64),44,INK,true,_modal)
	_label(reason,Vector2(346,259),Vector2(582,36),18,MUTED,false,_modal)
	var resume := _button("Keep racing",Vector2(348,329),Vector2(275,56),resume_race,true,_modal)
	_button("Settings",Vector2(646,329),Vector2(275,56),_open_settings,false,_modal)
	_button("Restart race",Vector2(348,407),Vector2(275,49),start_race,false,_modal)
	_button("Dream garage",Vector2(646,407),Vector2(275,49),show_garage,false,_modal)
	_label("Drift = hold the attack key. Release on a bend to earn turbo.",Vector2(346,505),Vector2(582,35),16,MUTED,false,_modal)
	resume.grab_focus()

func resume_race() -> void:
	if race_state!="paused" or _settings_open: return
	if is_instance_valid(_modal):
		remove_child(_modal)
		_modal.queue_free()
		_modal = null
	_restore_focus(_modal_focus)
	race_state = _resume_state
	if is_instance_valid(race_world): race_world.set_process(true)

func finish_race() -> void:
	if race_state!="racing": return
	race_state = "results"
	finish_rank = _rank(0)
	var record_mode := "%s_%s_%d_%d"%[mode,"gentle" if assist else "skillful",cup_stage if cup_active else difficulty,styles[0]]
	result_rewards = library.record_result(str(course.id),float(sim.racers[0].finish_time),stars,finish_rank,record_mode)
	if cup_active:
		for i in range(sim.racers.size()): cup_points[i] += [5,3,1][_rank(i)-1]
	_make_modal()
	var title := "A HAPPY FINISH!"
	if finish_rank==1: title = "FIRST-CLASS DOODLING!"
	if cup_active and cup_stage==2: title = "DOODLE CUP COMPLETE!"
	_label(title,Vector2(341,176),Vector2(601,57),34,INK,true,_modal)
	var detail := "%s place  •  %.1f seconds  •  %d stars"%[_ordinal(finish_rank),float(sim.racers[0].finish_time),stars]
	if mode=="local": detail = "P1: %s  •  P2: %s  —  two brilliant little drivers!"%[_ordinal(_rank(0)),_ordinal(_rank(1))]
	_label(detail,Vector2(347,249),Vector2(595,32),20,INK,false,_modal)
	_label("NEW PERSONAL BEST!" if result_rewards.get("new_best",false) else "Every finish is another story for your sketchbook.",Vector2(347,299),Vector2(588,33),23,Color("478b8e"),true,_modal)
	var reward_text := "+%d inspiration stars  •  %d in your collection"%[int(result_rewards.get("coins_earned",0)),library.coins]
	if cup_active: reward_text = "Cup points: YOU %d   /   Rocket %d   /   Cloud %d"%[cup_points[0],cup_points[1],cup_points[2]]
	_label(reward_text,Vector2(347,351),Vector2(595,34),18,MUTED,false,_modal)
	_label("Stickers unlocked: "+(", ".join(library.stickers) if not library.stickers.is_empty() else "finish a race to earn your first"),Vector2(347,393),Vector2(585,32),16,MUTED,false,_modal)
	var next := _button("Next playground  >" if cup_active and cup_stage<2 else "Race again!",Vector2(348,470),Vector2(285,57),_result_continue,true,_modal)
	_button("Dream garage",Vector2(653,470),Vector2(273,57),show_garage,false,_modal)
	if not library.last_error.is_empty(): _label(library.last_error,Vector2(342,540),Vector2(610,25),12,Color("a4423c"),false,_modal)
	var podium = load("res://scripts/rally_podium.gd").new()
	podium.style = int(styles[0])
	podium.paint = PAINTS[colors[0]]
	_modal.add_child(podium)
	next.grab_focus()
	if is_instance_valid(audio): audio.event("finish",int(styles[0]))

func _result_continue() -> void:
	if cup_active and cup_stage<2:
		cup_stage += 1
		selected_course_id = str(library.courses[cup_stage].id)
	elif cup_active:
		cup_stage = 0
		cup_points.assign([0,0,0])
		selected_course_id = str(library.courses[0].id)
	start_race()

func open_editor(source: Dictionary = {}) -> void:
	_save_preferences()
	race_state = "editor"
	_clear_screen()
	editor = Editor.new()
	add_child(editor)
	editor.race_requested.connect(func(edited: Dictionary):
		selected_course_id = str(edited.id)
		mode = "solo" if mode=="cup" else mode
		cup_active = false
		start_race())
	editor.exit_requested.connect(show_garage)
	editor.saved.connect(func(edited: Dictionary): selected_course_id = str(edited.id))
	editor.configure(library,source)
	queue_redraw()

func _open_settings() -> void:
	if _settings_open: return
	_settings_open = true
	var panel = load("res://scripts/settings_panel.gd").new()
	add_child(panel)
	panel.open_panel(func():
		_settings_open = false
		_refresh_prompts())

func _unhandled_input(event: InputEvent) -> void:
	if _settings_open: return
	if event.is_action_pressed("pause"):
		if race_state in ["countdown","racing"]: pause_race()
		elif race_state=="paused": resume_race()
		elif race_state=="garage": _close()
		elif race_state=="results": show_garage()
		else: return
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not test_mode and race_state in ["racing","countdown"]:
		pause_race("Paused while you were away. Your race is safe.")

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),PAPER)
	for i in range(25): draw_line(Vector2(0,14+i*29),Vector2(1280,14+i*29),Color("eee6d3"),1)
	if race_state=="garage":
		for i in range(8):
			var x := 425.0+i*68
			var y := 44.0+sin(i*1.8)*11
			draw_arc(Vector2(x,y),8,0,TAU,5,Color("d1c7ab"),2,true)

func _confirm_erase() -> void:
	var selected_course: Dictionary = library.get_course(selected_course_id)
	if selected_course.is_empty() or not selected_course_id.begins_with("custom_"): return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Erase this course?"
	dialog.dialog_text = "Erase %s and its personal bests from your sketchbook?"%selected_course.title
	dialog.ok_button_text = "Erase course"
	dialog.cancel_button_text = "Keep my course"
	add_child(dialog)
	dialog.confirmed.connect(func():
		if library.delete_course(selected_course_id): selected_course_id = "desk"
		show_garage())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(500,180))
