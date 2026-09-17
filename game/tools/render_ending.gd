extends SceneTree
const Story = preload("res://scripts/ending_storyboard.gd")
var story
var frames = 0
func _initialize(): call_deferred("begin")
func begin():
	root.get_node("Sound").set_external_music_active(true)
	story=Story.new()
	story.manual=true
	root.add_child(story)
	var captions=load("res://scripts/ending_captions.gd").new()
	captions.story=story
	root.add_child(captions)
	process_frame.connect(advance)
func advance():
	story.seek(frames/24.0)
	frames+=1
	if frames>720:
		root.get_node("Sound").shutdown()
		quit()
