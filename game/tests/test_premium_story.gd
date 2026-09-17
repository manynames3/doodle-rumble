extends SceneTree
const Chapters = preload("res://scripts/story_chapters.gd")
const Profile = preload("res://scripts/story_progress.gd")
var checks := 0
var failures := 0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	await process_frame
	var path := "user://story_test.cfg"
	var profile = Profile.new()
	profile.active = true
	profile.stage = 4
	profile.fighter = "purple"
	profile.hazards = false
	profile.completed.assign([0,1,2,3])
	profile.challenges.assign([0,2])
	check(profile.save_profile(path),"Story save writes atomically")
	var loaded = Profile.new()
	loaded.load_profile(path)
	check(loaded.active and loaded.stage==4 and loaded.fighter=="purple" and not loaded.hazards,"A recreated profile restores stage, fighter and hazard choice")
	check(loaded.completed==[0,1,2,3] and loaded.challenges==[0,2],"Completed chapters and bonus stickers survive reload")
	var legacy := ConfigFile.new()
	check(legacy.load(path)==OK,"Legacy profile can be read")
	legacy.set_value("book","equipped",2)
	check(legacy.save(path)==OK,"Legacy profile fixture saves")
	loaded.load_profile(path)
	check(loaded.completed==[0,1,2,3] and loaded.challenges==[0,2],"Old badge setting does not disrupt story progress")
	profile.stage = 5
	check(profile.save_profile(path),"Second save retains a backup")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("[broken\n")
	file.close()
	Engine.print_error_messages = false # The deliberately corrupt ConfigFile reports a parser error.
	loaded.load_profile(path)
	Engine.print_error_messages = true
	check(loaded.stage==4,"Interrupted/corrupt primary save recovers previous checkpoint")
	check(loaded._valid_indices([0,0,7,-1,"2",3])==[0,3],"Malformed chapter entries cannot unlock progress")
	check(loaded.save_profile(path),"Recovered profile saves without obsolete badge setting")
	var cleaned := ConfigFile.new()
	check(cleaned.load(path)==OK and not cleaned.has_section_key("book","equipped"),"Retired badge choice is removed on save")
	profile.free()
	loaded.free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	var chronicle = root.get_node("Chronicle")
	game.new_journey_selection()
	check(game.state=="select" and game.arcade_stage==0,"Fresh story allows fighter choice")
	game.selected[0]="purple"
	game.optional_hazards=false
	game.continue_journey()
	check(game.state=="playing" and chronicle.active and chronicle.fighter=="purple","Starting records the selected fighter")
	check(game.first.definition.id=="purple" and game.second.definition.id=="blue","Story starts with chosen fighter and ordered opponent")
	for stage in range(6):
		var chapter = Chapters.chapter(stage)
		check(chapter.before.size()==3 and chapter.after.size()==3,"Each chapter has a full setup and payoff: "+str(stage))
		check(not Chapters.goal_met(stage,{}),"Bonus stickers require demonstrated play: "+str(stage))
		game.arcade_stage=stage
		var callback_count := [0]
		game._show_story_scene(false,func(): callback_count[0]+=1)
		await process_frame
		check(game.state=="story" and game.story_scene.index==0,"Chapter opens before battle: "+str(stage))
		var scene = game.story_scene
		scene.advance()
		scene.advance()
		check(scene.index==2 and callback_count[0]==0,"Dialogue waits for deliberate advance: "+str(stage))
		scene.finish()
		scene.finish()
		check(callback_count[0]==1,"Skipping/advancing completes only once: "+str(stage))
		game.mode="arcade"
		game.start_match()
		game.match_stats={"air":true,"counter":true,"special_hits":2,"special_serials":[1,2],"healthy":true}
		game.rules.scores=[2,0]
		game.rules.last_winner=0
		game.rules.finished=true
		game._finish_round()
		check(stage in chronicle.completed and stage in chronicle.challenges,"Victory records earned chapter + bonus sticker: "+str(stage))
		if stage<5:
			check(chronicle.active and chronicle.stage==stage+1,"Victory checkpoints the NEXT chapter: "+str(stage))
			game.show_title()
			game.resume_story()
			check(game.arcade_stage==stage+1 and game.selected[0]=="purple" and not game.optional_hazards,"Continue returns to saved stage/choices: "+str(stage))
	check(not chronicle.active and chronicle.runs==1,"Final victory completes the run once")
	var wins: int = root.get_node("Settings").arcade_wins
	game._finish_round()
	check(chronicle.runs==1 and root.get_node("Settings").arcade_wins==wins,"Duplicate final-result delivery never grants another completion")
	game.show_story_hub()
	check(game.state=="journal","Completed journey returns to collection")
	game.mode="training"
	game.selected=["orange","blue"]
	game.start_match()
	check(is_instance_valid(game.coach) and game.coach.step==0,"Practice has a real staged coach")
	game.countdown=0
	game.first.start_attack(false)
	game.first.try_hit(game.second)
	game.second.take_hit(9,1)
	check(game.practice_hits==0 and not game.match_stats.air,"Hazard damage cannot award attack practice or an aerial sticker")
	game.first.attack_serial=22
	game.first.attack_spec={"air_kind":"fork_sweep"}
	game.first.is_special=false
	game.second.invulnerable=0
	game.second.take_hit(10,1,350,-245,game.first)
	check(game.practice_hits==1 and game.match_stats.air,"Real air-hit attribution progresses practice")
	game._on_perfect_dodge(game.first)
	check(game.match_stats.counter,"Actual counter signal progresses challenge")
	root.get_node("Settings").reduced_motion=true
	game._show_story_scene(true,func(): pass,5)
	check(game.story_scene.actors.all(func(actor): return not actor.preview),"Reduced-motion story actors remain still")
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("PREMIUM_STORY checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
