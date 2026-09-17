extends SceneTree
## Isolated rally persistence/editor tests. Never touches the player's save.
const RallyLibrary = preload("res://scripts/rally_library.gd")
const RallyEditor = preload("res://scripts/rally_editor.gd")
var checks := 0
var failures: Array[String] = []
var test_path := "user://qa_rally_library_%d.json" % Time.get_ticks_usec()

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		push_error("FAIL: " + description)

func run() -> void:
	await process_frame
	var library := RallyLibrary.new()
	library.save_path = test_path
	library.load_data()
	check(library.courses.size() == 3, "three presets ship in the library")
	for built_in in library.courses:
		check(RallyLibrary.validate_course(built_in).is_empty(), "preset %s is playable" % built_in.id)
		check(RallyLibrary.build_curve(built_in).get_baked_length() > 650.0, "preset %s has a useful lap" % built_in.id)
	var custom: Dictionary = library.make_course("My Twisty Test", "desk", library.courses[0].points, [{"kind":"boost", "u":0.2, "lane":22.0}])
	var saved: Dictionary = library.save_course(custom)
	check(not saved.is_empty() and library.courses.size() == 4, "custom course saves")
	check(FileAccess.file_exists(test_path), "save is committed")
	var found := RallyLibrary.new()
	found.save_path = test_path
	found.load_data()
	check(found.courses.size() == 4 and found.get_course(saved.id).title == "My Twisty Test", "custom course survives reload")
	check(found.get_course(saved.id).stamps.size() == 1, "course stamps survive reload")
	var first: Dictionary = found.record_result(saved.id, 33.4, 6, 2, "solo_gentle_0")
	var worse: Dictionary = found.record_result(saved.id, 38.0, 3, 3, "solo_gentle_0")
	var other: Dictionary = found.record_result(saved.id, 35.0, 4, 1, "solo_skillful_0")
	check(bool(first.get("new_best", false)) and not bool(worse.get("new_best", true)) and bool(other.get("new_best", false)), "best times are separate by race setup")
	check(is_equal_approx(float(found.records[saved.id + "|solo_gentle_0"].best_time), 33.4), "slower race cannot replace a best time")
	check(found.stickers.has("star") and found.stickers.has("lightning"), "finishes unlock earned decoration")
	found.selected_sticker = "lightning"
	found.save_data()
	var reloaded := RallyLibrary.new()
	reloaded.save_path = test_path
	reloaded.load_data()
	check(reloaded.selected_sticker == "lightning" and reloaded.coins == found.coins, "rewards and selection persist")
	var editor := RallyEditor.new()
	root.add_child(editor)
	await process_frame
	editor.configure(reloaded, reloaded.get_course(saved.id))
	check(editor.editor_points.size() == saved.points.size(), "editor reopens saved dots")
	if OS.has_environment("RALLY_EDITOR_SCREENSHOT"):
		await process_frame
		await RenderingServer.frame_post_draw
		editor.get_viewport().get_texture().get_image().save_png(OS.get_environment("RALLY_EDITOR_SCREENSHOT"))
	editor._name.text = "Revised Loop"
	var signals := {"saved":false, "race":false}
	editor.saved.connect(func(_course: Dictionary): signals.saved = true)
	editor._save()
	check(signals.saved and reloaded.get_course(saved.id).title == "Revised Loop", "editor saves revisions to same course")
	editor.race_requested.connect(func(_course: Dictionary): signals.race = true)
	editor._save_and_race()
	check(signals.race, "editor save-and-race sends a playable course")
	editor.queue_free()
	await process_frame
	# Corrupt files must fall back to safe presets without affecting fighting data.
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var malformed := RallyLibrary.new()
	malformed.save_path = test_path
	malformed.load_data()
	check(malformed.courses.size() == 3 and malformed.coins == 0, "malformed save recovers to presets")
	file = FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1, "courses":[{"id":"custom_bad", "title":"Bad", "theme":"desk", "points":[[999999,0]]}], "records":{"desk|solo_gentle_0":{"best_time":-9}}, "coins":9999999999, "selected_sticker":"lightning"}))
	file.close()
	malformed.load_data()
	check(malformed.courses.size() == 3 and malformed.records.is_empty(), "invalid course and record rejected")
	check(malformed.coins == 999999 and malformed.selected_sticker == "plain", "malicious values clamped and unearned sticker rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("RALLY_LIBRARY_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
