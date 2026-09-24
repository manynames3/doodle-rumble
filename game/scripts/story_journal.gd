extends Control
const Chapters = preload("res://scripts/story_chapters.gd")
const Catalog = preload("res://scripts/arena_catalog.gd")
var host
func build(owner_node) -> void:
	host = owner_node
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._panel(self,Rect2(30,22,1220,670),Color("101529f2"),Color("c6ad77"))
	host._text(self,"THE SAVE STAR SAGA",Rect2(60,35,1080,66),42,Color("fff0cc"))
	host._text(self,"Six suspicious friends. One missing star. A very unsupervised desktop.",Rect2(64,100,1080,35),20,Color("ccd0df"))
	host._button(self,"Back",Rect2(1125,41,95,42),host.show_title)
	for i in range(6):
		var chapter = Chapters.chapter(i)
		var unlocked: bool = i in Chronicle.completed
		var at := Vector2(60+(i%3)*392,153+(i/3)*191)
		var card = host._panel(self,Rect2(at,Vector2(374,176)),Color("1b2035"),Color(chapter.color) if unlocked else Color("4b4e69"))
		var texture := TextureRect.new()
		texture.texture = load("res://assets/arenas/%s_v2.png" % host.journey_stage_data(i).arena)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture.position = Vector2(4,4)
		texture.size = Vector2(366,65)
		texture.modulate = Color(0.6,0.6,0.65) if unlocked else Color(0.28,0.29,0.36)
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(texture)
		host._text(card,"%02d  %s" % [i+1,chapter.short.to_upper()],Rect2(14,12,345,48),23,Color("fff2cd"))
		host._text(card,"CHAPTER CLEARED" if unlocked else "A NEW FRIEND WAITS HERE",Rect2(14,73,345,30),18,Color(chapter.color) if unlocked else Color("a7abc0"))
		host._text(card,"★ BONUS STICKER" if i in Chronicle.challenges else chapter.challenge,Rect2(14,104,345,27),16,Color("dfd2b5"))
		if unlocked:
			host._button(card,"Replay tale",Rect2(13,135,345,32),func(): host.replay_chapter(i))
	var preview = host._panel(self,Rect2(64,542,640,57),Color("161b30ee"),Color("c6ad77"))
	host._text(preview,"YOUR JOURNEY",Rect2(12,4,616,24),16,Color("fff0cc"))
	host._text(preview,"Replay a tale or continue where you left off.",Rect2(12,30,616,22),16,Color("cbd0df"))
	var note: String = "%d / 6 CHAPTERS CLEARED   ·   %d / 6 BONUS STICKERS" % [Chronicle.completed.size(),Chronicle.challenges.size()]
	if not Chronicle.save_error.is_empty(): note = Chronicle.save_error
	elif Chronicle.missing_fighter: note = "Doodle missing? Pick another and keep your chapters."
	host._text(self,note,Rect2(736,544,471,30),18,Color("d6c7aa"),true)
	var primary: Button
	if Chronicle.active:
		primary = host._button(self,"Continue Story  >",Rect2(736,615,471,54),host.resume_story,Color("ffac3b"),true)
		host._text(self,"SAVED: CHAPTER %d  /  %s" % [Chronicle.stage+1,Data.fighter(Chronicle.fighter).name],Rect2(736,580,471,33),17,Color("d6c7aa"),true)
		host._button(self,"New journey",Rect2(64,617,240,50),host.new_journey_selection)
	else:
		primary = host._button(self,"New journey  >",Rect2(736,615,471,54),host.new_journey_selection,Color("ffac3b"),true)
	host._text(self,"Bring the Save Star home!",Rect2(328,622,385,30),17,Color("b7bdd2"),false,true)
	primary.grab_focus()
