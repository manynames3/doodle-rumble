extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,caption:String):
	checks+=1
	if not ok:failures.append(caption);push_error(caption)
func run():
	await process_frame
	var settings=root.get_node("Settings")
	var sound=root.get_node("Sound")
	var audio=load("res://scripts/rally_audio.gd").new()
	root.add_child(audio)
	check(audio._loops.size()==3,"Three unique racing music streams are loaded")
	var previous:PackedByteArray=[]
	for theme in ["desk","castle","sky"]:
		var stream:AudioStreamWAV=audio._loops[theme]
		check(stream.get_length()>24 and stream.stereo,"Racing score is a full stereo phrase: "+theme)
		check(previous!=stream.data,"Racing themes have distinct audio data")
		previous=stream.data
		check(stream.loop_end==stream.data.size()/4,"Loop covers exactly the stereo sample frames")
	settings.master_volume=.7
	audio._silent=false
	audio.play_theme("desk")
	audio._voices[0].stream=audio._sounds["star"]
	audio._voices[0].play()
	settings.music_volume=0
	settings.sfx_volume=.8
	audio._apply_mix()
	check(audio._music.stream_paused and not audio._voices[0].stream_paused,"Music mute leaves sound effects available")
	settings.music_volume=.2
	settings.sfx_volume=0
	audio._apply_mix()
	check(not audio._music.stream_paused and audio._voices[0].stream_paused,"SFX mute leaves music available")
	sound._music.play()
	sound.set_external_music_active(true)
	sound.apply_settings()
	check(sound._music.stream_paused,"Fighting music stays suspended while Rally owns music")
	audio.queue_free()
	await process_frame
	var boot=load("res://scenes/boot.tscn").instantiate()
	root.add_child(boot)
	current_scene=boot
	boot.set_process(false)
	boot._process(1.0)
	check(is_equal_approx(boot.picture.modulate.a,1.0) and not boot.transitioning,"Logo remains visible during its short hold")
	check(boot.picture.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Studio logo keeps the supplied proportions")
	var event:=InputEventKey.new();event.keycode=KEY_SPACE;event.pressed=true
	boot._unhandled_input(event)
	check(boot.skipped,"Key press skips the logo")
	boot._process(.01)
	await process_frame
	await process_frame
	check(current_scene!=null and current_scene.get_script().resource_path.ends_with("main.gd"),"Intro transitions to the real game")
	check(current_scene.state=="title" and not sound.external_music_active,"Title controls and title music resume after intro")
	current_scene.test_mode=true
	current_scene.queue_free()
	await process_frame
	sound.shutdown()
	await create_timer(0.15).timeout
	print("BOOT / AUDIO: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
