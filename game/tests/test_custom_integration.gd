extends SceneTree
## Exercise the actual menu -> editor -> battle path with an isolated sketchbook.
var checks := 0
var failures := 0
var game
var library
var registry

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func workshop():
	for node in game.ui.get_children():
		if node.has_signal("practice_requested"): return node
	return null

func run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("QA"):
		push_error("Custom integration tests require an isolated profile")
		quit(1)
		return
	library = root.get_node("Doodles")
	registry = root.get_node("Data")
	var chronicle = root.get_node("Chronicle")
	var settings = root.get_node("Settings")
	settings.reduced_motion = true
	var ids: Array[String] = []
	for kit in ["pixel_pick","bone","bat","ball","rubber_chicken","giant_crayon"]:
		var record: Dictionary = library.new_record()
		record.name = "QA " + kit
		record.kit = kit
		var id: String = library.save_record(record)
		check(not id.is_empty(),"A drawn fighter saves: " + kit)
		ids.append(id)
	check(registry.playable_ids().size()==12 and registry.ORDER.size()==6,"Six workshop kits extend selection without altering the six originals")
	check(not registry.is_playable("dark_lord") and not registry.is_playable("h4ck3r"),"Boss roles stay intact")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.selected = [ids[0],ids[0]]
	game.selection_tab = "custom"
	game.open_selection("local")
	check(game.state=="select" and game.selected[1]==ids[0],"Both players can choose the same creation")
	game.open_stage_selection()
	check(game.state=="stage_select","Custom local selection still opens stage choice")
	game.start_match()
	check(game.first.definition.id==ids[0] and game.second.definition.id==ids[0],"Match constructs both selected custom fighters")
	check(game.first.rig.custom_art!=game.second.rig.custom_art,"Each player has an independent animated renderer")
	game.second.take_hit(14,1)
	check(game.first.health==100 and game.second.health==86,"Shared drawing never shares combat health")
	game.first.update_art(1.0/60.0)
	check(game.first.rig.weapon.z_index>game.first.rig.custom_art.z_index,"Weapon is above the paper hand")
	check(game.first.start_dodge(1.0,game.second),"Custom fighter supports the standard dodge")
	game.mode="solo"
	game.start_match()
	check(game.second.definition.id==ids[0] and game.ai!=null,"Custom opponent remains selected for the computer")
	game.arena_kind="quarry"
	game.selected=[ids[3],ids[0]]
	game.start_match()
	game._on_release(game.first,"swerve_shot")
	var ball = game.projectiles[0]
	check(ball.platforms.size()==game.platform_bodies.size(),"Ball initially sees the real arena platforms")
	game.interactions.bridge_gone=2.0
	ball.set_platforms(game._projectile_platforms())
	ball.position=Vector2(600,480)
	ball.velocity=Vector2(0,150)
	ball._bounce_from_stage(Vector2(600,440),Vector2(600,480))
	check(ball.velocity.y>0 and ball.bounce_count==0,"Ball falls through the collapsed Quarry bridge")
	game.interactions.bridge_gone=0
	ball.set_platforms(game._projectile_platforms())
	ball._bounce_from_stage(Vector2(600,440),Vector2(600,480))
	check(ball.velocity.y<0 and ball.bounce_count==1,"Reformed bridge supports the bouncing ball again")
	game.selecting_player=1
	game.open_workshop(ids[1])
	await process_frame
	var editor = workshop()
	check(editor!=null and editor.record.id==ids[1],"Edit opens the existing source drawing")
	editor.dirty=true
	game.quit_game()
	check(not game.quitting and editor.has_node("ConfirmQuitDraft"),"Window close protects unfinished drawing edits")
	editor.get_node("ConfirmQuitDraft").hide()
	editor._save_and_practice()
	check(game.state=="playing" and game.mode=="training" and game.first.definition.id==ids[1],"Try in Practice saves once and enters an actual match")
	game.return_to_workshop()
	await process_frame
	check(game.state=="workshop" and game.mode=="solo" and game.selecting_player==1,"Returning restores the initiating mode and player slot")
	editor = workshop()
	editor.record.name = "My edited hero"
	editor._save_and_fight()
	check(game.state=="stage_select" and game.selected[1]==ids[1],"Save & Fight sets P2 and opens the stage page once")
	check(library.get_record(ids[1]).name=="My edited hero","Editing keeps the stable fighter ID")
	game.selected[0]=ids[2]
	settings.selected_fighter=ids[2]
	settings.save_settings()
	library.load_data()
	settings._load_settings()
	check(settings.selected_fighter==ids[2] and registry.is_playable(ids[2]),"Saved selection resolves after reloading the custom library")
	game.new_journey_selection()
	game.selected[0]=ids[2]
	game.continue_journey()
	for stage in range(6):
		game.arcade_stage=stage
		game.start_match()
		check(game.first.definition.id==ids[2],"Custom hero survives story chapter %d" % stage)
		game.rules.scores=[2,0]
		game.rules.last_winner=0
		game.rules.finished=true
		game._finish_round()
		check(stage in chronicle.completed,"Custom victory awards story chapter %d" % stage)
		if stage<5:
			game.show_title()
			game.resume_story()
			check(game.selected[0]==ids[2] and game.arcade_stage==stage+1,"Story resumes the same hero and next chapter")
	check(not chronicle.active and chronicle.runs==1,"Custom hero can complete the whole saved journey")
	game.play_ending()
	await process_frame
	var film = game.ending_player
	check(film.custom_hero==ids[2],"The final film carries the selected custom hero")
	film.finish()
	check(film.cameo_shown and not film.finished,"After the ending, the original drawing gets its own celebration")
	film.finish()
	await process_frame
	check(game.state=="match_over","Personal celebration returns to the results")
	chronicle.checkpoint(4,ids[2],true,2)
	check(library.delete_record(ids[2]),"The hero can be deleted without editing story data")
	chronicle.load_profile()
	check(chronicle.active and chronicle.stage==4 and chronicle.missing_fighter,"Missing drawing preserves chapter progress and offers a replacement")
	check(chronicle.fighter=="orange" and chronicle.completed.size()==6,"Recovery retains earned chapters")
	game.queue_free()
	await process_frame
	await process_frame
	root.get_node("Sound").shutdown()
	print("CUSTOM_INTEGRATION_TEST_RESULT checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
