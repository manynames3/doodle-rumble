extends SceneTree
var checks=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func tap_tab() -> void:
	var event=InputEventKey.new()
	event.keycode=KEY_TAB
	event.physical_keycode=KEY_TAB
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
func run():
	await process_frame
	if not OS.get_user_data_dir().contains("QA"):
		push_error("Ending tests require isolated QA preferences")
		quit(1)
		return
	var settings=root.get_node("Settings")
	var old_motion=settings.reduced_motion
	var old_wins=settings.arcade_wins
	var sound=root.get_node("Sound")
	var Player=load("res://scripts/ending_player.gd")
	check(Player.can_instantiate(),"Ending player compiles")
	check(ResourceLoader.exists("res://assets/cinematics/ending.ogv"),"Actual ending movie included")
	var host=Control.new()
	root.add_child(host)
	var background=Button.new()
	background.text="Underlying result"
	host.add_child(background)
	background.grab_focus()
	settings.reduced_motion=true
	var player=Player.new()
	host.add_child(player)
	check(player.is_storybook and player.video==null,"Reduced motion uses still pages")
	check(sound.external_music_active,"Ending owns music while visible")
	check(background.focus_mode==Control.FOCUS_NONE and root.gui_get_focus_owner()==player.skip,"Still pages block background focus and focus Next")
	for i in range(4):
		await tap_tab()
		check(root.gui_get_focus_owner()==player.skip and player.skip.find_next_valid_focus()==player.skip,"Still-page Tab stays on Next "+str(i))
	for i in range(6):
		check(player.page==i and not player.finished,"Storybook page "+str(i))
		var time=player.story.elapsed
		player._process(0.7)
		check(player.story.elapsed==time,"Storybook stays still until next")
		player.next_page()
	check(player.finished,"Last page completes")
	check(not sound.external_music_active,"Finishing restores shared music")
	check(background.focus_mode==Control.FOCUS_ALL and root.gui_get_focus_owner()==background,"Still-page finish restores background focus")
	player.queue_free()
	await process_frame
	settings.reduced_motion=false
	background.grab_focus()
	var stale=Button.new()
	host.add_child(stale)
	player=Player.new()
	host.add_child(player)
	check(not player.is_storybook and player.video!=null,"Normal settings use actual video")
	check(player.video.is_playing(),"Video starts playback")
	check(player.video.volume==0,"Silent QA keeps video muted")
	check(background.focus_mode==Control.FOCUS_NONE and stale.focus_mode==Control.FOCUS_NONE and root.gui_get_focus_owner()==player.skip,"Video blocks every background button")
	stale.queue_free()
	await process_frame
	for i in range(4):
		await tap_tab()
		check(root.gui_get_focus_owner()==player.skip and player.skip.find_next_valid_focus()==player.skip,"Video Tab stays on Skip "+str(i))
	player.finish()
	player.finish()
	check(player.finished and not player.video.is_playing(),"Skip is immediate and idempotent")
	check(background.focus_mode==Control.FOCUS_ALL and root.gui_get_focus_owner()==background,"Video exit restores surviving background focus after a sibling is deleted")
	player.queue_free()
	await process_frame
	settings.reduced_motion=true
	background.grab_focus()
	player=Player.new()
	host.add_child(player)
	check(background.focus_mode==Control.FOCUS_NONE,"Unexpected removal still blocks background while ending is open")
	player.queue_free()
	await process_frame
	check(background.focus_mode==Control.FOCUS_ALL and root.gui_get_focus_owner()==background,"Unexpected removal restores background focus")
	host.queue_free()
	await process_frame
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode=true
	game.set_physics_process(false)
	game.mode="arcade"
	game.arcade_stage=5
	game.selected=["orange","dark_lord"]
	game.start_match()
	game.rules.finished=true
	game.rules.last_winner=0
	game.rules.scores=[2,0]
	game.journey_rewarded=false
	game.test_mode=false
	settings.reduced_motion=true
	game._finish_round()
	await process_frame
	check(game.state=="story" and is_instance_valid(game.story_scene),"Final story victory opens the after-stage comic")
	check(settings.arcade_wins==old_wins+1,"Final reward granted once before playback")
	if is_instance_valid(game.story_scene): game.story_scene.finish()
	await process_frame
	check(game.state=="ending" and is_instance_valid(game.ending_player),"Finishing the comic automatically starts the ending")
	if is_instance_valid(game.ending_player):
		check(root.gui_get_focus_owner()==game.ending_player.skip and game.ending_player.skip.find_next_valid_focus()==game.ending_player.skip,"Comic-to-ending focus stays on Next page")
		var blocked=true
		for button in game.overlay.find_children("*","Button",true,false): blocked=blocked and button.focus_mode==Control.FOCUS_NONE
		check(blocked,"Result buttons behind ending are removed from focus traversal")
	if is_instance_valid(game.ending_player): game.ending_player.finish()
	await process_frame
	check(game.state=="match_over" and not is_instance_valid(game.ending_player),"Ending returns to final results")
	var focused=root.gui_get_focus_owner()
	check(focused is Button and focused.text=="New journey  >","Closing ending restores rebuilt result focus")
	game.play_ending()
	check(game.state=="ending","Results can replay ending")
	if is_instance_valid(game.ending_player): game.ending_player.finish()
	await process_frame
	check(settings.arcade_wins==old_wins+1,"Replay cannot duplicate reward")
	game.queue_free()
	await process_frame
	settings.reduced_motion=old_motion
	settings.arcade_wins=old_wins
	settings.save_settings()
	sound.shutdown()
	print("TEST_RESULT checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
