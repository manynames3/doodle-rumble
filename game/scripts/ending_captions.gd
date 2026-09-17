extends Node2D
const Story = preload("res://scripts/ending_storyboard.gd")
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
var story
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if not is_instance_valid(story): return
	var shot = mini(5,int(story.elapsed/5))
	var lines = Story.CAPTIONS[shot].split("\n")
	draw_colored_polygon(PackedVector2Array([Vector2(90,604),Vector2(1189,608),Vector2(1170,701),Vector2(104,695)]),Color("080c17",0.9))
	for i in range(lines.size()):
		draw_string(FONT,Vector2(105,646+i*34),lines[i],HORIZONTAL_ALIGNMENT_CENTER,1070,27,Color("fff1d6"))
	draw_string(FONT,Vector2(55,50),["THE STAR GETS LOOSE","TEAMWORK, WITH SHELVES","FOLLOW THE LIGHT","CAPES ARE OPTIONAL","THE SAVE STAR COMES HOME","BENJAM GAMES"][shot],HORIZONTAL_ALIGNMENT_LEFT,1170,25,Color("fff1d6"))
