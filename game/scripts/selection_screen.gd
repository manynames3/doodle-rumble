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
	host._text(self,def.name.to_upper(),Rect2(57,139,412,48),35,tint)
	host._text(self,def.special_name.to_upper(),Rect2(57,184,412,30),20,Color("fff1d6"))
	host._text(self,"SPECIAL PREVIEW",Rect2(57,481,412,32),16,Color("fff1d6"))
	host._button(self,"Player 1: "+Data.fighter(host.selected[0]).name,Rect2(516,109,350,38),func(): host.selecting_player=0; host.open_selection(host.mode),Color("ffac3b") if host.selecting_player==0 else Color("12172b"))
	if host.mode != "arcade":
		host._button(self,("Player 2: " if host.mode=="local" else "Opponent: ")+Data.fighter(host.selected[1]).name,Rect2(886,109,350,38),func(): host.selecting_player=1; host.open_selection(host.mode),Color("80ccff") if host.selecting_player==1 else Color("12172b"))
	else:
		host._text(self,"CHAPTER %d / 6" % (host.journey_selection_stage()+1),Rect2(886,109,350,38),20,Color("cda5ff"),true)
	var cards: Array[Button] = []
	for i in range(6):
		var fid: String = Data.ORDER[i]
		var data: Dictionary = Data.fighter(fid)
		var button = host._button(self,"",Rect2(515+(i%3)*247,157+(i/3)*186,234,176),func():
			host.selected[host.selecting_player]=fid
			Settings.selected_fighter=host.selected[0]
			Settings.save_settings()
			host.open_selection(host.mode))
		button.tooltip_text = data.description
		var art = load("res://scripts/selection_card.gd").new()
		art.gallery_mode = true
		button.add_child(art)
		art.configure(fid,Color(data.color),fid==id)
		host._text(button,data.name.to_upper(),Rect2(15,134,203,39),25,Color(data.color))
		if fid==id: host._text(button,"P%d" % (host.selecting_player+1),Rect2(183,6,40,30),16,Color("fff1d6"),true)
		cards.append(button)
	for i in range(cards.size()):
		cards[i].focus_neighbor_left = cards[i].get_path_to(cards[maxi(0,i-1)])
		cards[i].focus_neighbor_right = cards[i].get_path_to(cards[mini(5,i+1)])
		cards[i].focus_neighbor_top = cards[i].get_path_to(cards[maxi(0,i-3)])
		cards[i].focus_neighbor_bottom = cards[i].get_path_to(cards[mini(5,i+3)])
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
	if host.mode=="solo": host._button(self,"Practice",Rect2(285,657,149,45),func(): host.open_selection("training"))
	if host.mode=="arcade": host._button(self,"Sketchbook",Rect2(285,657,180,45),host.show_story_hub)
	host._text(self,"STEP 1 / PICK FIGHTERS" if host.mode in ["solo","local"] else "All six fighters. All yours.",Rect2(486,660,360,37),17,Color("b7c2d8"),true)
	var begin = host._button(self,"Choose stage  >" if host.mode in ["solo","local"] else "LET'S RUMBLE  >",Rect2(894,653,347,50),func():
		if host.mode=="arcade": host.continue_journey()
		elif host.mode in ["solo","local"]: host.open_stage_selection()
		else: host.start_match(),Color("ffac3b"),true)
	begin.grab_focus()
