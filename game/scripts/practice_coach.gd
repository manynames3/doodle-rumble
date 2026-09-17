extends Control
## A short, optional practice sequence. Feedback follows genuine gameplay events.
var host
var step := 0
var label: Label
var previous_success := false
var success_time := 0.0
func build(owner_node) -> void:
	host = owner_node
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(347,126)
	size = Vector2(586,109)
	host._panel(self,Rect2(Vector2.ZERO,size),Color("101629ee"),Color("dfc98e"))
	label = host._text(self,"",Rect2(17,9,551,93),22,Color("fff0cb"),true,true)

func _process(delta: float) -> void:
	if not is_instance_valid(host) or not is_instance_valid(label): return
	var controls = [Settings.binding_label("p1_move_left")+" / "+Settings.binding_label("p1_move_right"),Settings.binding_label("p1_jump"),Settings.binding_label("p1_attack"),Settings.binding_label("p1_special"),Settings.binding_label("p1_dodge")]
	if Settings.device_label(0).begins_with("Controller"): controls = ["Stick / D-pad","South","West","East","LB"]
	var prompts = ["1 / 6  MAKE AN ENTRANCE\nMove with "+controls[0],"2 / 6  CATCH SOME AIR\nJump with "+controls[1],"3 / 6  YOUR FIRST BONK\nHit the dummy with "+controls[2],"4 / 6  MAKE A BIG IMPRESSION\nUse your special: "+controls[3],"5 / 6  AN AIRBORNE IDEA\nJump, then attack before you land","6 / 6  YOUR TURN TO COUNTER\nWatch the dummy, then dodge with "+controls[4]]
	var successes = [host.practice_moved,host.practice_jumped,host.practice_hits>0,host.practice_special,host.match_stats.get("air",false),host.match_stats.get("counter",false)]
	if step>=6:
		label.text = "YOU'VE GOT THE BASICS!\nTry a special after a counter. Your doodle, your style."
		return
	if successes[step]:
		success_time += delta
		label.text = "NICE DOODLING!  ✓"
		if not previous_success: Sound.play("menu_select")
		previous_success = true
		if success_time > 0.8:
			step += 1
			success_time = 0
			previous_success = false
	else: label.text = prompts[step]
