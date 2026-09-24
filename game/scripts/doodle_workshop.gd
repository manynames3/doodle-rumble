extends Control
## Child-friendly fighter maker. All coordinates in a record use a 512-square sheet.
signal saved(id: String)
signal cancelled
signal practice_requested(id: String)

const CanvasScript = preload("res://scripts/workshop_canvas.gd")
const Photo = preload("res://scripts/workshop_photo.gd")
const Rig = preload("res://scripts/fighter_rig.gd")
const Library = preload("res://scripts/custom_library.gd")
const KitPreview = preload("res://scripts/custom_kit_preview.gd")
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const PARTS := ["head", "body", "left_arm", "right_arm", "left_leg", "right_leg"]
const PART_NAMES := ["Head", "Body", "Left arm", "Right arm", "Left leg", "Right leg"]
const JOINTS := ["head", "shoulder", "hip", "back_elbow", "back_hand", "front_elbow", "front_hand", "left_knee", "left_foot", "right_knee", "right_foot"]
const STEPS := ["Draw / Import", "Bring to life", "Weapon", "Try it!", "Save & Fight"]
const COLORS := ["#25364b", "#f06e55", "#f6a047", "#69aa71", "#56a5c5", "#9875c7", "#f19bb6", "#fff4cc"]
const COLOR_NAMES := ["Navy", "Coral", "Orange", "Green", "Blue", "Purple", "Pink", "Cream"]
const WIDTHS := [4, 9, 18]
const MIN_CUTOUT_AREA := 64.0
const KITS := ["pixel_pick", "bone", "bat", "ball", "rubber_chicken", "giant_crayon"]
const KIT_NAMES := ["Pixel Pickaxe", "Dinosaur Bone", "Baseball Bat", "Soccer Ball", "Rubber Chicken", "Jumbo Crayon"]
const KIT_SPECIALS := ["Ore Pop", "Fossil Fetch", "HOME RUN!", "Swerve Shot", "Cluckquake", "Rainbow Ruckus"]
const INK := Color("26384b")
const PAPER := Color("fff9e9")
const CREAM := Color("f4e9cb")
const SKY := Color("dfeef0")
const MINT := Color("b9dfcd")
const ORANGE := Color("f6ad57")
const MUTED := Color("657889")

var host
var record: Dictionary = {}
var step := 0
var source_mode := "draw"
var selected_part := "head"
var selected_joint := "head"
# `selected_color` is the drawing pen; `fighter_color` only recolors the starter body.
var selected_color := Color("#25364b")
var fighter_color := Color("#f6a047")
var pen_width := 9
var eraser_width := 22
var eraser_on := false
var details_on := false
var brush_width := 12
var ghost := true
var pose_name := "Walk"
var dirty := false
var status := "Choose a body part, then draw it on the page."
var _history: Array = []
var _redo: Array = []
var _canvas
var _canvas_frame: Control
var _preview_art: Node2D
var _preview_fx: Node2D
var _preview_uses_rig := false
var _preview_clock := 0.0
var _source_image: Image
var _source_square: Image
var _matte_image: Image
var _photo_path_cache := ""
var _source_path_cache := ""
var _draw_strokes_cache: Array = []
var _dialog: FileDialog
var _name_edit: LineEdit
var _exit_dialog: ConfirmationDialog
var _sensitivity: HSlider
var _sensitivity_label: Label
var _matte_preview: TextureRect
var _paper_edge_check: CheckButton
var _zoom := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if record.is_empty():
		build(null)

func build(owner, existing: Dictionary = {}) -> void:
	host = owner
	var library = get_node_or_null("/root/Doodles")
	record = existing.duplicate(true) if not existing.is_empty() else library.new_record() if library != null else _fallback_record()
	step = 0
	source_mode = "import" if not str(record.get("photo_path","")).is_empty() else "draw"
	var saved_color: String = str(record.get("color", COLORS[2]))
	if not Color.html_is_valid(saved_color): saved_color = COLORS[2]
	fighter_color = Color(saved_color)
	var saved_pen: String = str(record.get("pen_color", saved_color))
	if not Color.html_is_valid(saved_pen): saved_pen = saved_color
	selected_color = Color(saved_pen)
	record["color"] = fighter_color.to_html(false).insert(0,"#")
	record["pen_color"] = selected_color.to_html(false).insert(0,"#")
	_tag_legacy_base_strokes()
	_draw_strokes_cache = record.get("strokes",[]).duplicate(true)
	selected_part = "head"
	_history.clear()
	_redo.clear()
	dirty = false
	_load_existing_photo()
	_build_ui()

func _fallback_record() -> Dictionary:
	return {"id":"custom_%d" % Time.get_ticks_usec(),"name":"My Doodle","color":"#f6ad57","pen_color":"#f6ad57","kit":"pixel_pick","strokes":[],"joints":{"head":[256,105],"shoulder":[256,185],"hip":[256,300],"back_elbow":[185,235],"back_hand":[150,280],"front_elbow":[327,235],"front_hand":[362,280],"left_knee":[215,385],"left_foot":[190,460],"right_knee":[297,385],"right_foot":[322,460]},"photo_path":"","source_path":"","photo_parts":{},"photo_settings":{"rotation":0,"corners":[[32,32],[480,32],[480,480],[32,480]],"sensitivity":0.5,"paper_edge":true,"keep_strokes":[],"erase_strokes":[],"correction_strokes":[]}}

func _load_existing_photo() -> void:
	_source_image = null
	_source_square = null
	_matte_image = null
	var source_path: String = str(record.get("source_path",""))
	_source_path_cache = source_path
	if not source_path.is_empty() and FileAccess.file_exists(source_path):
		var result: Dictionary = Photo.load_source(ProjectSettings.globalize_path(source_path))
		if result.has("image"):
			_source_image = result.image
			_source_square = Photo.square_preview(_source_image,int(record.get("photo_settings",{}).get("rotation",0)))
	var matte_path: String = str(record.get("photo_path",""))
	_photo_path_cache = matte_path
	if not matte_path.is_empty() and FileAccess.file_exists(matte_path):
		_matte_image = Image.new()
		if _matte_image.load(matte_path) != OK: _matte_image = null

func _style(color: Color, border: Color = INK, width: int = 2, radius: int = 15) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8
	box.content_margin_right = 8
	return box

func _panel(at: Vector2, dimensions: Vector2, fill: Color = PAPER) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = dimensions
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_style(fill))
	add_child(panel)
	return panel

func _label(value: String, at: Vector2, dimensions: Vector2, font_size: int = 19, color: Color = INK, centered: bool = false, wrap: bool = false) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = value
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(caption: String, at: Vector2, dimensions: Vector2, action: Callable, primary: bool = false, selected: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = at
	button.size = dimensions
	button.add_theme_font_override("font",FONT)
	button.add_theme_font_size_override("font_size",17)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: button.add_theme_color_override(key,INK)
	var fill := MINT if selected else ORANGE if primary else PAPER
	button.add_theme_stylebox_override("normal",_style(fill))
	button.add_theme_stylebox_override("hover",_style(fill.lightened(0.12),Color("317e8c"),3))
	button.add_theme_stylebox_override("pressed",_style(fill.darkened(0.08)))
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("317e8c"),3))
	button.pressed.connect(action)
	add_child(button)
	return button

func _clear_ui() -> void:
	for child in get_children():
		child.queue_free()
	_canvas = null
	_canvas_frame = null
	_preview_art = null
	_preview_fx = null
	_preview_uses_rig = false
	_dialog = null
	_name_edit = null
	_exit_dialog = null
	_sensitivity = null
	_sensitivity_label = null
	_matte_preview = null
	_paper_edge_check = null

func _build_ui() -> void:
	_clear_ui()
	var background := ColorRect.new()
	background.color = Color("dce7df")
	background.size = Vector2(1280,720)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_panel(Vector2(13,10),Vector2(1254,698),Color("f8f3df"))
	_label("DOODLE WORKSHOP",Vector2(34,22),Vector2(340,30),20,MUTED)
	_label("Make a fighter only you could dream up!",Vector2(32,49),Vector2(970,53),35)
	_button("Back",Vector2(1112,29),Vector2(137,53),_ask_exit)
	for i in STEPS.size():
		var idx := i
		_button("%d  %s" % [i+1,STEPS[i]],Vector2(31+i*247,107),Vector2(235,44),func(): _go_step(idx),false,step == i)
	_panel(Vector2(27,160),Vector2(213,501),Color("e9f0e8"))
	_panel(Vector2(250,160),Vector2(510,501),Color("fffdf5"))
	_panel(Vector2(771,160),Vector2(480,501),Color("e9f0e8"))
	if step in [0,1]:
		_canvas_frame = Control.new()
		_canvas_frame.position = Vector2(259,169)
		_canvas_frame.size = Vector2(492,483)
		_canvas_frame.clip_contents = true
		add_child(_canvas_frame)
		_canvas = CanvasScript.new()
		_canvas.editor = self
		_canvas.position = Vector2.ZERO
		_canvas.size = Vector2(492,483)
		_canvas.pivot_offset = _canvas.size*0.5
		_canvas.scale = Vector2.ONE*_zoom
		_canvas.mode = _canvas_mode()
		_canvas.show_ghost = ghost
		_canvas.texture = _canvas_texture()
		_canvas_frame.add_child(_canvas)
	else:
		_draw_stage_card()
	_match_step()
	_label(status,Vector2(269,662),Vector2(730,40),17,MUTED,false,true)
	_button("< Previous",Vector2(28,670),Vector2(173,38),func(): _go_step(step-1))
	_button("Next >",Vector2(1090,670),Vector2(160,38),func(): _go_step(step+1),true)
	_prepare_dialogs()

func _canvas_texture() -> Texture2D:
	if source_mode != "import": return null
	if _canvas_mode() == "corners" and _source_square != null:
		return ImageTexture.create_from_image(_source_square)
	if _matte_image != null: return ImageTexture.create_from_image(_matte_image)
	if _source_square != null: return ImageTexture.create_from_image(_source_square)
	return null

func _canvas_mode() -> String:
	if step == 0:
		return ("erase_stroke" if eraser_on else "draw") if source_mode == "draw" else str(record.get("photo_settings",{}).get("tool","corners"))
	if step == 1:
		return "joints" if source_mode == "draw" else str(record.get("photo_settings",{}).get("life_tool","polygon"))
	return "view"

func _match_step() -> void:
	if step == 0: _build_draw_step()
	elif step == 1: _build_life_step()
	elif step == 2: _build_weapon_step()
	elif step == 3: _build_try_step()
	else: _build_save_step()

func _go_step(next: int) -> void:
	if next < 0 or next >= STEPS.size(): return
	step = next
	status = ["Choose a body part, then draw it on the page.","Move the dots to make your art bend and bounce.","Every fighter needs a favorite thing!","Watch your fighter move before saving.","Name your doodle and give it a place in the roster."][step]
	if step == 1 and source_mode == "import":
		status = "Trace the whole %s. Photo parts are not detected automatically." % PART_NAMES[PARTS.find(selected_part)]
	_build_ui()

func _build_draw_step() -> void:
	_label("1  MAKE YOUR ART",Vector2(42,174),Vector2(190,34),20)
	_button("Draw",Vector2(39,215),Vector2(90,36),func(): _set_source_mode("draw"),false,source_mode == "draw")
	_button("Import",Vector2(136,215),Vector2(90,36),func(): _set_source_mode("import"),false,source_mode == "import")
	if source_mode == "draw":
		_part_buttons(Vector2(41,255),31)
		_label("Fighter: " + _color_name(fighter_color),Vector2(43,438),Vector2(175,25),16)
		for i in COLORS.size():
			var idx := i
			_palette_chip(idx,Vector2(42+(i%4)*43,464+(i/4)*24),func(): _select_fighter_color(idx),fighter_color.to_html() == Color(COLORS[i]).to_html())
		_label("Pen: " + _color_name(selected_color),Vector2(43,512),Vector2(175,25),16)
		for i in COLORS.size():
			var idx := i
			_palette_chip(idx,Vector2(42+(i%4)*43,538+(i/4)*24),func(): _select_pen_color(idx),selected_color.to_html() == Color(COLORS[i]).to_html())
		_label("Line",Vector2(42,589),Vector2(50,22),16)
		for i in WIDTHS.size():
			var value: int = WIDTHS[i]
			_button(str(i+1),Vector2(87+i*46,585),Vector2(40,34),func(): _set_pen_width(value),false,pen_width == value)
		_button("Guide: " + ("On" if ghost else "Off"),Vector2(42,622),Vector2(175,34),_toggle_ghost)
		_label("Fighter color changes the starter. Pen color changes new lines.",Vector2(785,177),Vector2(442,54),18,MUTED,false,true)
		_button("Undo",Vector2(794,244),Vector2(100,38),_undo)
		_button("Redo",Vector2(904,244),Vector2(100,38),_do_redo)
		_button("Eraser",Vector2(1014,244),Vector2(108,38),_toggle_eraser,false,eraser_on)
		_button("Restore starter",Vector2(795,294),Vector2(180,40),_starter)
		_button("Details",Vector2(985,294),Vector2(126,40),_toggle_details,false,details_on)
		_button("Zoom +",Vector2(793,346),Vector2(100,38),func(): _change_zoom(1))
		_button("Zoom -",Vector2(904,346),Vector2(100,38),func(): _change_zoom(-1))
		_build_preview("Your doodle comes alive",Vector2(1009,636))
	else:
		_build_import_controls()

func _build_import_controls() -> void:
	_button("Choose photo",Vector2(43,267),Vector2(170,46),_choose_photo,true)
	_label("JPEG · PNG · HEIC",Vector2(43,315),Vector2(180,25),16,MUTED)
	_button("Turn ↻",Vector2(43,345),Vector2(170,38),_rotate_photo)
	_sensitivity_label = _label(_cleanup_strength_text(float(record.get("photo_settings",{}).get("sensitivity",0.5))),Vector2(43,388),Vector2(190,25),16)
	_sensitivity = HSlider.new()
	_sensitivity.position = Vector2(44,411)
	_sensitivity.size = Vector2(169,27)
	_sensitivity.min_value = 0.0
	_sensitivity.max_value = 1.0
	_sensitivity.step = 0.05
	_sensitivity.value = float(record.get("photo_settings",{}).get("sensitivity",0.5))
	_sensitivity.value_changed.connect(_on_sensitivity)
	add_child(_sensitivity)
	_paper_edge_check = CheckButton.new()
	_paper_edge_check.position = Vector2(40,440)
	_paper_edge_check.size = Vector2(185,34)
	_paper_edge_check.text = "White edge"
	_paper_edge_check.button_pressed = bool(record.get("photo_settings",{}).get("paper_edge",true))
	_paper_edge_check.add_theme_font_override("font",FONT)
	_paper_edge_check.add_theme_font_size_override("font_size",16)
	_paper_edge_check.add_theme_color_override("font_color",INK)
	_paper_edge_check.toggled.connect(_on_paper_edge_toggled)
	add_child(_paper_edge_check)
	_button("4 paper corners",Vector2(43,480),Vector2(171,36),func(): _set_photo_tool("corners"),false,_canvas_mode() == "corners")
	_button("Keep brush",Vector2(43,521),Vector2(171,36),func(): _set_photo_tool("keep"),false,_canvas_mode() == "keep")
	_button("Erase brush",Vector2(43,562),Vector2(171,36),func(): _set_photo_tool("erase"),false,_canvas_mode() == "erase")
	_label("Set cleanup strength and frame the page with four dots. It removes light, low-color paper. White edge adds the sticker border separately; Keep restores pale marks.",Vector2(789,177),Vector2(440,83),16,MUTED,false,true)
	_button("Undo",Vector2(795,272),Vector2(104,38),_undo)
	_button("Redo",Vector2(909,272),Vector2(104,38),_do_redo)
	_button("Zoom +",Vector2(795,320),Vector2(104,38),func(): _change_zoom(1))
	_button("Zoom -",Vector2(909,320),Vector2(104,38),func(): _change_zoom(-1))
	_label("Checkerboard = clear background",Vector2(789,370),Vector2(436,45),17,MUTED)
	_build_preview("Your drawing becomes a paper cutout, with a little white edge.",Vector2(1009,636))

func _build_life_step() -> void:
	_label("2  BRING TO LIFE",Vector2(41,175),Vector2(190,35),19)
	if source_mode == "import":
		_button("Trace cutouts",Vector2(41,220),Vector2(175,38),func(): _set_life_tool("polygon"),false,_canvas_mode() == "polygon")
		_button("Move joints",Vector2(41,263),Vector2(175,38),func(): _set_life_tool("joints"),false,_canvas_mode() == "joints")
		if _canvas_mode() == "polygon":
			_part_buttons(Vector2(41,310),43)
			_button("Clear this shape",Vector2(41,597),Vector2(175,41),_clear_polygon)
		else:
			_joint_buttons(310,26)
	else:
		_joint_buttons(224,36)
	_button("Undo",Vector2(791,185),Vector2(103,38),_undo)
	_button("Redo",Vector2(901,185),Vector2(103,38),_do_redo)
	if source_mode == "import":
		var progress := _cutout_progress()
		var next_part: String = _next_cutout_name()
		if _canvas_mode() == "polygon":
			_label("Trace around the whole " + PART_NAMES[PARTS.find(selected_part)].to_lower() + " in your photo. Tap around its outside edge to add dots.",Vector2(789,233),Vector2(436,83),18,MUTED,false,true)
			_label("Cutouts ready: %d / 6. Next: %s. Joints only mark bends; switch to Move joints after all six parts are traced." % [progress,next_part],Vector2(789,320),Vector2(430,72),17,INK,false,true)
		else:
			_label("Drag each dot to a bend, like an elbow or knee. The dots move the cutouts; they do not find or trace body parts for you.",Vector2(789,233),Vector2(436,83),18,MUTED,false,true)
			_label("Cutouts ready: %d / 6. %s" % [progress, "All six are ready to preview!" if progress == 6 else "Still needed: " + _next_cutout_name()],Vector2(789,320),Vector2(430,72),17,INK,false,true)
	else:
		_label("Pick a joint, then drag its dot to where your arm or leg bends. Try the elbow first!",Vector2(789,233),Vector2(436,80),18,MUTED,false,true)
	_build_preview("Watch it bend",Vector2(1009,636))

func _build_weapon_step() -> void:
	_label("3  CHOOSE A WEAPON",Vector2(43,182),Vector2(190,40),19)
	_label("Your doodle will hold it in battle.",Vector2(43,232),Vector2(173,84),18,MUTED,false,true)
	_label("Tap one!",Vector2(43,332),Vector2(170,35),20)
	for i in KITS.size():
		var idx := i
		var x := 789 + (i%3)*148
		var y := 218 + (i/3)*112
		_button(KIT_NAMES[i] + "\n" + KIT_SPECIALS[i],Vector2(x,y),Vector2(140,98),func(): _select_kit(idx),true,str(record.get("kit","")) == KITS[i])
	_label("Special move",Vector2(798,452),Vector2(170,34),21)
	var kit_idx: int = maxi(0,KITS.find(str(record.get("kit","pixel_pick"))))
	_label(KIT_SPECIALS[kit_idx],Vector2(798,488),Vector2(395,47),28,Color("ae6031"))
	_build_preview("Your fighter + weapon",Vector2(498,606))

func _build_try_step() -> void:
	_label("4  TRY YOUR MOVES",Vector2(42,182),Vector2(190,40),19)
	_label("Every pose uses your own art.",Vector2(42,233),Vector2(170,80),18,MUTED,false,true)
	for i in ["Walk","Jump","Basic","Special","Victory","Defeat"]:
		var pose: String = i
		var idx: int = ["Walk","Jump","Basic","Special","Victory","Defeat"].find(i)
		_button(i,Vector2(790+(idx%2)*216,235+(idx/2)*63),Vector2(199,54),func(): _select_pose(pose),false,pose_name == pose)
	_label("Move: " + pose_name,Vector2(788,465),Vector2(436,48),28)
	_button("Try in Practice",Vector2(823,531),Vector2(356,60),_save_and_practice,true)
	_build_preview("Your doodle in motion",Vector2(455,606))

func _build_save_step() -> void:
	_label("5  READY TO FIGHT!",Vector2(43,182),Vector2(185,40),19)
	_label("Your fighter stays on this Mac in one of six doodle slots.",Vector2(42,233),Vector2(177,113),18,MUTED,false,true)
	_label("Fighter name",Vector2(790,210),Vector2(190,33),20)
	_name_edit = LineEdit.new()
	_name_edit.position = Vector2(790,250)
	_name_edit.size = Vector2(412,52)
	_name_edit.max_length = 24
	_name_edit.text = str(record.get("name","My Doodle"))
	_name_edit.add_theme_font_override("font",FONT)
	_name_edit.add_theme_font_size_override("font_size",25)
	_name_edit.add_theme_color_override("font_color",INK)
	_name_edit.add_theme_color_override("caret_color",INK)
	_name_edit.add_theme_stylebox_override("normal",_style(Color.WHITE))
	_name_edit.text_changed.connect(func(value): record["name"] = value; dirty = true)
	add_child(_name_edit)
	_button("Save fighter",Vector2(790,323),Vector2(197,57),_save_fighter,true)
	_button("Save & Fight!",Vector2(1004,323),Vector2(198,57),_save_and_fight,true)
	_label("Your drawing, your fighter, your choice.",Vector2(790,400),Vector2(426,52),20,MUTED)
	_build_preview("Finished fighter",Vector2(506,606))

func _draw_stage_card() -> void:
	_label("YOUR FIGHTER",Vector2(284,180),Vector2(380,45),28,INK)
	_label("★",Vector2(665,178),Vector2(72,64),50,Color("e5b85c"),true)
	if step != 3: _label("From your sketchbook to the arena",Vector2(285,615),Vector2(415,34),18,MUTED,true)

func _build_preview(title: String, at: Vector2) -> void:
	if step in [0,1]:
		_label(title,Vector2(789,407),Vector2(421,71),19 if source_mode == "import" else 24,INK,false,source_mode == "import")
	else:
		_label(title,Vector2(283,248),Vector2(420,37),23,INK)
	if source_mode == "import" and not _all_photo_cutouts_ready():
		# Keep the full source on the central canvas for page-corner placement,
		# while this companion preview shows the processed transparency result.
		var preview_image: Image = _matte_image if _matte_image != null else _source_square
		if preview_image != null:
			_matte_preview = TextureRect.new()
			_matte_preview.position = Vector2(931,480) if step in [0,1] else Vector2(415,315)
			_matte_preview.size = Vector2(150,135) if step in [0,1] else Vector2(220,240)
			_matte_preview.texture = ImageTexture.create_from_image(preview_image)
			_matte_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_matte_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_matte_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_matte_preview)
			if step in [0,1]:
				_label("Cleanup preview · %d / 6 cutouts" % _cutout_progress(),Vector2(789,619),Vector2(430,28),16,MUTED,true)
		else:
			_label("Choose a photo to see your whole drawing here.",Vector2(789,500),Vector2(430,42),17,MUTED,true,true)
		return
	var data = get_node_or_null("/root/Data")
	_preview_uses_rig = data != null and data.has_method("custom_definition")
	if _preview_uses_rig:
		_preview_art = Rig.new()
	else:
		var script = load("res://scripts/custom_art.gd")
		if script == null: return
		_preview_art = script.new()
	_preview_art.position = at
	_preview_art.scale = Vector2.ONE * (0.93 if step in [0,1] else 1.55)
	add_child(_preview_art)
	_configure_preview()
	_preview_fx = KitPreview.new()
	_preview_fx.position = at
	_preview_fx.scale = _preview_art.scale
	add_child(_preview_fx)
	_preview_clock = 0.0
	if _preview_uses_rig:
		_preview_art.preview = false
		_preview_art.pose(0.0,{"grounded":true,"reduced_motion":_reduced_motion()})
	else:
		_preview_art.pose_preview({"grounded":true,"reduced_motion":_reduced_motion()})

func _photo_polygon_issue(value: Variant) -> String:
	if not value is Array or value.size() < 3:
		return "missing"
	if value.size() > 128:
		return "too_many"
	var polygon := PackedVector2Array()
	var min_point := Vector2(512.0,512.0)
	var max_point := Vector2.ZERO
	for raw_point in value:
		if not raw_point is Array or raw_point.size() != 2:
			return "too_small"
		if not (raw_point[0] is int or raw_point[0] is float) or not (raw_point[1] is int or raw_point[1] is float):
			return "too_small"
		var point := Vector2(float(raw_point[0]),float(raw_point[1]))
		if not is_finite(point.x) or not is_finite(point.y) or point.x < 0.0 or point.y < 0.0 or point.x > 512.0 or point.y > 512.0:
			return "too_small"
		polygon.append(point)
		min_point.x = minf(min_point.x,point.x)
		min_point.y = minf(min_point.y,point.y)
		max_point.x = maxf(max_point.x,point.x)
		max_point.y = maxf(max_point.y,point.y)
	var twice_area := 0.0
	for i in polygon.size():
		twice_area += polygon[i].x * polygon[(i+1)%polygon.size()].y - polygon[(i+1)%polygon.size()].x * polygon[i].y
	if absf(twice_area) * 0.5 < MIN_CUTOUT_AREA or max_point.x-min_point.x < 6.0 or max_point.y-min_point.y < 6.0:
		return "too_small"
	if Geometry2D.triangulate_polygon(polygon).is_empty():
		return "too_small"
	return ""

func _cutout_progress() -> int:
	var polygons: Dictionary = record.get("photo_parts",{}) if record.get("photo_parts",{}) is Dictionary else {}
	var count := 0
	for part in PARTS:
		if _photo_polygon_issue(polygons.get(part,null)).is_empty(): count += 1
	return count

func _all_photo_cutouts_ready() -> bool:
	return _cutout_progress() == PARTS.size()

func _next_cutout_name() -> String:
	var polygons: Dictionary = record.get("photo_parts",{}) if record.get("photo_parts",{}) is Dictionary else {}
	for i in PARTS.size():
		if not _photo_polygon_issue(polygons.get(PARTS[i],null)).is_empty():
			return PART_NAMES[i]
	return "All done!"

func _cutout_missing_names() -> Array[String]:
	var missing: Array[String] = []
	var polygons: Dictionary = record.get("photo_parts",{}) if record.get("photo_parts",{}) is Dictionary else {}
	for i in PARTS.size():
		if not _photo_polygon_issue(polygons.get(PARTS[i],null)).is_empty():
			missing.append(PART_NAMES[i])
	return missing

func _first_bad_cutout() -> String:
	var polygons: Dictionary = record.get("photo_parts",{}) if record.get("photo_parts",{}) is Dictionary else {}
	for part in PARTS:
		if _photo_polygon_issue(polygons.get(part,null)) in ["too_small","too_many"]:
			return part
	for part in PARTS:
		if not _photo_polygon_issue(polygons.get(part,null)).is_empty():
			return part
	return ""

func _configure_preview() -> void:
	if not is_instance_valid(_preview_art): return
	if _preview_uses_rig: _preview_art.configure(get_node("/root/Data").call("custom_definition",record))
	else: _preview_art.configure(record)

func _reduced_motion() -> bool:
	var settings = get_node_or_null("/root/Settings")
	return bool(settings.reduced_motion) if settings != null else false

func _process(delta: float) -> void:
	if not is_instance_valid(_preview_art): return
	_preview_clock += delta
	var state := {"grounded":true,"reduced_motion":_reduced_motion(),"facing":1}
	match pose_name:
		"Walk": state["velocity"] = Vector2(85,0)
		"Jump":
			state["grounded"] = false
			state["velocity"] = Vector2(0,-110)
		"Basic": state["attack_progress"] = fposmod(_preview_clock,1.0)
		"Special":
			state["attack_progress"] = fposmod(_preview_clock,1.3)/1.3
			state["special"] = true
			if str(record.get("kit","")) in ["bone","ball"] and float(state["attack_progress"]) > 0.28 and float(state["attack_progress"]) < 0.94:
				state["weapon_hidden"] = true
		"Victory": state["victory"] = true
		"Defeat": state["defeated"] = true
	if _preview_uses_rig: _preview_art.pose(delta,state)
	else: _preview_art.pose_preview(state)
	if is_instance_valid(_preview_fx):
		var hand: Vector2 = _preview_art.front_hand if _preview_uses_rig else Vector2(27,-65)
		_preview_fx.present(str(record.get("kit","pixel_pick")),float(state.get("attack_progress",-1.0)) if pose_name == "Special" else -1.0,hand,_reduced_motion())

func _part_buttons(start: Vector2, gap: int) -> void:
	for i in PARTS.size():
		var part: String = PARTS[i]
		_button(PART_NAMES[i],start+Vector2(0,i*gap),Vector2(176,gap-5),func(): _select_part(part),false,selected_part == part)

func _joint_buttons(start_y: int, gap: int) -> void:
	for i in JOINTS.size():
		var joint: String = JOINTS[i]
		_button(joint.replace("_"," ").capitalize(),Vector2(42,start_y+i*gap),Vector2(173,gap-3),func(): _select_joint(joint),false,selected_joint == joint)

func _select_part(value: String) -> void:
	selected_part = value
	if source_mode == "import" and step == 1 and _canvas_mode() == "polygon":
		status = "Trace around the whole %s in your photo." % PART_NAMES[PARTS.find(selected_part)]
	_build_ui()

func _select_joint(value: String) -> void:
	selected_joint = value
	_build_ui()

func _palette_chip(index: int, at: Vector2, action: Callable, selected: bool) -> void:
	var chip := Button.new()
	chip.position = at
	chip.size = Vector2(37,22)
	chip.tooltip_text = COLOR_NAMES[index]
	chip.add_theme_stylebox_override("normal",_style(Color(COLORS[index]),Color("25364b") if selected else Color("aeb9b6"),3 if selected else 1,5))
	chip.add_theme_stylebox_override("hover",_style(Color(COLORS[index]).lightened(0.16),Color("327e8c"),2,5))
	chip.add_theme_stylebox_override("pressed",_style(Color(COLORS[index]).darkened(0.08),Color("25364b"),2,5))
	chip.pressed.connect(action)
	add_child(chip)

func _color_name(color: Color) -> String:
	var index := COLORS.find("#" + color.to_html(false))
	return COLOR_NAMES[index] if index >= 0 else "Custom"

func _select_fighter_color(index: int) -> void:
	if index < 0 or index >= COLORS.size(): return
	var ink: String = COLORS[index]
	if fighter_color.to_html() == Color(ink).to_html(): return
	_snapshot()
	fighter_color = Color(COLORS[index])
	record["color"] = ink
	for stroke in record.get("strokes", []):
		if stroke is Dictionary and bool(stroke.get("base_figure", false)):
			stroke["color"] = ink
	status = "Base fighter color changed. Pick Pen color separately for new marks."
	_changed()
	_build_ui()

func _select_pen_color(index: int) -> void:
	if index < 0 or index >= COLORS.size(): return
	var ink: String = COLORS[index]
	if selected_color.to_html() == Color(ink).to_html(): return
	_snapshot()
	selected_color = Color(COLORS[index])
	record["pen_color"] = ink
	status = "Pen color changed. Your fighter color stays the same."
	_changed()
	_build_ui()

func _selected_color_hex() -> String:
	return "#" + selected_color.to_html(false)

func _fighter_color_hex() -> String:
	return "#" + fighter_color.to_html(false)

func _set_pen_width(width: int) -> void:
	pen_width = width
	eraser_width = width*2+5
	_build_ui()

func _toggle_eraser() -> void:
	eraser_on = not eraser_on
	status = "Drag over ink to erase it." if eraser_on else "Draw on %s." % selected_part.replace("_"," ")
	_build_ui()

func _toggle_details() -> void:
	details_on = not details_on
	eraser_on = false
	status = "Details will stick to %s when it moves." % selected_part.replace("_"," ") if details_on else "Draw the big shapes of your fighter."
	_build_ui()

func _toggle_ghost() -> void:
	ghost = not ghost
	_build_ui()

func _set_source_mode(value: String) -> void:
	if value == source_mode: return
	_snapshot()
	if value == "draw":
		_photo_path_cache = str(record.get("photo_path",""))
		_source_path_cache = str(record.get("source_path",""))
		record["photo_path"] = ""
		record["source_path"] = ""
		record["strokes"] = _draw_strokes_cache.duplicate(true)
	else:
		_draw_strokes_cache = record.get("strokes",[]).duplicate(true)
		record["photo_path"] = _photo_path_cache
		record["source_path"] = _source_path_cache
		record["strokes"] = []
	source_mode = value
	_changed()
	if value == "import" and _source_image == null: status = "Choose a photo of your drawing on white paper."
	_build_ui()

func _set_photo_tool(value: String) -> void:
	record["photo_settings"]["tool"] = value
	status = "Drag the paper corners." if value == "corners" else "Paint over marks to keep them." if value == "keep" else "Paint over marks to erase them."
	_build_ui()

func _set_life_tool(value: String) -> void:
	record["photo_settings"]["life_tool"] = value
	if value == "polygon":
		status = "Trace around the whole %s; the preview waits for all six cutouts." % PART_NAMES[PARTS.find(selected_part)]
	else:
		status = "Move the bend dots only after all six cutouts are traced."
	_build_ui()

func _on_paper_edge_toggled(enabled: bool) -> void:
	_snapshot()
	var settings: Dictionary = record.get("photo_settings", {}) if record.get("photo_settings", {}) is Dictionary else {}
	settings["paper_edge"] = enabled
	record["photo_settings"] = settings
	status = "White paper edge on." if enabled else "White paper edge off."
	_changed()

func _clear_polygon() -> void:
	_snapshot()
	record["photo_parts"][selected_part] = []
	status = "Cleared the %s outline. Trace around the whole part." % PART_NAMES[PARTS.find(selected_part)]
	_changed()
	_build_ui()

func _on_sensitivity(value: float) -> void:
	record["photo_settings"]["sensitivity"] = value
	if is_instance_valid(_sensitivity_label):
		_sensitivity_label.text = _cleanup_strength_text(value)
	_changed(true)

func _cleanup_strength_text(value: float) -> String:
	return "Page cleanup: %d%%" % int(round(clampf(value,0.0,1.0)*100.0))

func _select_kit(index: int) -> void:
	_snapshot()
	record["kit"] = KITS[index]
	_changed()
	_build_ui()

func _select_pose(value: String) -> void:
	pose_name = value
	_preview_clock = 0.0
	_build_ui()

func _change_zoom(direction: int) -> void:
	_zoom = clampf(_zoom + float(direction)*0.25,0.75,2.0)
	if _canvas != null:
		_canvas.pivot_offset = _canvas.size*0.5
		_canvas.scale = Vector2.ONE*_zoom
	status = "Zoom: %d%%" % int(round(_zoom*100))

func _snapshot() -> void:
	_history.append(record.duplicate(true))
	if _history.size() > 40: _history.pop_front()
	_redo.clear()

func _undo() -> void:
	if _history.is_empty(): return
	_redo.append(record.duplicate(true))
	record = _history.pop_back()
	fighter_color = Color(str(record.get("color", COLORS[2])))
	selected_color = Color(str(record.get("pen_color", record.get("color", COLORS[2]))))
	_changed(source_mode == "import")
	_build_ui()

func _do_redo() -> void:
	if _redo.is_empty(): return
	_history.append(record.duplicate(true))
	record = _redo.pop_back()
	fighter_color = Color(str(record.get("color", COLORS[2])))
	selected_color = Color(str(record.get("pen_color", record.get("color", COLORS[2]))))
	_changed(source_mode == "import")
	_build_ui()

func _starter() -> void:
	_snapshot()
	record["strokes"] = Library.starter_strokes()
	record["joints"] = Library.default_joints()
	record["color"] = _fighter_color_hex()
	for stroke in record["strokes"]:
		stroke["color"] = record["color"]
	status = "Starter restored. Undo brings back your last drawing."
	_changed()
	_build_ui()

func _tag_legacy_base_strokes() -> void:
	var strokes: Variant = record.get("strokes", [])
	if not strokes is Array: return
	for stroke in strokes:
		if not stroke is Dictionary or bool(stroke.get("base_figure", false)) or bool(stroke.get("detail", false)):
			continue
		if str(stroke.get("color", "")).to_lower() != "#f6a047": continue
		for template in Library.starter_strokes():
			if str(stroke.get("part", "")) != str(template.part): continue
			if not is_equal_approx(float(stroke.get("width", 0)), float(template.width)): continue
			if not _same_stroke_points(stroke.get("points", []), template.points): continue
			stroke["base_figure"] = true
			# Older drafts stored the chosen accent color but left the starter ink
			# orange. Keep those two values in sync when opening the draft.
			stroke["color"] = _fighter_color_hex()
			break
	record["strokes"] = strokes

func _same_stroke_points(first: Variant, second: Variant) -> bool:
	if not first is Array or not second is Array or first.size() != second.size(): return false
	for i in first.size():
		if not first[i] is Array or not second[i] is Array or first[i].size() != 2 or second[i].size() != 2:
			return false
		var a := Vector2(float(first[i][0]), float(first[i][1]))
		var b := Vector2(float(second[i][0]), float(second[i][1]))
		if a.distance_to(b) > 0.5: return false
	return true

func _changed(reprocess_photo: bool = false) -> void:
	dirty = true
	if reprocess_photo and _source_square != null:
		var path: String = Photo.save_matte(record,_source_square)
		if not path.is_empty():
			record["photo_path"] = path
			record["photo_settings"]["matte_path"] = path
			_photo_path_cache = path
			_matte_image = Image.new()
			_matte_image.load(path)
			if is_instance_valid(_matte_preview):
				_matte_preview.texture = ImageTexture.create_from_image(_matte_image)
	if is_instance_valid(_canvas):
		_canvas.texture = _canvas_texture()
		_canvas.queue_redraw()
	_configure_preview()

func _choose_photo() -> void:
	if _dialog != null: _dialog.popup_centered(Vector2i(900,640))

func _prepare_dialogs() -> void:
	_dialog = FileDialog.new()
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.use_native_dialog = true
	_dialog.add_filter("*.jpg,*.jpeg,*.png,*.heic,*.heif", "Photo files")
	_dialog.file_selected.connect(_photo_selected)
	add_child(_dialog)
	_exit_dialog = ConfirmationDialog.new()
	_exit_dialog.title = "Leave the workshop?"
	_exit_dialog.dialog_text = "Your unsaved changes will be lost."
	_exit_dialog.confirmed.connect(func(): cancelled.emit())
	add_child(_exit_dialog)

func _photo_selected(path: String) -> void:
	var result: Dictionary = Photo.load_source(path)
	if result.has("error"):
		status = str(result.error)
		_build_ui()
		return
	_snapshot()
	_source_image = result.image
	_source_square = Photo.square_preview(_source_image,0)
	record["source_path"] = path
	_source_path_cache = path
	record["strokes"] = []
	record["photo_parts"] = {}
	var previous_settings: Dictionary = record.get("photo_settings",{}) if record.get("photo_settings",{}) is Dictionary else {}
	var paper_edge: bool = bool(previous_settings.get("paper_edge",true))
	record["photo_settings"] = {"rotation":0,"corners":[[32,32],[480,32],[480,480],[32,480]],"sensitivity":0.50,"paper_edge":paper_edge,"keep_strokes":[],"erase_strokes":[],"correction_strokes":[],"tool":"corners","life_tool":"polygon"}
	_changed(true)
	status = "Photo loaded. Drag the four corner dots to frame the paper."
	_build_ui()

func _rotate_photo() -> void:
	if _source_image == null:
		status = "Choose a photo first."
		_build_ui()
		return
	_snapshot()
	var turns: int = posmod(int(record["photo_settings"].get("rotation",0))+1,4)
	record["photo_settings"]["rotation"] = turns
	_source_square = Photo.square_preview(_source_image,turns)
	_changed(true)
	_build_ui()

func _ask_exit() -> void:
	if dirty: _exit_dialog.popup_centered()
	else: cancelled.emit()

func _persist() -> String:
	if _name_edit != null: record["name"] = _name_edit.text.strip_edges()
	if str(record.get("name","")).is_empty():
		_show_save_issue("Give your doodle a name", "Type a name for your fighter, then tap Save fighter or Save & Fight!.")
		return ""
	if source_mode == "draw" and record.get("strokes",[]).is_empty():
		_show_save_issue("Add some doodle art", "Draw your fighter or tap Restore starter before saving.")
		return ""
	if source_mode == "import" and str(record.get("photo_path","")).is_empty():
		step = 0
		_show_save_issue("Choose your drawing", "Go to Draw / Import and choose a photo before saving.")
		return ""
	if source_mode == "import":
		var missing := _cutout_missing_names()
		if not missing.is_empty():
			var first_bad := _first_bad_cutout()
			selected_part = first_bad if not first_bad.is_empty() else PARTS[PART_NAMES.find(missing[0])]
			step = 1
			var photo_settings: Dictionary = record.get("photo_settings", {}) if record.get("photo_settings", {}) is Dictionary else {}
			photo_settings["life_tool"] = "polygon"
			record["photo_settings"] = photo_settings
			var names: String = ", ".join(missing)
			var current_parts: Dictionary = record.get("photo_parts",{}) if record.get("photo_parts",{}) is Dictionary else {}
			var issue := _photo_polygon_issue(current_parts.get(selected_part,[]))
			status = "Cutouts ready: %d / 6. Fix %s first. Still needed: %s." % [_cutout_progress(),PART_NAMES[PARTS.find(selected_part)],names]
			var instructions := "The Move joints tool only moves bend dots. It does not find body parts. We've switched to Trace cutouts and picked %s. Trace the missing parts with dots along their outside edges. Still needed: %s." % [missing[0],names]
			if issue == "too_small":
				instructions = "The %s cutout is too tiny or too narrow to move. Clear this shape, then tap around the whole colored part in your photo. Still needed: %s." % [missing[0],names]
			elif issue == "too_many":
				instructions = "The %s has too many dots. Clear this shape, then trace around the whole part with a few dots along its edge. Still needed: %s." % [missing[0],names]
			_show_save_issue("Let's finish the paper cutouts!",instructions)
			return ""
	var library = get_node_or_null("/root/Doodles")
	if library == null:
		_show_save_issue("Can't open your sketchbook", "The fighter library is unavailable right now. Please try again.")
		return ""
	var id: String = library.save_record(record)
	if id.is_empty():
		_show_save_issue("Your doodle couldn't save", str(library.last_error))
		return ""
	record = library.get_record(id)
	dirty = false
	status = "Saved! Find %s in your fighter roster." % str(record.get("name","Your doodle"))
	return id

func _show_save_issue(title: String, message: String) -> void:
	status = title
	_build_ui()
	var overlay := Control.new()
	overlay.name = "SaveIssueOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(INK.r, INK.g, INK.b, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var card := Panel.new()
	card.position = Vector2(320, 215)
	card.size = Vector2(640, 290)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _style(PAPER, INK, 3, 20))
	overlay.add_child(card)
	var heading := Label.new()
	heading.position = Vector2(345, 235)
	heading.size = Vector2(590, 42)
	heading.text = title
	heading.add_theme_font_override("font", FONT)
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", INK)
	overlay.add_child(heading)
	var explanation := Label.new()
	explanation.position = Vector2(345, 283)
	explanation.size = Vector2(590, 145)
	explanation.text = message
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	explanation.add_theme_font_override("font", FONT)
	explanation.add_theme_font_size_override("font_size", 19)
	explanation.add_theme_color_override("font_color", INK)
	overlay.add_child(explanation)
	var dismiss := Button.new()
	dismiss.position = Vector2(535, 439)
	dismiss.size = Vector2(210, 49)
	dismiss.text = "Got it!"
	dismiss.add_theme_font_override("font", FONT)
	dismiss.add_theme_font_size_override("font_size", 20)
	dismiss.add_theme_color_override("font_color", INK)
	dismiss.add_theme_stylebox_override("normal", _style(MINT))
	dismiss.add_theme_stylebox_override("hover", _style(MINT.lightened(0.12), Color("317e8c"), 3))
	dismiss.add_theme_stylebox_override("pressed", _style(MINT.darkened(0.08)))
	dismiss.pressed.connect(overlay.queue_free)
	overlay.add_child(dismiss)

func _save_fighter() -> void:
	var id := _persist()
	if id.is_empty(): return
	status = "Saved! Your fighter is in My Doodles. Save & Fight! when you're ready."
	_build_ui()

func _save_and_fight() -> void:
	var id := _persist()
	if not id.is_empty(): saved.emit(id)

func _save_and_practice() -> void:
	var id := _persist()
	if not id.is_empty(): practice_requested.emit(id)
