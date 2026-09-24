extends Node
## Local, versioned sketchbook. Only this component writes custom fighter data.

signal changed

const VERSION := 1
const MAX_RECORDS := 6
const MAX_SAVE_BYTES := 2097152
const MAX_PHOTO_BYTES := 20971520
const MAX_STROKES := 1000
const MAX_POINTS_PER_STROKE := 4000
const MAX_TOTAL_POINTS := 25000
const PARTS := ["head", "body", "left_arm", "right_arm", "left_leg", "right_leg"]
const KITS := ["pixel_pick", "bone", "bat", "ball", "rubber_chicken", "giant_crayon"]
const SAVE_ROOT := "user://doodles"

var last_error: String = ""
var save_root: String = SAVE_ROOT
var save_path: String = SAVE_ROOT.path_join("library.json")
var _records: Array[Dictionary] = []
var _primary_clean := true

func _enter_tree() -> void:
	# Autoloaded before Data and Settings: choose the QA profile before either can
	# read user://. Never touch the family's profile during native smoke tests.
	if "--isolated-qa" in OS.get_cmdline_user_args():
		ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
		var profile_id := str(OS.get_process_id())
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--qa-profile="):
				profile_id = argument.trim_prefix("--qa-profile=").validate_filename()
		ProjectSettings.set_setting("application/config/custom_user_dir_name", "DoodleRumbleQA/" + profile_id)
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--qa-user-dir="):
				var path := argument.trim_prefix("--qa-user-dir=")
				if path.is_absolute_path():
					save_root = path.path_join("doodles")
					save_path = save_root.path_join("library.json")

func _ready() -> void:
	load_data()

static func default_joints() -> Dictionary:
	return {
		"head": [256,105], "shoulder": [256,185], "hip": [256,300],
		"back_elbow": [185,235], "back_hand": [150,280],
		"front_elbow": [327,235], "front_hand": [362,280],
		"left_knee": [215,385], "left_foot": [190,460],
		"right_knee": [297,385], "right_foot": [322,460]
	}

static func starter_strokes() -> Array:
	return [
		{"part":"head","color":"#f6a047","width":19,"points":[[256,55],[223,61],[200,83],[192,111],[203,138],[228,153],[258,155],[284,145],[304,123],[307,95],[291,69],[256,55]],"base_figure":true},
		{"part":"body","color":"#f6a047","width":20,"points":[[256,181],[250,223],[256,267],[256,304]],"base_figure":true},
		{"part":"left_arm","color":"#f6a047","width":18,"points":[[249,192],[192,232],[160,276]],"base_figure":true},
		{"part":"right_arm","color":"#f6a047","width":18,"points":[[263,192],[323,232],[357,274]],"base_figure":true},
		{"part":"left_leg","color":"#f6a047","width":20,"points":[[251,299],[214,384],[190,453]],"base_figure":true},
		{"part":"right_leg","color":"#f6a047","width":20,"points":[[261,299],[298,384],[323,453]],"base_figure":true}
	]

func records() -> Array:
	return _records.duplicate(true)

func get_record(id: String) -> Dictionary:
	for record in _records:
		if str(record.id) == id:
			return record.duplicate(true)
	return {}

func has(id: String) -> bool:
	for record in _records:
		if str(record.id) == id: return true
	return false

func new_record() -> Dictionary:
	var id := _fresh_id()
	return {"id":id, "name":"My Doodle", "color":"#f6a047", "pen_color":"#f6a047", "kit":"pixel_pick",
		"strokes":starter_strokes(), "joints":default_joints(), "photo_path":"",
		"photo_parts":{}, "source_path":"", "photo_settings":{"paper_edge":true}}

func _fresh_id() -> String:
	var id := ""
	while id.is_empty() or has(id):
		id = "custom_%x_%x" % [Time.get_ticks_usec(), randi()]
	return id

func save_record(record: Dictionary) -> String:
	last_error = ""
	var candidate := _sanitize(record, false)
	if candidate.is_empty(): return ""
	var previous := -1
	for i in _records.size():
		if _records[i].id == candidate.id:
			previous = i
			break
	if previous < 0 and _records.size() >= MAX_RECORDS:
		last_error = "Your sketchbook has room for six fighters."
		return ""
	var old: Array[Dictionary] = _records.duplicate(true)
	var copied: Array[String] = []
	if not _own_assets(candidate, copied):
		for path in copied: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return ""
	if previous < 0: _records.append(candidate)
	else: _records[previous] = candidate
	if not _save_data():
		_records = old
		for path in copied: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return ""
	changed.emit()
	return candidate.id

func duplicate_record(id: String) -> String:
	last_error = ""
	var original := get_record(id)
	if original.is_empty():
		last_error = "That fighter is no longer in the sketchbook."
		return ""
	original.id = _fresh_id()
	original.name = str(original.name).substr(0, 27) + " Copy"
	return save_record(original)

func delete_record(id: String) -> bool:
	last_error = ""
	for i in _records.size():
		if _records[i].id == id:
			var old: Array[Dictionary] = _records.duplicate(true)
			_records.remove_at(i)
			if not _save_data():
				_records = old
				return false
			changed.emit()
			# Owned photos are deliberately retained: an interrupted editor or an
			# older backup may still refer to them. No foreign file is ever deleted.
			return true
	last_error = "That fighter is no longer in the sketchbook."
	return false

func load_data() -> void:
	_records.clear()
	last_error = ""
	_primary_clean = true
	var primary := _read_payload(save_path)
	var backup := _read_payload(save_path + ".bak")
	var valid: Dictionary = {}
	var damaged := false
	if primary.get("ok", false):
		for raw in primary.get("records", []):
			var parsed := _sanitize(raw, true)
			if parsed.is_empty() or valid.has(parsed.id): damaged = true
			else: valid[parsed.id] = parsed
	elif FileAccess.file_exists(save_path) or backup.get("ok", false):
		damaged = true
	if damaged and backup.get("ok", false):
		for raw in backup.get("records", []):
			var parsed := _sanitize(raw, true)
			if not parsed.is_empty() and not valid.has(parsed.id):
				valid[parsed.id] = parsed
	for id in valid.keys():
		if _records.size() >= MAX_RECORDS: break
		_records.append(valid[id])
	_primary_clean = not damaged
	if damaged:
		last_error = "Some sketchbook entries were damaged; valid fighters were restored."
		# Preserve the original bytes for forensic recovery, then write a clean
		# atomic snapshot assembled from every valid primary and backup entry.
		if FileAccess.file_exists(save_path) and not _copy_file(save_path, save_path + ".corrupt", MAX_SAVE_BYTES):
			last_error = "The damaged sketchbook needs a safe copy before repair."
			return
		_save_data()

func _read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK: return {}
	var data: Variant = parser.data
	if not data is Dictionary:
		return {}
	var version: Variant = data.get("version", -1)
	if not (version is int or version is float) or float(version) != float(VERSION) or not data.get("records", null) is Array:
		return {}
	return {"ok":true, "records":data.records}

func _save_data() -> bool:
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_root))
	if err != OK:
		last_error = "Could not open the sketchbook folder."
		return false
	var text := JSON.stringify({"version":VERSION,"records":_records})
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		last_error = "The sketchbook is too large to save."
		return false
	var temp := save_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write the sketchbook."
		return false
	file.store_string(text)
	file.flush()
	file.close()
	if _primary_clean and FileAccess.file_exists(save_path):
		_copy_file(save_path, save_path + ".bak", MAX_SAVE_BYTES)
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(save_path))
	if result != OK:
		last_error = "Could not finish saving the sketchbook."
		return false
	if not FileAccess.file_exists(save_path + ".bak"):
		_copy_file(save_path, save_path + ".bak", MAX_SAVE_BYTES)
	_primary_clean = true
	return true

func _own_assets(record: Dictionary, copied: Array[String]) -> bool:
	var id: String = record.id
	for key in ["photo_path", "source_path"]:
		var source: String = str(record.get(key, ""))
		if source.is_empty(): continue
		if not FileAccess.file_exists(source):
			last_error = "A photo for this fighter is missing."
			return false
		var extension := source.get_extension().to_lower()
		var allowed := ["png", "jpg", "jpeg", "webp", "heic", "heif"] if key == "source_path" else ["png", "jpg", "jpeg", "webp"]
		if extension not in allowed:
			last_error = "Choose a PNG, JPEG, WebP, HEIC, or HEIF picture."
			return false
		# New name per edit keeps the previous committed image intact if the
		# library write fails, and lets backups resolve the image they saved.
		if ProjectSettings.globalize_path(source).begins_with(ProjectSettings.globalize_path(save_root.path_join(id + "_"))):
			continue
		var owned := save_root.path_join(id + ("_matte_" if key == "photo_path" else "_source_") + str(Time.get_ticks_usec()) + "." + extension)
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_root)) != OK or not _copy_file(source, owned, MAX_PHOTO_BYTES):
			last_error = "Could not copy the photo into the sketchbook."
			return false
		copied.append(owned)
		record[key] = owned
	if record.photo_settings.has("matte_path") and not str(record.photo_path).is_empty():
		record.photo_settings.matte_path = record.photo_path
	return true

func _copy_file(source: String, dest: String, max_bytes: int) -> bool:
	var input := FileAccess.open(source, FileAccess.READ)
	if input == null or input.get_length() > max_bytes:
		if input != null: input.close()
		return false
	var output := FileAccess.open(dest + ".tmp", FileAccess.WRITE)
	if output == null:
		input.close()
		return false
	output.store_buffer(input.get_buffer(input.get_length()))
	output.flush()
	output.close()
	input.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(dest + ".tmp"), ProjectSettings.globalize_path(dest)) == OK

func _sanitize(raw: Variant, loading: bool) -> Dictionary:
	if not raw is Dictionary:
		if not loading: last_error = "That fighter has invalid data."
		return {}
	var id: String = str(raw.get("id", ""))
	if not id.begins_with("custom_") or id.length() > 60 or not id.is_valid_identifier():
		if loading: return {}
		id = _fresh_id()
	var name: String = str(raw.get("name", "")).strip_edges()
	if name.is_empty(): name = "My Doodle"
	name = name.substr(0, 32)
	var color: String = str(raw.get("color", "#f6a047"))
	if not Color.html_is_valid(color): color = "#f6a047"
	var pen_color: String = str(raw.get("pen_color", color))
	if not Color.html_is_valid(pen_color): pen_color = color
	var kit: String = str(raw.get("kit", "pixel_pick"))
	if kit not in KITS: kit = "pixel_pick"
	var joints: Dictionary = default_joints()
	if raw.get("joints", null) is Dictionary:
		for key in joints.keys():
			var point := _point(raw.joints.get(key, null))
			if point.size() == 2: joints[key] = point
	var strokes: Array = []
	if raw.get("strokes", null) is Array:
		if raw.strokes.size() > MAX_STROKES:
			if not loading: last_error = "Use fewer than 1,000 drawing strokes. Your draft is unchanged."
			return {}
		var total_points := 0
		for item in raw.strokes:
			if not item is Dictionary or str(item.get("part", "")) not in PARTS: continue
			var points: Array = []
			if item.get("points", null) is Array:
				if item.points.size() > MAX_POINTS_PER_STROKE:
					if not loading: last_error = "One stroke is too long (4,000 points max). Your draft is unchanged."
					return {}
				total_points += item.points.size()
				if total_points > MAX_TOTAL_POINTS:
					if not loading: last_error = "This fighter has too many drawing points (25,000 max). Your draft is unchanged."
					return {}
				for raw_point in item.points:
					var point := _point(raw_point)
					if point.size() == 2: points.append(point)
			if points.size() < 2: continue
			var ink: String = str(item.get("color", color))
			if not Color.html_is_valid(ink): ink = color
			var clean_stroke := {"part":str(item.part),"color":ink,"width":clampf(float(item.get("width", 12)),1.0,60.0),"points":points}
			if bool(item.get("detail", false)): clean_stroke.detail = true
			if bool(item.get("base_figure", false)): clean_stroke.base_figure = true
			strokes.append(clean_stroke)
	var photo_parts: Dictionary = {}
	if raw.get("photo_parts", null) is Dictionary:
		for part in PARTS:
			var polygon: Variant = raw.photo_parts.get(part, null)
			if not polygon is Array or polygon.size() < 3 or polygon.size() > 128: continue
			var points: Array = []
			for raw_point in polygon:
				var point := _point(raw_point)
				if point.size() == 2: points.append(point)
			if points.size() >= 3: photo_parts[part] = points
	var settings: Dictionary = raw.get("photo_settings", {}).duplicate(true) if raw.get("photo_settings", null) is Dictionary else {}
	settings["paper_edge"] = bool(settings.get("paper_edge", true))
	var photo_path: String = str(raw.get("photo_path", ""))
	var source_path: String = str(raw.get("source_path", ""))
	if loading:
		if not FileAccess.file_exists(photo_path): photo_path = ""
		if not FileAccess.file_exists(source_path): source_path = ""
	if strokes.is_empty() and (photo_path.is_empty() or photo_parts.is_empty()):
		if not loading: last_error = "Draw a fighter or finish cutting out a photo before saving."
		return {}
	return {"id":id,"name":name,"color":color,"pen_color":pen_color,"kit":kit,"strokes":strokes,"joints":joints,
		"photo_path":photo_path,"photo_parts":photo_parts,"source_path":source_path,"photo_settings":settings}

static func _point(value: Variant) -> Array:
	if not value is Array or value.size() != 2: return []
	if not (value[0] is int or value[0] is float) or not (value[1] is int or value[1] is float): return []
	var x := float(value[0])
	var y := float(value[1])
	if not is_finite(x) or not is_finite(y) or x < -64 or x > 576 or y < -64 or y > 576: return []
	return [x,y]
