extends Node2D
## Match coordinator. Rendering and menus never own combat clocks.
const Fighter = preload("res://scripts/fighter.gd")
const Rules = preload("res://scripts/match_rules.gd")
const AI = preload("res://scripts/ai_controller.gd")
const BossAI = preload("res://scripts/boss_controller.gd")
const HackerAI = preload("res://scripts/hacker_controller.gd")
const PacAI = preload("res://scripts/pacman_controller.gd")
const Journey = preload("res://scripts/solo_ladder.gd")
const BossProjectile = preload("res://scripts/boss_projectile.gd")
const Projectile = preload("res://scripts/attack_effect.gd")
const Arena = preload("res://scripts/arena_art.gd")
const ArenaInteractions = preload("res://scripts/arena_interactions.gd")
const ArenaLayout = preload("res://scripts/arena_layout.gd")
const Foreground = preload("res://scripts/foreground_props.gd")
const Juice = preload("res://scripts/juice.gd")
const Hazards = preload("res://scripts/hazards.gd")
const InkHUD = preload("res://scripts/ink_hud.gd")
const HandFont = preload("res://assets/fonts/Kalam-Bold.ttf")
const INK = Color("edf1ff")
const PAPER = Color("15182b")
const ORANGE = Color("ffac3b")
const MUTED = Color("a8afca")
const ArenaCatalog = preload("res://scripts/arena_catalog.gd")
const ARENA_NAMES = ArenaCatalog.NAMES
var world: Node2D
var arena: Node2D
var interactions: Node2D
var platform_bodies: Array = []
var foreground: Node2D
var juice: Node2D
var hazards: Node2D
var camera: Camera2D
var ui: Control
var overlay: Control
var first
var second
var rules = Rules.new()
var ai = AI.new()
var boss_ai = BossAI.new()
var pac_ai = PacAI.new()
var hacker_ai = HackerAI.new()
var hazard_sequence = 0
var projectiles: Array = []
var state = "title"
var mode = "solo"
var arena_kind = "desktop"
var selected = ["orange","blue"]
var selecting_player = 0
var selection_tab := "original"
var workshop_practice: Dictionary = {}
var arcade_stage = 0
var journey_stage_won: bool = false
var journey_rewarded: bool = false
var optional_hazards = true
var hazard_clock = 8.0
var countdown = 0.0
var result_delay = 0.0
var training_reset = 0.0
var shake = 0.0
var preview_time = 0.0
var settings_open = false
var paused_reason = "Take a breather. Your doodles will wait."
var health_bars: Array = []
var health_labels: Array = []
var special_labels: Array = []
var cooldown_bars: Array = []
var score_labels: Array = []
var timer_label: Label
var hint_label: Label
var enemy_warning_label: Label
var prompts: Array = []
var countdown_label: Label
var practice_hits = 0
var practice_jumped = false
var practice_moved = false
var practice_special = false
var test_mode = false
var ending_player: Control
var title_prompt: Label
var quitting = false
var hud_note_started_at := 0
var fresh_journey := false
var match_stats: Dictionary = {}
var coach: Control
var practice_counter_clock := 2.8
var music_phase := "intro"
var previous_warning := ""
var story_scene: Control
const Chapters = preload("res://scripts/story_chapters.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
var difficulty_level: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	test_mode = "--test-mode" in OS.get_cmdline_user_args()
	selected[0] = Settings.selected_fighter
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	arena = Arena.new()
	world.add_child(arena)
	_add_surface(ArenaLayout.FLOOR)
	interactions = ArenaInteractions.new()
	world.add_child(interactions)
	interactions.z_index = 3
	arena.interactions = interactions
	interactions.activated.connect(_on_arena_interaction)
	_rebuild_platforms()
	var contact_shadows = load("res://scripts/contact_shadows.gd").new()
	contact_shadows.host = self
	contact_shadows.z_index = 4
	world.add_child(contact_shadows)
	foreground = Foreground.new()
	world.add_child(foreground)
	juice = Juice.new()
	world.add_child(juice)
	juice.z_index = 10
	hazards = Hazards.new()
	world.add_child(hazards)
	hazards.z_index = 2
	camera = Camera2D.new()
	camera.position = Vector2(640,360)
	add_child(camera)
	var layer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	Settings.controller_lost.connect(func(_slot):
		if state == "playing": pause_game("Controller disconnected. Reconnect or use the keyboard."))
	boss_ai.pattern_released.connect(func(kind): _boss_pattern(kind))
	pac_ai.pattern_released.connect(func(kind): _boss_pattern(kind))
	hacker_ai.pattern_released.connect(func(kind): _hacker_pattern(kind))
	show_title()

func _add_surface(rect: Rect2, one_way: bool = false) -> StaticBody2D:
	var body = StaticBody2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	var collision = CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	body.position = rect.get_center()
	world.add_child(body)
	return body

func _rebuild_platforms() -> void:
	for body in platform_bodies:
		body.collision_layer = 0
		body.queue_free()
	platform_bodies.clear()
	var large_boss: bool = mode == "arcade" and selected[1] == "dark_lord"
	for ledge in ArenaLayout.get_platforms(arena_kind,large_boss):
		platform_bodies.append(_add_surface(ledge,true))
	arena.boss_large = large_boss
	interactions.configure(arena_kind,platform_bodies,large_boss)

func _on_arena_interaction(kind: String, at: Vector2) -> void:
	var cue: String = "jump" if kind in ["spring","gust"] else "signal" if kind in ["teleport","data_lift"] else "hammer" if kind in ["crumble","bumper"] else "special"
	Sound.play(cue)
	juice.dust(at)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing" and not test_mode:
		pause_game("Paused while you were away. Ready when you are.")

func _unhandled_input(event: InputEvent) -> void:
	if settings_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return
	if state in ["racing","story","workshop"]:
		return
	if event.is_action_pressed("pause") or (state in ["select","stage_select","journal"] and event.is_action_pressed("ui_cancel")):
		if state == "playing": pause_game()
		elif state == "paused": resume_game()
		elif state == "stage_select": open_selection(mode)
		elif state in ["select","journal"]: show_title()
		get_viewport().set_input_as_handled()

func _clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	health_bars.clear()
	health_labels.clear()
	special_labels.clear()
	cooldown_bars.clear()
	score_labels.clear()
	prompts.clear()
	countdown_label = null
	overlay = null
	title_prompt = null
	enemy_warning_label = null

func _style(color: Color, _radius: int = 14, border: Color = Color("4d4b78"), width: int = 2) -> StyleBox:
	return load("res://scripts/ink_style.gd").make(color,border,width)

func _panel(parent: Node, rect: Rect2, color: Color = PAPER, border: Color = Color("4d4b78")) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel",_style(color,18,border,2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _text(parent: Node, value: String, rect: Rect2, size_px: int = 22, color: Color = INK, centered: bool = false, wrap: bool = false) -> Label:
	var label = Label.new()
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_color_override("font_color",color)
	label.add_theme_font_size_override("font_size",size_px)
	if size_px >= 27 or (value == value.to_upper() and value.length() > 3):
		label.add_theme_font_override("font",HandFont)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, rect: Rect2, callback: Callable, fill: Color = PAPER, big: bool = false, press_cue: String = "menu_select", hover_cue: String = "menu_move") -> Button:
	var button = Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size",26 if big else 19)
	button.add_theme_font_override("font",HandFont)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(key,Color("151427") if fill.get_luminance() > 0.36 else INK)
	button.add_theme_stylebox_override("normal",_style(fill))
	button.add_theme_stylebox_override("hover",_style(fill.lightened(0.10),14,ORANGE,3))
	button.add_theme_stylebox_override("pressed",_style(fill.darkened(0.08),14,Color("bd7fff"),3))
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,14,Color("df8536"),4))
	button.pressed.connect(func():
		if not press_cue.is_empty(): Sound.play(press_cue)
		callback.call())
	button.mouse_entered.connect(func():
		if not hover_cue.is_empty(): Sound.play(hover_cue))
	parent.add_child(button)
	return button

func _portrait(parent: Node, id: String, at: Vector2, size_scale: float = 1.0, facing: int = 1):
	# Story panels use full-size animated portraits. The tiny match HUD instead
	# draws an ink icon so it never instantiates a second custom-art renderer.
	var rig = load("res://scripts/fighter_rig.gd").new()
	rig.position = at
	rig.scale = Vector2(size_scale * facing,size_scale)
	parent.add_child(rig)
	rig.configure(Data.fighter(id))
	rig.preview = false
	rig.pose(0,{"grounded":true,"facing":facing,"reduced_motion":Settings.reduced_motion})
	return rig

func _poster(parent: Node, dim: float = 0.0) -> void:
	var picture = TextureRect.new()
	picture.texture = load("res://assets/intro_poster_v060.png")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.size = Vector2(1280,720)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	if dim > 0:
		var shade = ColorRect.new()
		shade.size = Vector2(1280,720)
		shade.color = Color(0.015,0.018,0.06,dim)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(shade)

func show_title() -> void:
	workshop_practice.clear()
	Sound.set_music_context("title")
	get_tree().paused = false
	state = "title"
	world.show()
	_hide_fighters()
	arena.arena_kind = "desktop"
	arena.training = false
	hazards.camera_bugs = false
	hazards.clear()
	_clear_ui()
	_poster(ui)
	var menu = load("res://scripts/title_menu.gd").new()
	ui.add_child(menu)
	menu.build([
		["Story Mode",show_story_hub,"Six battles. One big adventure. Choose your doodle."],
		["Quick Match",func(): selecting_player = 0; open_selection("solo"),"Choose two fighters and a stage for a quick rumble."],
		["2P Battle",func(): selecting_player = 0; open_selection("local"),"Two players, your doodles, one great showdown."],
		["Doodle Rally",start_racing,"Take your imagination for a spin."],
		["Settings",open_settings,"Make the sound, motion and controls your own."],
		["Quit",quit_game,"Your next adventure will be waiting."]
	])

func _boss_pattern(kind: String) -> void:
	if state != "playing" or not is_instance_valid(second): return
	if kind in ["void_orb","pellet_fan","eclipse_volley"]:
		var angles = [-0.24,0.0,0.24] if kind == "void_orb" else [-0.40,0.0,0.40] if kind == "pellet_fan" else [-0.44,-0.22,0.0,0.22,0.44]
		for angle in angles:
			var projectile = BossProjectile.new()
			world.add_child(projectile)
			projectile.configure(second,kind,second.facing,angle)
			projectile.z_index = 6
			projectiles.append(projectile)
		Sound.play("boss" if kind in ["void_orb","eclipse_volley"] else "pickaxe")
	elif kind == "rift":
		_boss_hazard("dark_lord","dark_rift")
	elif kind == "eclipse_wave":
		_boss_hazard("dark_lord","eclipse_wave")
	elif kind == "void_pillar":
		_boss_hazard("dark_lord","void_pillar")
	else:
		_boss_hazard("dark_lord")

func _hacker_pattern(kind: String) -> void:
	if state != "playing" or not is_instance_valid(second): return
	if kind == "checksum_volley":
		for angle in [-0.22,0.0,0.22]:
			var projectile = BossProjectile.new()
			world.add_child(projectile)
			projectile.configure(second,kind,second.facing,angle)
			projectile.z_index = 6
			projectiles.append(projectile)
		Sound.play("signal")
	else:
		_boss_hazard("h4ck3r",kind)

func _boss_hazard(owner_id: String, kind: String = "") -> void:
	if state != "playing" or not is_instance_valid(first): return
	var cycle = ["camera","eraser_drop","ink_geyser","cursor_stamp"]
	if kind.is_empty(): kind = cycle[hazard_sequence%cycle.size()]
	hazards.mark_target(first.position.x,hazard_sequence%2,kind,owner_id)
	hazard_sequence += 1
	Sound.play("warning")

func start_racing() -> void:
	Sound.set_music_context("racing")
	state = "racing"
	get_tree().paused = false
	_hide_fighters()
	world.hide()
	_clear_ui()
	var racing = load("res://scripts/racing_game.gd").new()
	ui.add_child(racing)
	racing.test_mode = test_mode
	racing.open_game(show_title)

func _hide_fighters() -> void:
	if is_instance_valid(first): first.hide()
	if is_instance_valid(second): second.hide()
	for projectile in projectiles: _discard_projectile(projectile)
	projectiles.clear()

func _discard_projectile(projectile) -> void:
	if projectile.has_method("cleanup"): projectile.cleanup()
	projectile.queue_free()

func new_journey_selection() -> void:
	arcade_stage = 0
	fresh_journey = true
	journey_stage_won = false
	journey_rewarded = false
	selecting_player = 0
	open_selection("arcade")

func journey_stage_data(index: int = -1) -> Dictionary:
	return Journey.stage(arcade_stage if index < 0 else index)

func journey_selection_stage() -> int:
	return mini(arcade_stage+1,Journey.STAGES.size()-1) if journey_stage_won else arcade_stage

func journey_caption(index: int = -1) -> String:
	var stage_index = arcade_stage if index < 0 else index
	var entry = journey_stage_data(stage_index)
	return "STAGE %d / %d  ·  %s  ·  %s" % [stage_index+1,Journey.STAGES.size(),Data.fighter(entry.opponent).name,entry.difficulty]

func journey_list() -> String:
	var names: PackedStringArray = []
	for entry in Journey.STAGES:
		names.append(Data.fighter(entry.opponent).name)
	return "  >  ".join(names)

func open_selection(new_mode: String = "arcade") -> void:
	workshop_practice.clear()
	mode = new_mode
	if not Data.is_playable(selected[0]): selected[0] = "orange"
	if mode != "arcade" and not Data.is_playable(selected[1]):
		selected[1] = "blue"
	if mode == "arcade": selecting_player = 0
	state = "select"
	get_tree().paused = false
	_hide_fighters()
	_clear_ui()
	_poster(ui,0.84)
	var selection = load("res://scripts/selection_screen.gd").new()
	ui.add_child(selection)
	selection.build(self)

func open_workshop(id: String = "") -> void:
	state = "workshop"
	get_tree().paused = false
	_hide_fighters()
	hazards.clear()
	_clear_ui()
	var workshop = load("res://scripts/doodle_workshop.gd").new()
	ui.add_child(workshop)
	workshop.cancelled.connect(func(): selection_tab="custom"; open_selection(mode))
	workshop.saved.connect(func(saved_id: String):
		selected[selecting_player] = saved_id
		Settings.selected_fighter = selected[0]
		Settings.save_settings()
		selection_tab = "custom"
		if mode in ["solo","local"]: open_stage_selection()
		elif mode == "arcade": continue_journey()
		else: start_match())
	workshop.practice_requested.connect(func(saved_id: String):
		workshop_practice = {"id":saved_id,"mode":mode,"player":selecting_player,"selected":selected.duplicate()}
		selected = [saved_id,"blue"]
		mode = "training"
		start_match())
	workshop.build(self,Doodles.get_record(id) if Doodles.has(id) else Doodles.new_record())

func return_to_workshop() -> void:
	if workshop_practice.is_empty(): return
	var context := workshop_practice.duplicate(true)
	workshop_practice.clear()
	mode = context.mode
	selecting_player = int(context.player)
	selected = context.selected.duplicate()
	open_workshop(str(context.id))

func open_stage_selection() -> void:
	if mode not in ["solo","local"]:
		open_selection(mode)
		return
	state = "stage_select"
	get_tree().paused = false
	_hide_fighters()
	_clear_ui()
	_poster(ui,0.86)
	var selection = load("res://scripts/stage_selection.gd").new()
	ui.add_child(selection)
	selection.build(self)

func _combat_difficulty() -> int:
	return difficulty_level if mode in ["solo","arcade"] else 0

func start_arcade() -> void:
	arcade_stage = 0
	mode = "arcade"
	journey_stage_won = false
	journey_rewarded = false
	start_match()

func continue_journey() -> void:
	if journey_stage_won and arcade_stage < Journey.STAGES.size()-1:
		arcade_stage += 1
	if fresh_journey:
		Chronicle.begin_run(selected[0],optional_hazards,difficulty_level)
		fresh_journey = false
	_begin_story_match()

func _begin_story_match() -> void:
	Chronicle.checkpoint(arcade_stage,selected[0],optional_hazards,difficulty_level)
	if test_mode: start_match()
	else: _show_story_scene(false,start_match)

func show_story_hub() -> void:
	get_tree().paused = false
	state = "journal"
	_hide_fighters()
	hazards.clear()
	_clear_ui()
	_poster(ui,0.88)
	Sound.set_music_context("story")
	var journal = load("res://scripts/story_journal.gd").new()
	ui.add_child(journal)
	journal.build(self)

func resume_story() -> void:
	if not Chronicle.active:
		new_journey_selection()
		return
	arcade_stage = Chronicle.stage
	selected[0] = Chronicle.fighter
	optional_hazards = Chronicle.hazards
	difficulty_level = Chronicle.difficulty_level
	journey_stage_won = false
	journey_rewarded = false
	fresh_journey = false
	selecting_player = 0
	selection_tab = "custom" if Doodles.has(selected[0]) else "original"
	open_selection("arcade")

func replay_chapter(index: int) -> void:
	if index not in Chronicle.completed: return
	_show_story_scene(false,func(): _show_story_scene(true,show_story_hub,index),index)

func _show_story_scene(after: bool, finished: Callable, index: int = -1) -> void:
	get_tree().paused = false
	state = "story"
	_hide_fighters()
	_clear_ui()
	Sound.set_music_context("story")
	story_scene = load("res://scripts/story_scene.gd").new()
	ui.add_child(story_scene)
	story_scene.build(self,arcade_stage if index < 0 else index,after,func():
		if is_instance_valid(story_scene):
			ui.remove_child(story_scene)
			story_scene.queue_free()
			story_scene = null
		finished.call())

func _after_stage_story(final_win: bool) -> void:
	if test_mode: return
	_show_story_scene(true,func():
		state = "match_over"
		first.show()
		second.show()
		build_hud()
		_show_result()
		if final_win: play_ending())

func start_match() -> void:
	get_tree().paused = false
	state = "playing"
	if mode == "arcade":
		arcade_stage = clampi(arcade_stage,0,Journey.STAGES.size()-1)
		var entry = journey_stage_data()
		arena_kind = entry.arena
		selected[1] = entry.opponent
		ai.configure(int(entry.ai_level))
	else:
		ai.configure(1)
	if not Data.is_playable(selected[0]): selected[0] = "orange"
	if mode != "arcade" and not Data.is_playable(selected[1]):
		selected[1] = "blue"
	journey_stage_won = false
	match_stats = {"air":false,"counter":false,"special_hits":0,"special_serials":[],"healthy":false}
	if mode == "arcade": Chronicle.checkpoint(arcade_stage,selected[0],optional_hazards,difficulty_level)
	for fighter in [first,second]:
		if is_instance_valid(fighter):
			world.remove_child(fighter)
			fighter.queue_free()
	first = Fighter.new()
	second = Fighter.new()
	world.add_child(first)
	world.add_child(second)
	first.setup(selected[0],1)
	second.setup(selected[1],2)
	for fighter in [first,second]:
		fighter.z_index = 5
		fighter.attacked.connect(_on_attack)
		fighter.released.connect(_on_release)
		fighter.damaged.connect(_on_damage)
		fighter.jumped.connect(_on_jump)
		fighter.landed.connect(_on_land)
		fighter.dodge_started.connect(_on_dodge)
		fighter.perfect_dodged.connect(_on_perfect_dodge)
		fighter.guarded.connect(_on_guarded)
	rules.reset()
	practice_hits = 0
	practice_jumped = false
	practice_moved = false
	practice_special = false
	var music_context: String = selected[1] if selected[1] in ["pac_man","dark_lord"] else "journey_green" if mode == "arcade" and arcade_stage == 2 else arena_kind
	music_context = {"canopy":"journey_green","arcade":"pac_man","network":"glitch"}.get(music_context,music_context)
	Sound.set_music_context(music_context)
	arena.arena_kind = arena_kind
	_rebuild_platforms()
	arena.training = mode == "training"
	hazards.camera_bugs = selected[1] == "dark_lord"
	_reset_round()
	build_hud()

func _reset_round() -> void:
	interactions.reset()
	juice.particles.clear()
	juice.words.clear()
	juice.marks.clear()
	shake = 0.0
	for projectile in projectiles: _discard_projectile(projectile)
	projectiles.clear()
	first.show()
	second.show()
	first.reset_at(Vector2(420,599))
	second.reset_at(Vector2(860,599))
	first.facing = 1
	second.facing = -1
	first.update_art(0)
	second.update_art(0)
	for controller in [ai,boss_ai,pac_ai,hacker_ai]:
		controller.configure_difficulty(_combat_difficulty())
	ai.reset()
	boss_ai.reset()
	pac_ai.reset()
	hacker_ai.reset()
	hazard_sequence = 0
	hazards.clear()
	hazard_clock = Difficulty.opening_hazard_delay(_combat_difficulty())
	training_reset = 0
	countdown = 0.95 if mode != "training" else 0.25
	music_phase = "intro"
	Sound.set_music_phase(music_phase)
	Sound.play("round_start")
	practice_counter_clock = 2.8

func next_round() -> void:
	rules.next_round()
	state = "playing"
	_reset_round()
	build_hud()

func rematch() -> void:
	start_match()

func advance_arcade() -> void:
	if mode != "arcade" or not journey_stage_won or not rules.finished or rules.last_winner != 0 or arcade_stage >= Journey.STAGES.size()-1:
		return
	arcade_stage += 1
	_begin_story_match()

func _progress(parent: Node, rect: Rect2, color: Color, max_value: float = 100) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.max_value = max_value
	bar.show_percentage = false
	var background = _style(Color("272841"),6,Color("51476b"),1)
	var fill = _style(color,5,Color.TRANSPARENT,0)
	for style in [background,fill]:
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	bar.size = rect.size
	return bar

func build_hud() -> void:
	_clear_ui()
	var ink_hud = InkHUD.new()
	ui.add_child(ink_hud)
	ink_hud.bind(self)
	hud_note_started_at = Time.get_ticks_msec()
	for i in range(2):
		var x = 66 if i == 0 else 824
		var fighter = first if i == 0 else second
		var identity = "  /  YOU" if i == 0 and mode != "local" else "  /  P%d" % (i+1) if mode == "local" else "  /  DUMMY" if mode == "training" else ""
		var name_label = _text(ui,fighter.definition.name.to_upper() + identity,Rect2(x,12,390,26),19)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_font_override("font",HandFont)
		if i == 1: name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		health_bars.append(_progress(ui,Rect2(x,39,390,18),Color(fighter.definition.color),fighter.max_health))
		health_bars[-1].hide()
		health_labels.append(_text(ui,"100",Rect2(x,12,1,1),1,Color.TRANSPARENT))
		health_labels[-1].hide()
		cooldown_bars.append(_progress(ui,Rect2(67 if i == 0 else 1137,68,76,5),Color(fighter.definition.color),6))
		cooldown_bars[-1].hide()
		var special_x = 61 if i == 0 else 839
		var special = _text(ui,"READY",Rect2(special_x,58,320,20),12,Color("e8e2d2"),i == 1)
		special.add_theme_font_override("font",HandFont)
		special_labels.append(special)
		score_labels.append(_text(ui,"○  ○",Rect2(481 if i == 0 else 699,19,100,40),24,Color(fighter.definition.color),true))
		score_labels[-1].hide()
	timer_label = _text(ui,str(int(Rules.ROUND_SECONDS)),Rect2(591,10,98,48),37,INK,true)
	timer_label.add_theme_font_override("font",HandFont)
	var round_note = _text(ui,"BEST OF 3" if mode != "training" else "NO CLOCK",Rect2(588,54,104,20),10,MUTED,true)
	round_note.add_theme_font_override("font",HandFont)
	var stage_copy = "%d/%d  ·  %s" % [arcade_stage+1,Journey.STAGES.size(),ARENA_NAMES[arena_kind]] if mode == "arcade" else ARENA_NAMES[arena_kind]
	var stage_note = _text(ui,stage_copy,Rect2(454,80,372,21),12,Color("e8e2d2"),true)
	stage_note.add_theme_font_override("font",HandFont)
	var notes = Control.new()
	notes.size = Vector2(1280,720)
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(notes)
	for i in range(2):
		var prompt = _text(notes,"",Rect2(29 if i==0 else 659,682,584,28),11,INK,i == 1)
		prompt.add_theme_font_override("font",HandFont)
		prompts.append(prompt)
	var pause = _button(ui,"Pause",Rect2(1191,87,67,28),pause_game,Color("090a11df"))
	pause.add_theme_font_size_override("font_size",13)
	if mode == "training":
		var reset_match = func():
			_reset_round()
			build_hud()
		var reset = _button(ui,"Reset",Rect2(1120,87,63,28),reset_match,Color("090a11df"))
		reset.add_theme_font_size_override("font_size",13)
		if not workshop_practice.is_empty():
			var back = _button(ui,"Back to workshop",Rect2(958,87,154,28),return_to_workshop,Color("090a11df"))
			back.add_theme_font_size_override("font_size",13)
	hint_label = _text(notes,"",Rect2(20,93,450,27),13,Color("f0dfaa"))
	hint_label.add_theme_font_override("font",HandFont)
	hint_label.add_theme_color_override("font_outline_color",Color("101329"))
	hint_label.add_theme_constant_override("outline_size",4)
	enemy_warning_label = _text(ui,"",Rect2(0,0,194,30),14,Color("ffda84"),true)
	enemy_warning_label.add_theme_font_override("font",HandFont)
	enemy_warning_label.add_theme_stylebox_override("normal",_style(Color("090a11df"),5,Color("ffda84"),1))
	enemy_warning_label.hide()
	countdown_label = _text(ui,"",Rect2(355,301,570,92),53,INK,true)
	countdown_label.add_theme_color_override("font_outline_color",Color("101329"))
	countdown_label.add_theme_constant_override("outline_size",8)
	if mode == "training":
		coach = load("res://scripts/practice_coach.gd").new()
		ui.add_child(coach)
		coach.build(self)
	_update_hud()

func _control_prompt(slot: int) -> String:
	if Settings.device_label(slot).begins_with("Controller"):
		return "P%d   Stick / D-pad move   South jump   West hit   East special   LB dodge" % (slot+1)
	var prefix = "p%d_" % (slot+1)
	return "P%d   %s/%s move   %s jump   %s hit   %s special   %s dodge" % [slot+1,Settings.binding_label(prefix+"move_left"),Settings.binding_label(prefix+"move_right"),Settings.binding_label(prefix+"jump"),Settings.binding_label(prefix+"attack"),Settings.binding_label(prefix+"special"),Settings.binding_label(prefix+"dodge")]

func _update_hud() -> void:
	if health_bars.is_empty() or not is_instance_valid(first): return
	for i in range(2):
		var fighter = first if i == 0 else second
		health_bars[i].value = fighter.health
		health_labels[i].text = str(fighter.health)
		cooldown_bars[i].value = 6-fighter.cooldown
		special_labels[i].text = ("✦ READY  /  " + fighter.definition.special_name) if fighter.cooldown <= 0 else "⌁ %.1fs  /  %s" % [fighter.cooldown,fighter.definition.special_name]
		score_labels[i].text = ("●" if rules.scores[i]>0 else "○") + "   " + ("●" if rules.scores[i]>1 else "○")
		prompts[i].text = _control_prompt(i) if i == 0 or mode == "local" else "Training dummy  /  Auto-refill" if mode == "training" else "Dark lord  /  Dodge, then strike!" if selected[1] == "dark_lord" else "Pac-Man  /  Hop over the charge!" if selected[1] == "pac_man" else str(journey_stage_data().difficulty) + " opponent  /  Watch the windup!" if mode == "arcade" else ["Easy","Medium","Hard"][difficulty_level]+" opponent  /  Watch the windup!"
		prompts[i].size.x = 584
	timer_label.text = "FREE" if mode == "training" else str(ceili(rules.remaining))
	if mode == "training":
		hint_label.text = "NO PRESSURE. EXPERIMENT AWAY."
	else:
		hint_label.text = "JUMP THE WAVE. WATCH THE FLOOR." if selected[1] == "dark_lord" else "SIDESTEP THE CURSOR. JUMP THE INK!" if selected[1] == "h4ck3r" else "WATCH THE MOUTH. HOP OVER THE CHARGE!" if selected[1] == "pac_man" else ("Hold attack to repeat. Jump + hit: air move. Dodge to counter!" if Settings.hold_to_attack else "Press attack to swing. Jump + hit: air move. Dodge to counter!")
	var note_alpha = 1.0 if mode == "training" else clampf(1.0 - (Time.get_ticks_msec() - hud_note_started_at - 4300.0) / 1500.0,0.0,1.0)
	hint_label.modulate.a = note_alpha
	for prompt in prompts: prompt.modulate.a = note_alpha
	if countdown_label:
		countdown_label.text = "READY?" if countdown > 0.5 else "RUMBLE!" if countdown > 0 else ""
	_update_enemy_warning()

func _update_enemy_warning() -> void:
	if not is_instance_valid(enemy_warning_label): return
	var warning = ""
	if state == "playing" and countdown <= 0 and is_instance_valid(second):
		warning = boss_ai.tell if selected[1] == "dark_lord" else hacker_ai.tell if selected[1] == "h4ck3r" else pac_ai.tell if selected[1] == "pac_man" else "WATCH THE SWING!" if ai.tell_time > 0 and mode in ["solo","arcade"] else ""
	if mode=="training" and is_instance_valid(coach) and coach.step==5 and second.attack_time>=0 and not second.is_active(): warning="PRACTICE SWING!"
	enemy_warning_label.visible = warning != ""
	enemy_warning_label.text = warning
	if warning != "" and warning != previous_warning: Sound.play_warning("boss" if selected[1] in ["dark_lord","pac_man","h4ck3r"] else "hazard")
	previous_warning = warning
	if warning != "":
		enemy_warning_label.position = Vector2(clampf(second.position.x-97,24,1062),clampf(second.position.y-second.visual_head_height()-42,116,526))

func _physics_process(delta: float) -> void:
	if state != "playing" or get_tree().paused: return
	if countdown > 0:
		countdown = maxf(0,countdown-delta)
		_update_hud()
		return
	var desired_music: String = "climax" if rules.remaining < 25 or first.health < first.max_health*0.3 or second.health < second.max_health*0.3 else "battle"
	if desired_music != music_phase:
		music_phase = desired_music
		Sound.set_music_phase(music_phase)
	var command1 = Settings.read_player(0)
	var command2 = {}
	if mode == "local": command2 = Settings.read_player(1)
	elif mode == "training" and is_instance_valid(coach) and coach.step == 5:
		practice_counter_clock -= delta
		var distance: float = first.position.x-second.position.x
		command2 = {"move":signf(distance)*0.35 if absf(distance)>140 else 0.0,"attack":practice_counter_clock<=0 and absf(distance)<200}
		if practice_counter_clock<=0: practice_counter_clock=3.2
		first.health = first.max_health
	elif mode != "training":
		command2 = boss_ai.read_input(delta,second,first) if selected[1] == "dark_lord" else hacker_ai.read_input(delta,second,first) if selected[1] == "h4ck3r" else pac_ai.read_input(delta,second,first) if selected[1] == "pac_man" else ai.read_input(delta,second,first)
	var arena_commands = interactions.begin_tick(delta,[first,second],[command1,command2])
	first.tick(delta,arena_commands[0],second)
	second.tick(delta,arena_commands[1],first)
	interactions.end_tick(delta,[first,second])
	first.try_hit(second)
	second.try_hit(first)
	for projectile in projectiles.duplicate():
		if projectile.has_method("set_platforms"):
			projectile.set_platforms(_projectile_platforms())
		var target = second if projectile.owner_fighter == first else first
		if projectile.tick(delta,target):
			juice.burst(projectile.position,projectile.tint)
			projectiles.erase(projectile)
			_discard_projectile(projectile)
	hazards.tick(delta,[first,second])
	if optional_hazards and (mode in ["solo","local","arcade"]):
		hazard_clock -= delta
		if hazard_clock <= 0:
			var kinds = ArenaCatalog.hazard_cycle(arena_kind)
			hazards.mark_target(640+sin(rules.remaining)*330,0,kinds[hazard_sequence%kinds.size()])
			hazard_sequence += 1
			var interval: float = [12,10,9,8,10,11][clampi(arcade_stage,0,5)] if mode == "arcade" else 8
			hazard_clock = Difficulty.hazard_interval(interval,_combat_difficulty())
	practice_moved = practice_moved or absf(first.position.x-420)>30
	if mode == "training":
		if second.health <= 0:
			training_reset += delta
			if training_reset >= 1.4:
				second.reset_at(Vector2(860,599))
				training_reset = 0
	elif rules.tick(delta,ceili(first.health*10000.0/first.max_health),ceili(second.health*10000.0/second.max_health)):
		_finish_round()
	_update_hud()

func _process(delta: float) -> void:
	preview_time += delta
	if state == "title" and is_instance_valid(title_prompt):
		title_prompt.text = _control_prompt(0)
	_update_enemy_warning()
	if is_instance_valid(arena):
		arena.reduced_motion = Settings.reduced_motion
		arena.focus_x = (first.position.x+second.position.x)/2 if is_instance_valid(first) and state in ["playing","round_over","match_over"] else 640.0
		foreground.arena_kind = arena.arena_kind
		foreground.reduced_motion = Settings.reduced_motion
		foreground.focus_x = arena.focus_x
	interactions.reduced_motion = Settings.reduced_motion
	hazards.reduced_motion = Settings.reduced_motion
	juice.reduced_motion = Settings.reduced_motion
	if is_instance_valid(first):
		first.reduced_motion = Settings.reduced_motion
		second.reduced_motion = Settings.reduced_motion
	shake = maxf(0,shake-delta*24)
	camera.offset = Vector2(sin(preview_time*91),cos(preview_time*73))*shake if not Settings.reduced_motion and state == "playing" else Vector2.ZERO
	if state in ["round_over","match_over"]:
		first.update_art(delta)
		second.update_art(delta)
	if state == "round_over":
		result_delay -= delta
		if result_delay <= 0: next_round()
	queue_redraw()

func _on_attack(fighter, special: bool) -> void:
	var cue: String = str(fighter.definition.special) if special and fighter.definition.special in ["signal","swarm"] else "special" if special else "boss" if fighter.definition.id == "dark_lord" else "swing" if fighter.definition.id == "pac_man" else "signal" if fighter.definition.id == "h4ck3r" else str(fighter.definition.weapon)
	if bool(fighter.definition.get("custom",false)):
		cue = str(fighter.definition.special if special else fighter.definition.weapon)
	Sound.play(cue)
	if fighter == first and special: practice_special = true

func _projectile_platforms() -> Array:
	var platforms: Array = ArenaLayout.get_platforms(arena_kind,selected[1]=="dark_lord").duplicate()
	if arena_kind == "quarry" and interactions.bridge_gone>0:
		platforms.remove_at(ArenaLayout.QUARRY_BRIDGE_INDEX)
	return platforms

func _on_release(fighter, kind: String) -> void:
	if kind in ["ore_pop","fossil_fetch","swerve_shot","cluckquake","rainbow_ruckus"]:
		var projectile = load("res://scripts/custom_projectile.gd").new()
		world.add_child(projectile)
		projectile.configure(fighter,kind,fighter.facing,_projectile_platforms())
		projectile.z_index = 6
		projectiles.append(projectile)
	elif kind == "shockwave":
		for direction in [-1,1]:
			var projectile = Projectile.new()
			world.add_child(projectile)
			projectile.configure(fighter,kind,direction)
			projectile.z_index = 6
			projectiles.append(projectile)
		juice.burst(Vector2(fighter.position.x,596),Color(fighter.definition.color),true)
		juice.crack(Vector2(fighter.position.x,600),Color(fighter.definition.color))
	elif kind in ["fragment","arrow","signal","swarm"]:
		var projectile = Projectile.new()
		world.add_child(projectile)
		projectile.configure(fighter,kind,fighter.facing)
		projectile.z_index = 6
		projectiles.append(projectile)
		juice.burst(fighter.position+Vector2(fighter.facing*45,-55)*fighter.body_scale,Color(fighter.definition.color))
	elif kind == "dash":
		juice.dash_trail(fighter.position,Color(fighter.definition.color),fighter.facing)
	else:
		juice.burst(fighter.position+Vector2(0,-65)*fighter.body_scale,Color(fighter.definition.color),true)

func _on_damage(fighter, amount: int, direction: int) -> void:
	var source = fighter.last_hit_source
	var attacker = source.owner_fighter if is_instance_valid(source) and source.get("owner_fighter") != null else source
	var attributed: bool = is_instance_valid(attacker) and attacker.get("definition") != null
	var hit_color := Color(attacker.definition.color) if attributed else Color("ffd077")
	var weapon_name: String = str(attacker.definition.weapon) if attributed else "hammer"
	Sound.play_impact(weapon_name,amount/20.0,"magic" if attributed and attacker.definition.id in ["dark_lord","purple","h4ck3r"] else "paper")
	juice.impact(fighter.position+Vector2(0,-72)*fighter.body_scale,hit_color,direction,amount>=20)
	juice.damage_number(fighter.position-Vector2(0,fighter.visual_head_height()+8),amount,hit_color,direction)
	shake = 4.6 if amount>=20 else 2.7
	for participant in [first,second]:
		participant.update_art(0)
		participant.begin_impact_hold(0.055)
	if fighter == second and attacker == first:
		practice_hits += 1
		if fighter.last_hit_air_kind not in ["","reflect"]: match_stats["air"] = true
		if fighter.last_hit_special and fighter.last_hit_attack_serial not in match_stats.get("special_serials",[]):
			match_stats.special_serials.append(fighter.last_hit_attack_serial)
			match_stats.special_hits += 1

func _on_dodge(fighter) -> void:
	Sound.play("swing")
	juice.dust(fighter.position)

func _on_perfect_dodge(fighter) -> void:
	if fighter == first: match_stats["counter"] = true
	if fighter.definition.id=="purple": return # Shield callback owns its contact sound/effect.
	Sound.play_guard("parry")
	juice.word(fighter.position-Vector2(0,fighter.visual_head_height()+12),"COUNTER!",Color("fff5bd"))
	juice.burst(fighter.position+Vector2(0,-70)*fighter.body_scale,Color(fighter.definition.color))

func _on_guarded(fighter, reflected: bool) -> void:
	Sound.play_guard("reflect" if reflected else "shield")
	juice.guard(fighter.position+Vector2(fighter.facing*32,-72)*fighter.body_scale,Color(fighter.definition.color),fighter.facing,reflected)
	if reflected:
		juice.word(fighter.position-Vector2(0,fighter.visual_head_height()+12),"RETURN TO SENDER!",Color("e8bcff"))
		if fighter == first: match_stats["counter"] = true

func _on_jump(fighter) -> void:
	Sound.play("jump")
	juice.dust(fighter.position)
	if fighter == first: practice_jumped = true

func _on_land(fighter, _speed) -> void:
	juice.dust(fighter.position)

func _finish_round() -> void:
	countdown = 0
	if is_instance_valid(countdown_label): countdown_label.text = ""
	state = "match_over" if rules.finished else "round_over"
	result_delay = 2.7
	# The scored round is over. Keep the camera and the real fighters at gameplay scale.
	first.attack_time = -1
	second.attack_time = -1
	first.position = Vector2(250,599)
	second.position = Vector2(1000,599)
	first.velocity = Vector2.ZERO
	second.velocity = Vector2.ZERO
	first.facing = 1
	second.facing = -1
	for projectile in projectiles: _discard_projectile(projectile)
	projectiles.clear()
	hazards.clear()
	first.victory = rules.last_winner == 0
	second.victory = rules.last_winner == 1
	first.result_defeated = rules.last_winner == 1
	second.result_defeated = rules.last_winner == 0
	first.update_art(0)
	second.update_art(0)
	if rules.last_winner >= 0:
		juice.celebrate()
	Sound.play("match_win" if rules.finished else "round_end")
	if rules.last_winner == 0 and first.health >= first.max_health/2: match_stats["healthy"] = true
	if rules.finished and mode == "arcade":
		journey_stage_won = rules.last_winner == 0
		if journey_stage_won: Chronicle.finish_stage(arcade_stage,Chapters.goal_met(arcade_stage,match_stats))
	var first_final_win = rules.finished and mode == "arcade" and arcade_stage == Journey.STAGES.size()-1 and rules.last_winner == 0 and not journey_rewarded
	if first_final_win:
		journey_rewarded = true
		Settings.arcade_wins += 1
		Settings.save_settings()
	_show_result()
	if journey_stage_won and rules.finished and not test_mode: _after_stage_story.call_deferred(first_final_win)

func play_ending() -> void:
	if is_instance_valid(ending_player): return
	state = "ending"
	ending_player = load("res://scripts/ending_player.gd").new()
	ending_player.custom_hero = selected[0] if Doodles.has(selected[0]) else ""
	ending_player.completed.connect(func():
		ending_player.queue_free()
		ending_player = null
		state = "match_over"
		_show_result())
	ui.add_child(ending_player)

func _show_result() -> void:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
	overlay = Control.new()
	overlay.size = Vector2(1280,720)
	ui.add_child(overlay)
	var is_journey: bool = mode == "arcade"
	var final_stage: int = Journey.STAGES.size()-1
	var winner = first if rules.last_winner == 0 else second
	var tint: Color = Color(winner.definition.color) if rules.last_winner >= 0 else Color("ddcaa5")
	var heading: String = winner.definition.name.to_upper()+" WINS!" if rules.last_winner >= 0 else "A DRAW!"
	if rules.finished and is_journey and arcade_stage == final_stage and rules.last_winner == 0: heading = "PLAYROOM CHAMPION!"
	# The match actors remain visible; result UI never substitutes enlarged portraits.
	first.show()
	second.show()
	var ribbon = _panel(overlay,Rect2(341,194,598,88),Color("101324f5"),tint)
	_text(ribbon,heading,Rect2(11,9,576,70),39,INK,true)
	var score = _panel(overlay,Rect2(547,292,186,61),Color("101324e8"),tint)
	_text(score,"%d  :  %d" % [rules.scores[0],rules.scores[1]],Rect2(0,2,186,55),33,Color("fff0cb"),true)
	if is_journey:
		_text(overlay,"CHAPTER %d  /  %s" % [arcade_stage+1,Chapters.chapter(arcade_stage).short.to_upper()],Rect2(324,153,632,35),22,tint,true)
	var description: String = "Next round in a moment..." if not rules.finished else "Another little rumble?"
	if rules.last_winner == -1: description = "Same health. Let's try that round again."
	if rules.finished and is_journey:
		description = "Chapter saved!  Next: "+Data.fighter(journey_stage_data(arcade_stage+1).opponent).name if rules.last_winner==0 and arcade_stage<final_stage else "Your story stays here. Try a new plan!" if rules.last_winner==1 else "The star is home. Your next idea is waiting."
	var caption = _text(overlay,description,Rect2(352,364,576,42),21,Color("fff0ce"),true,true)
	caption.add_theme_color_override("font_outline_color",Color("080b17"))
	caption.add_theme_constant_override("outline_size",6)
	var primary: Button
	if not rules.finished:
		primary = _button(overlay,"Next round  >",Rect2(355,423,274,56),next_round,ORANGE,true)
	elif is_journey and rules.last_winner==0 and arcade_stage<final_stage:
		primary = _button(overlay,"Next match  >",Rect2(355,423,274,56),advance_arcade,ORANGE,true)
	elif is_journey and rules.last_winner==0 and arcade_stage==final_stage:
		primary = _button(overlay,"New journey  >",Rect2(355,423,274,56),new_journey_selection,ORANGE,true)
		_button(overlay,"Watch the ending",Rect2(516,489,248,41),play_ending).name = "ReplayEnding"
	else:
		primary = _button(overlay,"Retry stage  >" if is_journey else "Rematch  >",Rect2(355,423,274,56),rematch,ORANGE,true)
	var change = _button(overlay,"Change fighters",Rect2(650,423,274,56),func(): selecting_player=0; open_selection(mode))
	primary.focus_next = primary.get_path_to(change)
	change.focus_previous = change.get_path_to(primary)
	if overlay.has_node("ReplayEnding"):
		var replay = overlay.get_node("ReplayEnding")
		change.focus_next = change.get_path_to(replay)
		replay.focus_previous = replay.get_path_to(change)
		replay.focus_next = replay.get_path_to(primary)
		primary.focus_previous = primary.get_path_to(replay)
	if is_journey and not (arcade_stage==final_stage and rules.last_winner==0): _button(overlay,"Sketchbook",Rect2(520,492,240,40),show_story_hub)
	primary.grab_focus()
	if not Settings.reduced_motion:
		ribbon.modulate.a = 0.0
		create_tween().tween_property(ribbon,"modulate:a",1.0,0.22)

func pause_game(reason: String = "Take a breather. Your doodles will wait.") -> void:
	if state != "playing": return
	state = "paused"
	paused_reason = reason
	get_tree().paused = true
	_show_pause()

func _show_pause() -> void:
	if overlay: overlay.queue_free()
	overlay = Control.new()
	overlay.size = Vector2(1280,720)
	ui.add_child(overlay)
	var dim = ColorRect.new()
	dim.color = Color(0.10,0.16,0.22,0.30)
	dim.size = Vector2(1280,720)
	overlay.add_child(dim)
	var card = _panel(overlay,Rect2(367,159,546,428),PAPER)
	_text(card,"PAUSED",Rect2(20,20,506,63),45,INK,true)
	_text(card,paused_reason,Rect2(15,84,516,45),16,MUTED,true)
	var resume = _button(card,"Keep playing  >",Rect2(37,143,472,64),resume_game,ORANGE,true)
	_button(card,"Settings",Rect2(37,224,227,53),open_settings)
	_button(card,"Restart match",Rect2(282,224,227,53),rematch)
	_button(card,"Choose fighters",Rect2(37,294,227,53),func(): open_selection(mode))
	_button(card,"Title screen",Rect2(282,294,227,53),show_title)
	_text(card,_control_prompt(0),Rect2(25,356,496,25),12,MUTED,true)
	if mode == "local":
		_text(card,_control_prompt(1),Rect2(25,385,496,25),12,MUTED,true)
	resume.grab_focus()

func resume_game() -> void:
	if state != "paused": return
	get_tree().paused = false
	state = "playing"
	if overlay:
		overlay.queue_free()
		overlay = null

func open_settings() -> void:
	if settings_open: return
	settings_open = true
	var panel = load("res://scripts/settings_panel.gd").new()
	ui.add_child(panel)
	panel.open_panel(func():
		settings_open = false
		if state == "paused": _show_pause()
		elif state == "title": show_title()
		elif state == "select": open_selection(mode)
		elif state == "stage_select": open_stage_selection()
		elif state == "journal": show_story_hub())

func quit_game(discard_draft: bool = false) -> void:
	if quitting: return
	if state == "workshop" and not discard_draft:
		for child in ui.get_children():
			if child.has_signal("practice_requested") and child.dirty:
				var confirm = child.get_node_or_null("ConfirmQuitDraft")
				if confirm == null:
					confirm = ConfirmationDialog.new()
					confirm.name = "ConfirmQuitDraft"
					confirm.title = "Keep drawing?"
					confirm.dialog_text = "Your latest changes have not been saved. Quit and leave them behind?"
					confirm.ok_button_text = "Quit without saving"
					confirm.cancel_button_text = "Keep drawing"
					child.add_child(confirm)
					confirm.confirmed.connect(func(): quit_game(true))
				confirm.popup_centered()
				return
	quitting = true
	Sound.shutdown()
	await get_tree().create_timer(0.1,true).timeout
	get_tree().quit()
