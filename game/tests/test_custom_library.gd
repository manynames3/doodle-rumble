extends SceneTree
## Uses a unique QA folder even when launched outside the game's autoloads.
const Library = preload("res://scripts/custom_library.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)

func run() -> void:
	await process_frame
	var lib := Library.new()
	lib.save_root = "user://doodles_library_test_%d" % Time.get_ticks_usec()
	lib.save_path = lib.save_root.path_join("library.json")
	lib.load_data()
	var first := lib.new_record()
	first.kit = "giant_crayon"
	check(first.id.begins_with("custom_") and first.joints.size() == 11 and first.strokes.size() == 6, "starter has stable ID and full binding")
	var first_id := lib.save_record(first)
	check(first_id == first.id and FileAccess.file_exists(lib.save_path), "first record saved atomically")
	var second := lib.new_record()
	second.name = "Blue Comet"
	second.kit = "rubber_chicken"
	var second_id := lib.save_record(second)
	check(second_id == second.id and FileAccess.file_exists(lib.save_path + ".bak"), "second record and backup saved")
	var duplicate := lib.duplicate_record(first_id)
	check(duplicate.begins_with("custom_") and duplicate != first_id and lib.get_record(duplicate).name.ends_with("Copy"), "clone receives an independent ID")
	var reloaded := Library.new()
	reloaded.save_root = lib.save_root
	reloaded.save_path = lib.save_path
	reloaded.load_data()
	check(reloaded.records().size() == 3 and reloaded.has(first_id) and reloaded.has(second_id), "records survive reload")
	check(reloaded.get_record(first_id).kit == "giant_crayon" and reloaded.get_record(second_id).kit == "rubber_chicken", "both new weapon kits survive a save and reload")
	for i in 3:
		check(not reloaded.save_record(reloaded.new_record()).is_empty(), "six local slots fill")
	check(reloaded.save_record(reloaded.new_record()).is_empty() and not reloaded.last_error.is_empty(), "seventh slot rejected")
	check(reloaded.delete_record(second_id) and not reloaded.has(second_id), "delete persists")
	var after_delete := Library.new()
	after_delete.save_root = lib.save_root
	after_delete.save_path = lib.save_path
	after_delete.load_data()
	check(not after_delete.has(second_id), "healthy primary does not resurrect deleted backup entries")
	var content := FileAccess.get_file_as_string(lib.save_path)
	var parsed: Dictionary = JSON.parse_string(content)
	parsed.records.append({"id":"../bad","name":"Corrupt"})
	var file := FileAccess.open(lib.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(parsed))
	file.close()
	var repaired := Library.new()
	repaired.save_root = lib.save_root
	repaired.save_path = lib.save_path
	repaired.load_data()
	check(repaired.has(first_id) and repaired.has(duplicate) and FileAccess.file_exists(lib.save_path + ".corrupt"), "damaged entry isolated while valid primary records remain")
	file = FileAccess.open(lib.save_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var recovered := Library.new()
	recovered.save_root = lib.save_root
	recovered.save_path = lib.save_path
	recovered.load_data()
	check(recovered.has(first_id) and recovered.records().size() > 0, "malformed JSON restored from last good backup")
	# Photo copies are owned by the library, and clones get their own assets.
	var image := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(190, 50, 130, 140), Color("e5552b"))
	var source := lib.save_root.path_join("test_input.png")
	image.save_png(source)
	var photo := recovered.get_record(first_id)
	photo.photo_path = source
	photo.photo_parts = {"head":[[190,50],[320,50],[320,190],[190,190]]}
	check(recovered.save_record(photo) == first_id, "photo record saves")
	var owned: String = recovered.get_record(first_id).photo_path
	check(owned != source and FileAccess.file_exists(owned), "source image copied under sketchbook ownership")
	var heic_source := lib.save_root.path_join("original.heic")
	file = FileAccess.open(heic_source, FileAccess.WRITE)
	file.store_buffer(PackedByteArray([0, 0, 0, 12, 102, 116, 121, 112, 104, 101, 105, 99]))
	file.close()
	photo = recovered.get_record(first_id)
	photo.source_path = heic_source
	check(recovered.save_record(photo) == first_id, "HEIC original accepted beside processed matte")
	var restored := Library.new()
	restored.save_root = lib.save_root
	restored.save_path = lib.save_path
	restored.load_data()
	var owned_source: String = str(restored.get_record(first_id).get("source_path", ""))
	check(owned_source.ends_with(".heic") and owned_source != heic_source and FileAccess.file_exists(owned_source) and restored.get_record(first_id).photo_path == owned, "owned HEIC source and matte survive reload")
	var long_edit := restored.get_record(first_id)
	var long_points: Array = []
	for index in range(450): long_points.append([200+index%100,300])
	long_edit.strokes.append({"part":"body","color":"#fff2af","width":3,"points":long_points,"detail":true})
	check(restored.save_record(long_edit) == first_id and restored.get_record(first_id).strokes[-1].points.size() == 450, "450-point source stroke saves without truncation")
	var too_long := restored.get_record(first_id)
	var excess: Array = []
	for index in range(4001): excess.append([200+index%100,300])
	too_long.strokes[-1].points = excess
	check(restored.save_record(too_long).is_empty() and restored.get_record(first_id).strokes[-1].points.size() == 450 and not restored.last_error.is_empty(), "oversized edit is rejected without changing saved drawing")
	var invisible := restored.new_record()
	invisible.strokes = []
	invisible.photo_path = lib.save_root.path_join("missing.png")
	invisible.photo_parts = {"head":[[200,60],[300,60],[300,155],[200,155]]}
	check(restored.save_record(invisible).is_empty() and not restored.last_error.is_empty(), "missing photo-only creation cannot be saved invisibly")
	var broken_root := lib.save_root.path_join("missing_photo_case")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(broken_root))
	var broken_path := broken_root.path_join("library.json")
	file = FileAccess.open(broken_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"records":[invisible]}))
	file.close()
	var absent := Library.new()
	absent.save_root = broken_root
	absent.save_path = broken_path
	absent.load_data()
	check(not absent.has(str(invisible.id)), "reload drops photo-only fighter whose image disappeared")
	for instance in [lib, reloaded, after_delete, repaired, recovered, restored, absent]: instance.free()
	print("CUSTOM_LIBRARY_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
