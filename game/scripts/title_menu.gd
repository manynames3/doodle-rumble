extends Control
## A narrow painted footer leaves the poster's cast and descriptions unobscured.
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const TitleMotion = preload("res://scripts/title_motion.gd")
var hint: Label
var buttons: Array[Button] = []
var motion: Control

func build(entries: Array) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280,720)
	var widths = [206,220,184,221,174,119]
	var x = 78.0
	# First child: the underline and doodles stay beneath the hint and button labels, as the old underline did.
	motion = TitleMotion.new()
	add_child(motion)
	hint = Label.new()
	hint.position = Vector2(80,634)
	hint.size = Vector2(1120,25)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font",FONT)
	hint.add_theme_font_size_override("font_size",16)
	hint.add_theme_color_override("font_color",Color("dbcbea"))
	hint.add_theme_color_override("font_outline_color",Color("080811"))
	hint.add_theme_constant_override("outline_size",5)
	add_child(hint)
	for i in range(entries.size()):
		var entry = entries[i]
		var b = Button.new()
		b.text = entry[0]
		b.position = Vector2(x,662)
		b.size = Vector2(widths[i],48)
		b.add_theme_font_override("font",FONT)
		b.add_theme_font_size_override("font_size",25)
		for style in ["normal","hover","pressed","focus"]:
			b.add_theme_stylebox_override(style,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
			b.add_theme_color_override(state,Color("fff0d7") if state == "font_color" else Color("ffb539"))
		b.add_theme_color_override("font_outline_color",Color("070810"))
		b.add_theme_constant_override("outline_size",7)
		b.focus_entered.connect(func(): hint.text = entry[2]; motion.set_focus(b))
		b.focus_exited.connect(func(): motion.clear_focus(b))
		b.mouse_entered.connect(func(): b.grab_focus())
		b.pressed.connect(func(): Sound.play("ui"); entry[1].call())
		add_child(b)
		buttons.append(b)
		x += widths[i]
	for i in range(buttons.size()):
		buttons[i].focus_neighbor_left = buttons[i].get_path_to(buttons[posmod(i-1,buttons.size())])
		buttons[i].focus_neighbor_right = buttons[i].get_path_to(buttons[(i+1)%buttons.size()])
	buttons[0].grab_focus()

func _draw() -> void:
	# Feather the bottom into the painted foreground, without a window or border.
	for i in range(28):
		draw_rect(Rect2(0,632+i*3.2,1280,3.4),Color(0.012,0.015,0.033,float(i)/28.0*0.88))
	# The focus underline and caret are drawn by the title_motion overlay so they can play with the doodles.
