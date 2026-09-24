extends SceneTree

const Workshop = preload("res://scripts/doodle_workshop.gd")
const Photo = preload("res://scripts/workshop_photo.gd")
const Library = preload("res://scripts/custom_library.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_check")

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("Workshop: ",message)

func _button_named(parent: Node, caption: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == caption:
			return child
	return null

func _check() -> void:
	var workshop := Workshop.new()
	root.add_child(workshop)
	workshop.build(null)
	var initial_strokes: int = workshop.record.get("strokes",[]).size()
	_expect(workshop.record.get("joints",{}).size() == 11,"starter record has missing joints")
	_expect("#" + workshop.fighter_color.to_html(false) == workshop.record.color and "#" + workshop.selected_color.to_html(false) == workshop.record.pen_color,"base fighter and pen colors load independently")
	var chip_counts: Dictionary = {}
	for child in workshop.get_children():
		if child is Button and child.tooltip_text in ["Navy","Coral","Orange","Green","Blue","Purple","Pink","Cream"]:
			chip_counts[child.tooltip_text] = int(chip_counts.get(child.tooltip_text,0))+1
	var both_palettes := true
	for color_name in ["Navy","Coral","Orange","Green","Blue","Purple","Pink","Cream"]:
		both_palettes = both_palettes and int(chip_counts.get(color_name,0)) >= 2
	_expect(both_palettes,"draw screen has separate full fighter-color and pen-color palettes")
	workshop._starter()
	_expect(workshop.record.get("strokes",[]).size() == 6,"starter has six body parts")
	workshop._select_fighter_color(3)
	var green_base := true
	for stroke in workshop.record.strokes:
		green_base = green_base and bool(stroke.get("base_figure",false)) and stroke.color == "#69aa71"
	_expect(green_base and workshop.record.color == "#69aa71" and workshop.record.pen_color == "#f6a047","fighter palette recolors the base without changing the pen")
	workshop._undo()
	var undo_base := true
	for stroke in workshop.record.strokes:
		undo_base = undo_base and stroke.color == "#f6a047"
	_expect(undo_base and workshop.fighter_color.to_html(false) == Color("#f6a047").to_html(false) and workshop.selected_color.to_html(false) == Color("#f6a047").to_html(false),"undo restores both independent palette selections")
	workshop._do_redo()
	_expect(workshop.record.strokes[0].color == "#69aa71" and workshop.fighter_color.to_html(false) == Color("#69aa71").to_html(false) and workshop.selected_color.to_html(false) == Color("#f6a047").to_html(false),"redo restores fighter color without changing pen color")
	workshop._undo()
	_expect(workshop.record.get("strokes",[]).size() == initial_strokes,"undo restores prior strokes")
	workshop._do_redo()
	_expect(workshop.record.get("strokes",[]).size() == 6,"redo restores starter")
	workshop._toggle_details()
	workshop.selected_part = "head"
	workshop._select_pen_color(4)
	workshop._canvas._start_at(Vector2(90,190))
	workshop._canvas._move_to(Vector2(120,190))
	workshop._canvas._finish()
	var detail: Dictionary = workshop.record.strokes[-1]
	_expect(detail.part == "head" and detail.get("detail",false),"detail attaches to selected part")
	workshop._select_fighter_color(5)
	_expect(detail.color == "#56a5c5" and workshop.record.strokes[0].color == "#9875c7" and workshop.record.pen_color == "#56a5c5","pen color colors new details while fighter color only changes base marks")
	workshop._toggle_eraser()
	workshop._canvas._start_at(Vector2(105,190))
	workshop._canvas._finish()
	_expect(workshop.record.strokes.size() == 6,"drag eraser removes touched ink")
	_expect(workshop._preview_uses_rig,"live preview uses the gameplay fighter rig")
	for kit_index in 6:
		workshop._select_kit(kit_index)
		workshop._select_pose("Special")
		workshop._preview_clock = 0.65
		workshop._process(0.0)
		var kit: String = ["pixel_pick","bone","bat","ball","rubber_chicken","giant_crayon"][kit_index]
		_expect(workshop.record.kit == kit and workshop._preview_fx.kit == kit and workshop._preview_fx.active,"special preview uses chosen kit: " + kit)
		if kit in ["bone","ball"]:
			_expect(not workshop._preview_art.weapon.visible,"thrown weapon leaves hand during flight: " + kit)
	var paper := Image.create_empty(512,512,false,Image.FORMAT_RGBA8)
	paper.fill(Color.WHITE)
	for y in range(100,400):
		for x in range(180,330): paper.set_pixel(x,y,Color("#3282b5"))
	var settings := {"corners":[[0,0],[511,0],[511,511],[0,511]],"sensitivity":0.5,"keep_strokes":[],"erase_strokes":[]}
	var matte: Image = Photo.make_matte(paper,settings)
	_expect(matte.get_pixel(10,10).a < 0.1 and matte.get_pixel(250,250).a > 0.9,"paper removal keeps blue drawing")
	var shaded_page := Image.create_empty(512,512,false,Image.FORMAT_RGBA8)
	shaded_page.fill(Color("#bdb5a8"))
	for y in range(100,400):
		for x in range(180,330): shaded_page.set_pixel(x,y,Color("#d4c600"))
	var shaded_settings := {"corners":[[0,0],[511,0],[511,511],[0,511]],"sensitivity":0.5,"keep_strokes":[],"erase_strokes":[]}
	var shaded_matte: Image = Photo.make_matte(shaded_page,shaded_settings)
	_expect(shaded_matte.get_pixel(10,10).a < 0.05 and shaded_matte.get_pixel(250,250).a > 0.95,"default cleanup removes warm-gray paper while preserving saturated yellow marker")
	shaded_settings.sensitivity = 0.0
	var gentle_matte: Image = Photo.make_matte(shaded_page,shaded_settings)
	_expect(gentle_matte.get_pixel(10,10).a > 0.95,"lower cleanup strength retains the shaded paper")
	var brush_order_settings := {"corners":[[0,0],[511,0],[511,511],[0,511]],"sensitivity":0.5,"correction_strokes":[{"mode":"erase","width":9,"points":[[40,40]]},{"mode":"keep","width":9,"points":[[40,40]]}]}
	var restored_paper: Image = Photo.make_matte(shaded_page,brush_order_settings)
	_expect(restored_paper.get_pixel(40,40).a > 0.95,"Keep restores a pale pixel after a later correction")
	brush_order_settings.correction_strokes.reverse()
	var erased_again: Image = Photo.make_matte(shaded_page,brush_order_settings)
	_expect(erased_again.get_pixel(40,40).a < 0.05,"Erase removes a pixel when it is the latest correction")
	var cleanup_workshop := Workshop.new()
	root.add_child(cleanup_workshop)
	cleanup_workshop.build(null)
	cleanup_workshop.source_mode = "import"
	cleanup_workshop._source_square = shaded_page
	cleanup_workshop.record.photo_settings.sensitivity = 0.0
	cleanup_workshop._build_ui()
	cleanup_workshop._on_sensitivity(0.5)
	_expect(cleanup_workshop._matte_image != null and cleanup_workshop._matte_image.get_pixel(10,10).a < 0.05 and cleanup_workshop._matte_image.get_pixel(250,250).a > 0.95,"cleanup slider reprocesses the page and retains marker color")
	_expect(cleanup_workshop._matte_preview != null and cleanup_workshop._matte_preview.texture != null and cleanup_workshop._matte_preview.texture.get_image().get_pixel(10,10).a < 0.05 and cleanup_workshop._matte_preview.texture.get_image().get_pixel(250,250).a > 0.95,"visible cleanup preview refreshes to the transparent page and preserved marker")
	_expect(cleanup_workshop._sensitivity_label != null and cleanup_workshop._sensitivity_label.text == "Page cleanup: 50%","page cleanup slider reports its current strength")
	cleanup_workshop.free()
	settings.keep_strokes = [{"width":7,"points":[[10,10]]}]
	settings.erase_strokes = [{"width":7,"points":[[250,250]]}]
	var touched: Image = Photo.make_matte(paper,settings)
	_expect(touched.get_pixel(10,10).a > 0.9 and touched.get_pixel(250,250).a < 0.1,"Keep and Erase brushes change alpha")
	var temp: String = Photo.draft_dir()
	var sample := Image.create_empty(100,200,false,Image.FORMAT_RGB8)
	sample.fill(Color("#f2273e"))
	var png: String = temp.path_join("sample.png")
	var jpg: String = temp.path_join("sample.jpg")
	var heic: String = temp.path_join("sample.heic")
	_expect(sample.save_png(png) == OK and sample.save_jpg(jpg) == OK,"sample PNG and JPEG created")
	var output: Array = []
	var heic_code: int = OS.execute("sips",["-s","format","heic",png,"--out",heic],output,true)
	_expect(heic_code == 0 and FileAccess.file_exists(heic),"native sips created HEIC sample")
	for path in [png,jpg,heic]:
		var before: String = FileAccess.get_sha256(path)
		var imported: Dictionary = Photo.load_source(path)
		_expect(imported.has("image") and imported.image.get_width() == 100 and imported.image.get_height() == 200,"photo loads: " + path.get_extension())
		_expect(FileAccess.get_sha256(path) == before,"source remains untouched: " + path.get_extension())
	var exif_path: String = temp.path_join("orientation6.jpg")
	var jpeg: PackedByteArray = FileAccess.get_file_as_bytes(jpg)
	var exif := PackedByteArray([255,225,0,34,69,120,105,102,0,0,73,73,42,0,8,0,0,0,1,0,18,1,3,0,1,0,0,0,6,0,0,0,0,0,0,0])
	var oriented := PackedByteArray([255,216])
	oriented.append_array(exif)
	oriented.append_array(jpeg.slice(2))
	var file := FileAccess.open(exif_path,FileAccess.WRITE)
	file.store_buffer(oriented)
	file.close()
	var exif_image: Dictionary = Photo.load_source(exif_path)
	_expect(Photo._jpeg_orientation(exif_path) == 6 and exif_image.has("image") and exif_image.image.get_size() == Vector2i(200,100),"EXIF orientation turns JPEG upright")
	var library := Library.new()
	root.add_child(library)
	library.save_root = temp.path_join("saved")
	library.save_path = library.save_root.path_join("library.json")
	library.load_data()
	var saved_record: Dictionary = workshop.record.duplicate(true)
	saved_record.source_path = png
	saved_record.photo_path = temp.path_join("sample_matte.png")
	matte.save_png(saved_record.photo_path)
	var id: String = library.save_record(saved_record)
	if id.is_empty(): printerr("First library save: ",library.last_error)
	var retrieved: Dictionary = library.get_record(id)
	_expect(not id.is_empty() and FileAccess.file_exists(str(retrieved.get("source_path",""))) and FileAccess.file_exists(str(retrieved.get("photo_path",""))),"library owns untouched source and separate matte")
	var saved_base_parts := 0
	for stroke in retrieved.get("strokes",[]):
		if bool(stroke.get("base_figure",false)) and stroke.get("color","") == retrieved.get("color",""):
			saved_base_parts += 1
	_expect(saved_base_parts == 6 and retrieved.pen_color == "#56a5c5","library preserves base color, pen color, and recolorable starter-part markers")
	_expect(FileAccess.get_sha256(png) == FileAccess.get_sha256(str(retrieved.get("source_path",""))),"owned source matches original bytes")
	var legacy_record: Dictionary = workshop.record.duplicate(true)
	legacy_record.strokes = Library.starter_strokes()
	legacy_record.color = "#69aa71"
	legacy_record.erase("pen_color")
	for stroke in legacy_record.strokes:
		stroke.erase("base_figure")
		stroke.color = "#f6a047"
	var legacy_workshop := Workshop.new()
	root.add_child(legacy_workshop)
	legacy_workshop.build(null,legacy_record)
	var legacy_recolored := true
	for stroke in legacy_workshop.record.strokes:
		legacy_recolored = legacy_recolored and bool(stroke.get("base_figure",false)) and stroke.color == "#69aa71"
	_expect(legacy_recolored and legacy_workshop.selected_color.to_html(false) == Color("#69aa71").to_html(false),"older saves without a pen color keep their former palette behavior")
	legacy_workshop.free()
	var imported_record: Dictionary = library.new_record()
	imported_record.strokes = []
	imported_record.source_path = heic
	imported_record.photo_path = temp.path_join("heic_matte.png")
	touched.save_png(imported_record.photo_path)
	imported_record.photo_parts = {"body":[[170,90],[338,90],[338,400],[170,400]]}
	imported_record.photo_settings = {"rotation":1,"corners":[[14,15],[490,16],[480,483],[18,480]],"sensitivity":0.8,"keep_strokes":settings.keep_strokes,"erase_strokes":settings.erase_strokes,"matte_path":imported_record.photo_path}
	var heic_id: String = library.save_record(imported_record)
	if heic_id.is_empty(): printerr("HEIC library save: ",library.last_error)
	library.load_data()
	var roundtrip: Dictionary = library.get_record(heic_id)
	_expect(not heic_id.is_empty() and str(roundtrip.get("source_path","")).get_extension().to_lower() == "heic","HEIC source survives save and reload")
	_expect(FileAccess.get_sha256(heic) == FileAccess.get_sha256(str(roundtrip.get("source_path",""))),"HEIC source bytes remain untouched")
	_expect(FileAccess.get_sha256(str(roundtrip.get("photo_path",""))) == FileAccess.get_sha256(imported_record.photo_path),"cleanup matte survives save and reload")
	_expect(float(roundtrip.get("photo_settings",{}).get("sensitivity",-1.0)) == 0.8 and roundtrip.get("photo_settings",{}).get("keep_strokes",[]).size() == 1 and roundtrip.get("photo_parts",{}).has("body"),"editable cleanup settings and cutout survive reload")
	var reopened := Workshop.new()
	root.add_child(reopened)
	reopened.build(null,roundtrip)
	_expect(reopened.source_mode == "import" and reopened._source_square != null and reopened._matte_image != null,"imported editor reopens with owned source and matte")
	_expect(float(reopened.record.photo_settings.get("sensitivity",-1.0)) == 0.8 and reopened.record.photo_settings.get("corners",[]).size() == 4,"reopened editor retains cleanup controls")
	reopened._go_step(1)
	_expect(reopened.status.contains("Trace the whole Head") and not reopened.status.contains("Move the dots"),"photo import footer explains tracing instead of repeating the joint instruction")
	_expect(reopened._cutout_progress() == 1 and not reopened._preview_uses_rig,"a partial photo cutout keeps the whole photo preview instead of showing a misleading sliver")
	reopened.record.photo_parts = {"body":[[230,110],[235,110],[235,300],[230,300]]}
	_expect(reopened._cutout_progress() == 0 and reopened._first_bad_cutout() == "body","a narrow outline is rejected and selected for repair before unrelated missing parts")
	reopened.record.photo_parts = {
		"head":[[180,35],[320,35],[320,165],[180,165]],
		"body":[[200,150],[310,150],[310,310],[200,310]],
		"left_arm":[[120,150],[215,150],[215,255],[120,255]],
		"right_arm":[[295,150],[390,150],[390,255],[295,255]],
		"left_leg":[[185,285],[245,285],[245,465],[185,465]],
		"right_leg":[[265,285],[325,285],[325,465],[265,465]]
	}
	reopened._build_ui()
	_expect(reopened._cutout_progress() == 6 and reopened._preview_uses_rig,"all six complete photo shapes switch the preview to the animated rig")
	workshop.source_mode = "import"
	workshop.record.photo_path = imported_record.photo_path
	workshop.record.photo_parts = {}
	workshop.step = 4
	workshop._build_ui()
	var blocked_save := _button_named(workshop,"Save & Fight!")
	var blocked_ids: Array[String] = []
	workshop.saved.connect(func(saved_id: String): blocked_ids.append(saved_id))
	if blocked_save != null: blocked_save.emit_signal("pressed")
	_expect(blocked_save != null and blocked_ids.is_empty() and workshop.step == 1 and workshop.selected_part == "head","incomplete imported fighter opens Bring to life at the first missing body part")
	_expect(workshop.record.photo_settings.get("life_tool","") == "polygon" and workshop._canvas_mode() == "polygon","save automatically switches from joint dots to Cutout shapes")
	var issue_overlay: Control = workshop.get_node_or_null("SaveIssueOverlay")
	var issue_button := _button_named(issue_overlay,"Got it!") if issue_overlay != null else null
	var issue_explanation := ""
	if issue_overlay != null:
		for child in issue_overlay.get_children():
			if child is Label and child.text.contains("does not find body parts"):
				issue_explanation = child.text
	_expect(issue_overlay != null and issue_button != null and issue_explanation.contains("outside edge") and issue_explanation.contains("does not find body parts") and workshop.status == "Let's finish the paper cutouts!","child-friendly message explains joint dots do not detect cutouts")
	var game_library = root.get_node_or_null("Doodles")
	_expect(game_library != null,"project fighter library is available to the workshop")
	if game_library != null:
		game_library.save_root = temp.path_join("button_library")
		game_library.save_path = game_library.save_root.path_join("library.json")
		game_library.load_data()
		var button_record: Dictionary = game_library.new_record()
		button_record.name = "Imported Button Test"
		button_record.strokes = []
		button_record.source_path = png
		button_record.photo_path = imported_record.photo_path
		button_record.photo_parts = {
			"head":[[190,40],[320,40],[320,160],[190,160]],
			"body":[[200,150],[310,150],[310,300],[200,300]],
			"left_arm":[[130,150],[210,150],[210,250],[130,250]],
			"right_arm":[[300,150],[380,150],[380,250],[300,250]],
			"left_leg":[[190,285],[245,285],[245,450],[190,450]],
			"right_leg":[[265,285],[320,285],[320,450],[265,450]]
		}
		var button_workshop := Workshop.new()
		root.add_child(button_workshop)
		button_workshop.build(null,button_record)
		button_workshop.step = 4
		button_workshop._build_ui()
		var emitted_ids: Array[String] = []
		button_workshop.saved.connect(func(saved_id: String): emitted_ids.append(saved_id))
		var save_only := _button_named(button_workshop,"Save fighter")
		if save_only != null: save_only.emit_signal("pressed")
		_expect(save_only != null and game_library.has(str(button_record.id)) and button_workshop.step == 4 and emitted_ids.is_empty(),"Save fighter button stores an imported fighter and stays in the workshop")
		_expect(button_workshop.status.contains("Saved!") and button_workshop.record.get("photo_parts",{}).size() == 6,"imported cutouts remain saved and success feedback is shown")
		var save_and_fight := _button_named(button_workshop,"Save & Fight!")
		if save_and_fight != null: save_and_fight.emit_signal("pressed")
		_expect(save_and_fight != null and emitted_ids == [str(button_record.id)],"Save & Fight button emits the saved imported fighter id")
		button_workshop.free()
	workshop.free()
	reopened.free()
	library.free()
	var sound = root.get_node_or_null("/root/Sound")
	if sound != null: sound.shutdown()
	print("test_workshop checks=%d failures=%d" % [checks,failures])
	quit(1 if failures > 0 else 0)
