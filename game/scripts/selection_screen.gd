extends Control
const Catalog = preload("res://scripts/arena_catalog.gd")
const Chapters = preload("res://scripts/story_chapters.gd")
const Showcase = preload("res://scripts/fighter_showcase.gd")
var host
func build(owner_node) -> void:
	host = owner_node
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._text(self,"PICK YOUR DOODLE",Rect2(35,16,940,60),43)
	var captions = {"solo":"QUICK MATCH", "arcade":"STORY MODE", "local":"2P BATTLE", "training":"PRACTICE PLAYGROUND"}
	host._text(self,captions[host.mode]+"  /  BIG IDEAS. LITTLE TROUBLEMAKERS.",Rect2(39,76,1000,29),17,Color("b7c2d8"))
	host._button(self,"Back",Rect2(1118,29,124,44),host.show_title)
	var id: String = host.selected[host.selecting_player]
	var def: Dictionary = Data.fighter(id)
	var tint := Color(def.color)
	# A live visual demonstration occupies its own uncluttered illustrated page.
	var stage: String = host.journey_stage_data(host.journey_selection_stage()).arena if host.mode == "arcade" else host.arena_kind
	var picture := TextureRect.new()
	picture.texture = load("res://assets/arenas/%s_v2.png" % stage)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.position = Vector2(36,131)
	picture.size = Vector2(455,390)
	picture.modulate = Color(0.55,0.57,0.65)
	add_child(picture)
	var demo = Showcase.new()
	demo.position = Vector2(36,131)
	demo.size = Vector2(455,390)
	add_child(demo)
	demo.configure(id)
	var title = host._text(self,def.name.to_upper(),Rect2(57,139,412,48),35,tint)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	host._text(self,def.special_name.to_upper(),Rect2(57,184,412,30),20,Color("fff1d6"))
	if Doodles.has(id):
		_build_edit_actions(id)
	else:
		host._text(self,"SPECIAL PREVIEW",Rect2(57,481,412,32),16,Color("fff1d6"))
	host._button(self,"Player 1: "+Data.fighter(host.selected[0]).name,Rect2(516,109,350,38),func(): host.selecting_player=0; host.open_selection(host.mode),Color("ffac3b") if host.selecting_player==0 else Color("12172b"))
	if host.mode != "arcade":
		host._button(self,("Player 2: " if host.mode=="local" else "Opponent: ")+Data.fighter(host.selected[1]).name,Rect2(886,109,350,38),func(): host.selecting_player=1; host.open_selection(host.mode),Color("80ccff") if host.selecting_player==1 else Color("12172b"))
	else:
		host._text(self,"CHAPTER %d / 6" % (host.journey_selection_stage()+1),Rect2(886,109,350,38),20,Color("cda5ff"),true)
	host._button(self,"Original Fighters",Rect2(515,153,350,32),func(): host.selection_tab="original"; host.open_selection(host.mode),Color("343251") if host.selection_tab=="original" else Color("12172b"))
	host._button(self,"My Doodles  /  %d of 6" % Doodles.records().size(),Rect2(887,153,350,32),func(): host.selection_tab="custom"; host.open_selection(host.mode),Color("345047") if host.selection_tab=="custom" else Color("12172b"))
	_build_cards(id)
	host._text(self,def.description,Rect2(40,527,1197,36),18,Color("f3e9d8"))
	if host.mode in ["solo","arcade"]:
		var difficulty = load("res://scripts/difficulty_picker.gd").new()
		difficulty.position = Vector2(37,568)
		add_child(difficulty)
		difficulty.build(host)
	else:
		host._text(self,"Your fighters are ready! Next, pick a place to play." if host.mode=="local" else "Try your moves. Your practice buddy always gets back up.",Rect2(41,571,1188,56),22,Color("dfd2b5"))
	if host.mode == "arcade":
		var toggle := CheckButton.new()
		toggle.text = "Hazards"
		toggle.position = Vector2(1042,582)
		toggle.size = Vector2(201,44)
		toggle.button_pressed = host.optional_hazards
		toggle.add_theme_font_size_override("font_size",18)
		toggle.add_theme_color_override("font_color",Color("fff1d6"))
		toggle.toggled.connect(func(value): host.optional_hazards=value)
		add_child(toggle)
	host._button(self,"Controls & sound",Rect2(36,657,233,45),host.open_settings)
	if host.mode == "arcade" and Chronicle.missing_fighter:
		host._text(self,"Your saved doodle is missing. Pick any fighter to keep your story going.",Rect2(40,628,1190,24),15,Color("ffe2a0"))
	if host.mode=="solo": host._button(self,"Practice",Rect2(285,657,149,45),func(): host.open_selection("training"))
	if host.mode=="arcade": host._button(self,"Sketchbook",Rect2(285,657,180,45),host.show_story_hub)
	host._text(self,"STEP 1 / PICK FIGHTERS" if host.mode in ["solo","local"] else "Your drawings can fight, too.",Rect2(486,660,360,37),17,Color("b7c2d8"),true)
	var begin = host._button(self,"Choose stage  >" if host.mode in ["solo","local"] else "LET'S RUMBLE  >",Rect2(894,653,347,50),func():
		if host.mode=="arcade": host.continue_journey()
		elif host.mode in ["solo","local"]: host.open_stage_selection()
		else: host.start_match(),Color("ffac3b"),true)
	begin.grab_focus()

func _select(id: String) -> void:
	host.selected[host.selecting_player] = id
	Settings.selected_fighter = host.selected[0]
	Settings.save_settings()
	host.open_selection(host.mode)

func _build_cards(selected_id: String) -> void:
	var cards: Array[Button] = []
	var records: Array = Doodles.records()
	for i in range(6):
		var rect := Rect2(515+(i%3)*247,194+(i/3)*166,234,156)
		if host.selection_tab == "custom" and i >= records.size():
			var create = host._button(self,"+\nDraw a fighter",rect,func(): host.open_workshop(),Color("16272c"))
			cards.append(create)
			continue
		var fid: String = str(records[i].id) if host.selection_tab == "custom" else str(Data.ORDER[i])
		var data: Dictionary = Data.fighter(fid)
		var button = host._button(self,"",rect,func(): _select(fid))
		button.tooltip_text = data.description
		if host.selection_tab == "custom":
			var art = load("res://scripts/custom_thumbnail.gd").new()
			button.add_child(art)
			art.configure(Doodles.get_record(fid),fid==selected_id)
		else:
			var art = load("res://scripts/selection_card.gd").new()
			art.gallery_mode = true
			button.add_child(art)
			art.configure(fid,Color(data.color),fid==selected_id)
		var label = host._text(button,data.name.to_upper(),Rect2(15,120,203,34),23,Color(data.color))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if fid==selected_id: host._text(button,"P%d" % (host.selecting_player+1),Rect2(183,6,40,30),16,Color("fff1d6"),true)
		cards.append(button)
	for i in range(cards.size()):
		cards[i].focus_neighbor_left = cards[i].get_path_to(cards[maxi(0,i-1)])
		cards[i].focus_neighbor_right = cards[i].get_path_to(cards[mini(5,i+1)])
		cards[i].focus_neighbor_top = cards[i].get_path_to(cards[maxi(0,i-3)])
		cards[i].focus_neighbor_bottom = cards[i].get_path_to(cards[mini(5,i+3)])

func _build_edit_actions(id: String) -> void:
	host._button(self,"Edit",Rect2(51,483,131,30),func(): host.open_workshop(id))
	var copy = host._button(self,"Make a Copy",Rect2(191,483,139,30),func():
		var copied: String = Doodles.duplicate_record(id)
		if copied.is_empty(): _show_error(Doodles.last_error)
		else: _select(copied))
	copy.disabled = Doodles.records().size() >= 6
	host._button(self,"Delete",Rect2(339,483,131,30),func():
		var dialog := ConfirmationDialog.new()
		dialog.title = "Delete this doodle?"
		dialog.dialog_text = "Remove %s from My Doodles? Your story chapters stay saved." % Data.fighter(id).name
		dialog.ok_button_text = "Delete doodle"
		add_child(dialog)
		dialog.confirmed.connect(func():
			if not Doodles.delete_record(id):
				_show_error(Doodles.last_error)
				return
			for slot in range(2):
				if host.selected[slot] == id: host.selected[slot] = "orange" if slot == 0 else "blue"
			Settings.selected_fighter = host.selected[0]
			Settings.save_settings()
			if Chronicle.fighter == id:
				Chronicle.fighter = "orange"
				Chronicle.save_profile()
				Chronicle.missing_fighter = true
			host.open_selection(host.mode))
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered(Vector2i(460,170)))

func _show_error(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Let's try that again"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(460,170))
