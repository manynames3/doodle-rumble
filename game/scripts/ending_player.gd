extends Control
signal completed
const Story = preload("res://scripts/ending_storyboard.gd")
var video: VideoStreamPlayer
var story
var music: AudioStreamPlayer
var elapsed = 0.0
var finished = false
var page = 0
var skip: Button
var is_storybook = false
var custom_hero := ""
var cameo_shown := false
var _background_focus: Array[Dictionary] = []
var _previous_focus: WeakRef

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	z_index=50
	var focused := get_viewport().gui_get_focus_owner()
	_previous_focus = weakref(focused) if focused != null else null
	_block_background_focus(get_parent())
	var backdrop=ColorRect.new()
	backdrop.color=Color("080c17")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	Sound.set_external_music_active(true)
	is_storybook=Settings.reduced_motion or not ResourceLoader.exists("res://assets/cinematics/ending.ogv")
	if is_storybook:
		story=Story.new()
		story.manual=true
		add_child(story)
		story.seek(2.5)
		var captions=load("res://scripts/ending_captions.gd").new()
		captions.story=story
		add_child(captions)
		music=AudioStreamPlayer.new()
		music.stream=load("res://assets/cinematics/ending_music.wav")
		add_child(music)
		music.volume_db=linear_to_db(maxf(0.00001,_volume()))
		if _volume()>0: music.play()
	else:
		video=VideoStreamPlayer.new()
		video.expand=true
		video.size=Vector2(1280,720)
		video.stream=load("res://assets/cinematics/ending.ogv")
		video.volume=_volume()
		add_child(video)
		video.finished.connect(finish)
		video.play()
	skip=Button.new()
	skip.text="Next page  >" if is_storybook else "Skip  >"
	skip.position=Vector2(1100,26)
	skip.size=Vector2(140,42)
	skip.add_theme_font_size_override("font_size",19)
	add_child(skip)
	skip.pressed.connect(next_page if is_storybook else finish)
	skip.grab_focus()

func _block_background_focus(node: Node) -> void:
	# Pointer blocking alone does not stop Tab or gamepad focus escaping.
	if node == self: return
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		_background_focus.append({"control":weakref(node),"mode":node.focus_mode})
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): _block_background_focus(child)

func _restore_background_focus() -> void:
	for saved in _background_focus:
		var control: Variant = saved.control.get_ref()
		if is_instance_valid(control): control.focus_mode = saved.mode
	_background_focus.clear()
	var previous: Variant = _previous_focus.get_ref() if _previous_focus != null else null
	_previous_focus = null
	if is_instance_valid(previous) and previous.is_inside_tree() and previous.is_visible_in_tree() and previous.focus_mode != Control.FOCUS_NONE:
		previous.grab_focus()

func _volume() -> float:
	if DisplayServer.get_name()=="headless" or "--silent-qa" in OS.get_cmdline_user_args(): return 0.0
	return Settings.master_volume*Settings.music_volume

func _process(delta: float) -> void:
	if cameo_shown: return
	elapsed+=delta
	if video: video.volume=_volume()
	if music: music.volume_db=linear_to_db(maxf(0.00001,_volume()))
	# A damaged or unsupported stream must never trap the player after winning.
	if not is_storybook and elapsed>Story.DURATION+3.0: finish()

func next_page() -> void:
	page+=1
	if page>=6:
		finish()
		return
	story.seek(page*5+2.5)
	skip.text="Done  >" if page==5 else "Next page  >"

func _unhandled_input(event: InputEvent) -> void:
	if elapsed<0.3: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if finished: return
	if not cameo_shown and not custom_hero.is_empty() and Doodles.has(custom_hero):
		_show_custom_celebration()
		return
	finished=true
	if video: video.stop()
	if music: music.stop()
	Sound.set_external_music_active(false)
	_restore_background_focus()
	completed.emit()

func _show_custom_celebration() -> void:
	cameo_shown = true
	if video: video.stop()
	if music: music.stop()
	for child in get_children():
		if child is CanvasItem: child.hide()
	Sound.set_external_music_active(false)
	Sound.play("match_win")
	var background := ColorRect.new()
	background.size = Vector2(1280,720)
	background.color = Color("101b30")
	add_child(background)
	var font = load("res://assets/fonts/Kalam-Bold.ttf")
	var definition: Dictionary = Data.fighter(custom_hero)
	for entry in [["YOU DREW A HERO.",76,46],["AND SAVED THE SAVE STAR!",137,25],[str(definition.name),524,36],["Drawn by you.",577,24]]:
		var label := Label.new()
		label.text = entry[0]
		label.position = Vector2(150,entry[1])
		label.size = Vector2(980,65)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",entry[2])
		label.add_theme_color_override("font_color",Color("ffe9b5"))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_child(label)
	var actor = load("res://scripts/fighter_rig.gd").new()
	add_child(actor)
	actor.configure(definition)
	actor.position = Vector2(615,512)
	actor.scale = Vector2.ONE*1.8
	actor.preview = true
	actor.pose(0,{"grounded":true,"facing":1,"victory":true,"reduced_motion":Settings.reduced_motion})
	var done := Button.new()
	done.text = "Back to your victory  >"
	done.position = Vector2(445,645)
	done.size = Vector2(390,49)
	done.add_theme_font_override("font",font)
	done.add_theme_font_size_override("font_size",23)
	add_child(done)
	done.pressed.connect(finish)
	done.grab_focus()

func _exit_tree() -> void:
	_restore_background_focus()
	Sound.set_external_music_active(false)
