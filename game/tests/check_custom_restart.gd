extends SceneTree
## Run twice using the same --qa-profile and --restart-write on the first launch.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		quit(1)
		return
	var library = root.get_node("Doodles")
	var settings = root.get_node("Settings")
	var story = root.get_node("Chronicle")
	var ok := false
	if "--restart-write" in OS.get_cmdline_user_args():
		var record: Dictionary = library.new_record()
		record.name="The Restart Kid"
		record.kit="bone"
		settings.selected_fighter=library.save_record(record)
		settings.save_settings()
		story.checkpoint(3,settings.selected_fighter,true,2)
		ok=not settings.selected_fighter.is_empty()
	else:
		var records: Array = library.records()
		ok=records.size()==1 and records[0].name=="The Restart Kid" and records[0].kit=="bone"
		ok=ok and settings.selected_fighter==records[0].id and story.fighter==records[0].id
		ok=ok and story.active and story.stage==3 and story.difficulty_level==2
	root.get_node("Sound").shutdown()
	print("CUSTOM_RESTART checks=1 failures=%d" % (0 if ok else 1))
	quit(0 if ok else 1)
