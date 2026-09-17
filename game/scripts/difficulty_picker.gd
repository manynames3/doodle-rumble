extends Control
## Friendly names always include the familiar level so children know the choice.
const LABELS := ["Chill Doodles · Easy", "Spicy Scribbles · Medium", "Doodle Mayhem · Hard"]
const HINTS := ["Take your time. Learn their tricks!", "Enemies attack more often. Watch the floor!", "Busy battles! More attacks and more hazards."]
const COLORS := [Color("90dfb3"),Color("ffc05d"),Color("ff839d")]

func build(host) -> void:
	size = Vector2(983,69)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._text(self,"HOW WILD?",Rect2(0,0,147,24),17,Color("fff1d6"))
	host._text(self,HINTS[host.difficulty_level],Rect2(151,0,831,24),16,Color("c4c9dc"))
	for i in range(3):
		var chosen: bool = host.difficulty_level == i
		var control = host._button(self,LABELS[i],Rect2(i*332,29,320,37),func():
			host.difficulty_level = i
			host.open_selection(host.mode),COLORS[i] if chosen else Color("14192d"))
		control.name = "Difficulty%d" % i
		control.tooltip_text = HINTS[i]
