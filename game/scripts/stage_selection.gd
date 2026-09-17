extends Control
const Catalog = preload("res://scripts/arena_catalog.gd")
const DifficultyPicker = preload("res://scripts/difficulty_picker.gd")
const FLAVOR := {
	"desktop":"Leap between rulers, books and a very springy doodle!",
	"quarry":"Big blocks. Wobbly bridges. Please bring your imagination.",
	"glitch":"Purple portals and a computer having a very silly day.",
	"canopy":"Paper treetops, flying folds and leafy little surprises.",
	"arcade":"Glowing games and pinballs with absolutely no manners.",
	"network":"Follow the bright cables. Mind the falling data!"
}

func build(host) -> void:
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._text(self,"WHERE SHALL WE RUMBLE?",Rect2(36,15,1080,62),42)
	var mode_name: String = "QUICK MATCH" if host.mode == "solo" else "2P BATTLE"
	var matchup: String = Data.fighter(host.selected[0]).name+"  vs  "+Data.fighter(host.selected[1]).name
	host._text(self,mode_name+"  /  "+matchup,Rect2(40,78,785,34),21,Color("d0d5e8"))
	host._button(self,"Back",Rect2(1118,30,124,44),func(): host.open_selection(host.mode))
	var cards: Array[Button] = []
	for i in range(Catalog.ORDER.size()):
		var id: String = Catalog.ORDER[i]
		var chosen: bool = host.arena_kind == id
		var button = host._button(self,"",Rect2(37+(i%3)*407,124+(i/3)*225,390,210),func():
			host.arena_kind = id
			host.open_stage_selection())
		button.name = "Arena_"+id
		button.tooltip_text = Catalog.NAMES[id]+". "+FLAVOR[id]
		# Keep a semantic button label while drawing the larger illustrated card.
		button.text = Catalog.NAMES[id]
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			button.add_theme_color_override(key,Color.TRANSPARENT)
		var picture := TextureRect.new()
		picture.texture = load("res://assets/arenas/%s_v2.png" % id)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.position = Vector2(5,5)
		picture.size = Vector2(380,157)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(picture)
		host._panel(button,Rect2(5,159,380,46),Color("101529f2"),Color("101529"))
		host._text(button,Catalog.NAMES[id],Rect2(17,164,347,37),25,Color("ffcf7e") if chosen else Color("f5eddc"))
		if chosen:
			button.add_theme_stylebox_override("normal",load("res://scripts/ink_style.gd").make(Color("ffb54f"),Color("ffe2a8"),3))
			host._panel(button,Rect2(269,12,106,29),Color("ffb54f"),Color("ffdca4"))
			host._text(button,"PICKED!",Rect2(269,11,106,29),17,Color("151427"),true)
		cards.append(button)
	for i in range(cards.size()):
		cards[i].focus_neighbor_left = cards[i].get_path_to(cards[maxi(0,i-1)])
		cards[i].focus_neighbor_right = cards[i].get_path_to(cards[mini(5,i+1)])
		cards[i].focus_neighbor_top = cards[i].get_path_to(cards[maxi(0,i-3)])
		if i < 3: cards[i].focus_neighbor_bottom = cards[i].get_path_to(cards[i+3])
	host._text(self,FLAVOR[host.arena_kind],Rect2(41,566,939,34),19,Color("f3e9d8"))
	var note: String = DifficultyPicker.LABELS[host.difficulty_level]+"  /  60-second rounds" if host.mode=="solo" else "Two players. One keyboard or controllers. 60-second rounds."
	host._text(self,note,Rect2(41,604,976,30),17,Color("b7c2d8"))
	var toggle := CheckButton.new()
	toggle.text = "Hazards"
	toggle.position = Vector2(1038,585)
	toggle.size = Vector2(201,44)
	toggle.button_pressed = host.optional_hazards
	toggle.add_theme_font_size_override("font_size",19)
	toggle.add_theme_color_override("font_color",Color("fff1d6"))
	toggle.toggled.connect(func(value): host.optional_hazards=value)
	add_child(toggle)
	host._button(self,"Controls & sound",Rect2(36,657,233,45),host.open_settings)
	host._button(self,"Change fighters",Rect2(287,657,226,45),func(): host.open_selection(host.mode))
	host._text(self,"STEP 2 / PICK A STAGE",Rect2(529,660,341,37),17,Color("b7c2d8"),true)
	var begin = host._button(self,"LET'S RUMBLE  >",Rect2(894,653,347,50),host.start_match,Color("ffac3b"),true)
	begin.grab_focus()
