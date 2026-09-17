extends Control
## Three-beat comic exchange with manual advance, skip, and reduced-motion poses.
const Chapters = preload("res://scripts/story_chapters.gd")
var host
var chapter: Dictionary
var lines: Array
var index := 0
var on_done: Callable
var ended := false
var actors: Array = []
var bubble: Control
var next_button: Button
var footer: Label
var chapter_index := 0

func build(owner_node, stage: int, after: bool, done: Callable) -> void:
	host = owner_node
	chapter_index = stage
	chapter = Chapters.chapter(stage)
	lines = chapter.after if after else chapter.before
	on_done = done
	Sound.play("story_open")
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := TextureRect.new()
	bg.texture = load("res://assets/arenas/%s_v2.png" % host.journey_stage_data(stage).arena)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = size
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.025,0.035,0.065,0.38)
	shade.size = size
	add_child(shade)
	host._panel(self,Rect2(30,22,1220,102),Color("090d1de8"),Color(chapter.color))
	host._text(self,"CHAPTER %02d  /  %s" % [stage+1,"ONE MORE FRIEND" if after else "THE SAVE STAR SAGA"],Rect2(58,31,1100,30),18,Color(chapter.color))
	host._text(self,chapter.title,Rect2(58,60,1130,56),34)
	actors.append(host._portrait(self,host.selected[0],Vector2(240,508),1.5))
	actors.append(host._portrait(self,host.journey_stage_data(stage).opponent,Vector2(1040,508),1.5,-1))
	for actor in actors: actor.preview = not Settings.reduced_motion
	host._panel(self,Rect2(34,518,1212,164),Color("0e1329f2"),Color(chapter.color))
	footer = host._text(self,chapter.clue if after else chapter.setup,Rect2(66,536,900,74),23,Color("fff1d6"),false,true)
	next_button = host._button(self,"Next  >",Rect2(993,621,225,48),advance,Color(chapter.color),true,"story_next","story_hover")
	host._button(self,"Skip scene",Rect2(66,624,174,44),finish,Color("10162a"),false,"story_skip","story_hover")
	host._text(self,"A tiny tale. Read at your own pace.",Rect2(267,627,676,36),17,Color("bac1d7"))
	_show_line()
	next_button.grab_focus()

func _show_line() -> void:
	if is_instance_valid(bubble):
		remove_child(bubble)
		bubble.queue_free()
	var line = lines[index]
	var speaker: String = host.selected[0] if line[0] == "hero" else line[0]
	var hero: bool = line[0] == "hero"
	var cue := "story_page" if index == 0 else "story_pencil" if hero else "story_bonk"
	match speaker:
		"pac_man": cue = "story_chomp"
		"h4ck3r": cue = "story_glitch"
		"dark_lord": cue = "story_magic"
		"green": cue = "story_swish"
		"yellow": cue = "story_spark"
	Sound.play(cue)
	bubble = host._panel(self,Rect2(418,161,445,243),Color("fff0d3"),Color("17162c"))
	host._text(bubble,Data.fighter(speaker).name.to_upper()+("  /  YOU" if hero else ""),Rect2(23,16,397,39),23,Color(Data.fighter(speaker).color).darkened(0.56))
	host._text(bubble,line[1],Rect2(23,65,397,164),23,Color("242039"),false,true)
	for n in range(actors.size()):
		actors[n].modulate = Color.WHITE if (n == 0) == hero else Color(0.63,0.64,0.72)
		actors[n].pose(0,{"grounded":true,"facing":1 if n == 0 else -1,"reduced_motion":Settings.reduced_motion,"victory":index == 2 and n == 0})
	next_button.text = "Let's go!  >" if index == lines.size()-1 else "Next  %d / %d  >" % [index+1,lines.size()]
	if not Settings.reduced_motion:
		bubble.modulate.a = 0
		create_tween().tween_property(bubble,"modulate:a",1.0,0.16)

func advance() -> void:
	if ended: return
	index += 1
	if index >= lines.size(): finish()
	else: _show_line()

func finish() -> void:
	if ended: return
	ended = true
	Sound.play("story_close")
	on_done.call()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		finish()
