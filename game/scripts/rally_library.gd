extends RefCounted
## Doodle Rally's own versioned save. Fighting-game settings never enter this file.
const SAVE_PATH := "user://doodle_rally.json"
const VERSION := 1
const SAFE_RECT := Rect2(130, 220, 1020, 330)
const THEMES := ["desk", "castle", "sky"]
const STAMP_KINDS := ["ramp", "boost", "puddle", "gate", "wind"]
const MAX_CUSTOM := 24
const MAX_STAMPS := 32

var save_path: String = SAVE_PATH
var courses: Array[Dictionary] = []
var records: Dictionary = {}
var coins: int = 0
var stickers: Array[String] = []
var lifetime_stars: int = 0
var last_error: String = ""
var recovery_backup_path: String = ""
var _save_blocked: bool = false
var selected_style: int = 0
var selected_color: int = 0
var selected_sticker: String = "plain"
var selected_course_id: String = "desk"

func _init() -> void:
	courses = _presets()

static func _presets() -> Array[Dictionary]:
	return [
		{"id":"desk", "title":"Pencil Parade", "theme":"desk", "seed":1201,
		 "points":[Vector2(158,383),Vector2(229,241),Vector2(420,231),Vector2(543,353),Vector2(731,300),Vector2(883,229),Vector2(1090,282),Vector2(1112,471),Vector2(958,542),Vector2(780,488),Vector2(671,428),Vector2(454,540),Vector2(244,529)],
		 "stamps":[{"kind":"ramp","u":0.17,"lane":-24.0},{"kind":"boost","u":0.34,"lane":22.0},{"kind":"puddle","u":0.53,"lane":0.0},{"kind":"gate","u":0.75,"lane":-22.0}], "preset":true},
		{"id":"castle", "title":"Wobble Castle", "theme":"castle", "seed":1202,
		 "points":[Vector2(163,388),Vector2(202,247),Vector2(389,236),Vector2(516,349),Vector2(679,264),Vector2(897,225),Vector2(1106,324),Vector2(1082,509),Vector2(857,537),Vector2(700,418),Vector2(514,526),Vector2(286,537)],
		 "stamps":[{"kind":"ramp","u":0.22,"lane":23.0},{"kind":"gate","u":0.41,"lane":0.0},{"kind":"boost","u":0.62,"lane":-23.0},{"kind":"puddle","u":0.82,"lane":22.0}], "preset":true},
		{"id":"sky", "title":"Cloud Scribble", "theme":"sky", "seed":1203,
		 "points":[Vector2(162,387),Vector2(200,252),Vector2(353,224),Vector2(501,295),Vector2(608,391),Vector2(733,246),Vector2(936,235),Vector2(1107,335),Vector2(1106,502),Vector2(910,543),Vector2(774,463),Vector2(610,532),Vector2(392,533),Vector2(247,492)],
		 "stamps":[{"kind":"wind","u":0.15,"lane":0.0},{"kind":"boost","u":0.36,"lane":-22.0},{"kind":"ramp","u":0.59,"lane":22.0},{"kind":"gate","u":0.80,"lane":0.0}], "preset":true}
	]

func presets() -> Array[Dictionary]:
	return _presets()

func get_course(id: String) -> Dictionary:
	for course in courses:
		if course.id == id:
			return course.duplicate(true)
	return {}

func make_course(title: String, theme: String, points: Array, stamps: Array = []) -> Dictionary:
	var id := "custom_%d_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), randi()]
	return {"id":id, "title":title, "theme":theme, "points":points.duplicate(true), "stamps":stamps.duplicate(true), "seed":randi(), "preset":false}

static func validate_course(course: Dictionary) -> String:
	var title: String = str(course.get("title", "")).strip_edges()
	if title.is_empty() or title.length() > 32:
		return "Give your course a name of 1–32 letters."
	if not THEMES.has(str(course.get("theme", ""))):
		return "Pick a paper world for your course."
	var points: Variant = course.get("points", [])
	if not points is Array or points.size() < 6 or points.size() > 20:
		return "Join 6–20 dots to make a loop."
	for point in points:
		if not point is Vector2 or not point.is_finite() or not SAFE_RECT.has_point(point):
			return "Keep every dot inside the drawing guide."
	for i in range(points.size()):
		if points[i].distance_to(points[(i + 1) % points.size()]) < 40.0:
			return "Give neighboring dots a car length of room."
	var curve := build_curve(course)
	if curve == null or not is_finite(curve.get_baked_length()) or curve.get_baked_length() < 650.0:
		return "Spread your dots farther across the paper."
	var stamps: Variant = course.get("stamps", [])
	if not stamps is Array or stamps.size() > MAX_STAMPS:
		return "Use no more than 32 course stamps."
	for stamp in stamps:
		if not stamp is Dictionary or not STAMP_KINDS.has(str(stamp.get("kind", ""))):
			return "One course stamp needs a new type."
		var u: Variant = stamp.get("u", -1.0)
		var lane: Variant = stamp.get("lane", 100.0)
		if not (u is float or u is int) or not (lane is float or lane is int):
			return "Place each stamp on the road."
		if not is_finite(float(u)) or float(u) < 0.025 or float(u) > 0.975 or not is_finite(float(lane)) or absf(float(lane)) > 32.0:
			return "Place each stamp on the road."
	return ""

static func build_curve(course: Dictionary) -> Curve2D:
	var points: Variant = course.get("points", [])
	if not points is Array or points.size() < 3:
		return null
	var curve := Curve2D.new()
	curve.bake_interval = 3.0
	for i in range(points.size() + 1):
		var index: int = i % points.size()
		var current: Vector2 = points[index]
		var previous: Vector2 = points[posmod(index - 1, points.size())]
		var next: Vector2 = points[(index + 1) % points.size()]
		var handle: Vector2 = (next - previous) * 0.17
		var incoming: Vector2 = (current - handle).clamp(SAFE_RECT.position, SAFE_RECT.end) - current
		var outgoing: Vector2 = (current + handle).clamp(SAFE_RECT.position, SAFE_RECT.end) - current
		curve.add_point(current, incoming, outgoing)
	return curve

func save_course(course: Dictionary) -> Dictionary:
	last_error = ""
	var candidate := course.duplicate(true)
	var id: String = str(candidate.get("id", ""))
	if not id.begins_with("custom_") or not id.is_valid_identifier() or id.length() > 64:
		candidate.id = make_course(str(candidate.get("title", "My Course")), str(candidate.get("theme", "desk")), candidate.get("points", []), candidate.get("stamps", [])).id
	candidate.title = str(candidate.get("title", "")).strip_edges()
	candidate.preset = false
	last_error = validate_course(candidate)
	if not last_error.is_empty():
		return {}
	var previous := -1
	for i in range(courses.size()):
		if courses[i].id == candidate.id:
			previous = i
			break
	if previous < 0 and courses.size() - 3 >= MAX_CUSTOM:
		last_error = "Your sketchbook has room for 24 saved courses."
		return {}
	var old_course: Dictionary = courses[previous].duplicate(true) if previous >= 0 else {}
	var old_records := records.duplicate(true)
	var old_selection := selected_course_id
	if previous >= 0:
		courses[previous] = candidate
		if not _same_layout(old_course, candidate):
			for key in records.keys():
				if str(key).begins_with(candidate.id + "|"):
					records.erase(key)
	else:
		courses.append(candidate)
	selected_course_id = candidate.id
	if not save_data():
		if previous >= 0:
			courses[previous] = old_course
		else:
			courses.pop_back()
		records = old_records
		selected_course_id = old_selection
		return {}
	return candidate.duplicate(true)

static func _same_layout(a: Dictionary, b: Dictionary) -> bool:
	return a.get("theme", "") == b.get("theme", "") and a.get("points", []) == b.get("points", []) and a.get("stamps", []) == b.get("stamps", [])

func delete_course(id: String) -> bool:
	for i in range(3, courses.size()):
		if courses[i].id == id:
			var removed: Dictionary = courses[i]
			var old_selection := selected_course_id
			var old_records := records.duplicate(true)
			courses.remove_at(i)
			for key in records.keys():
				if str(key).begins_with(id + "|"):
					records.erase(key)
			if selected_course_id == id:
				selected_course_id = "desk"
			if not save_data():
				courses.insert(i, removed)
				records = old_records
				selected_course_id = old_selection
				return false
			return true
	return false

func record_result(id: String, time: float, stars: int, rank: int, mode: String = "solo") -> Dictionary:
	if get_course(id).is_empty() or not is_finite(time) or time <= 0.0 or time > 86400.0 or stars < 0 or stars > 999 or rank < 1 or rank > 12:
		return {}
	if mode.is_empty() or mode.length() > 48 or not mode.is_valid_identifier():
		return {}
	var previous_records := records.duplicate(true)
	var previous_coins := coins
	var previous_stars := lifetime_stars
	var previous_stickers := stickers.duplicate()
	var key := id + "|" + mode
	var record: Dictionary = records.get(key, {"best_time":time, "best_stars":0, "best_rank":rank, "finishes":0})
	var improved: bool = not records.has(key) or time < float(record.get("best_time", 1e20))
	record.best_time = minf(float(record.get("best_time", time)), time)
	record.best_stars = maxi(int(record.get("best_stars", 0)), stars)
	record.best_rank = mini(int(record.get("best_rank", rank)), rank)
	record.finishes = mini(int(record.get("finishes", 0)) + 1, 999999)
	records[key] = record
	var coins_earned: int = 2 + stars + maxi(0, 4 - rank)
	coins = mini(coins + coins_earned, 999999)
	lifetime_stars = mini(lifetime_stars + stars, 999999)
	if not stickers.has("star"):
		stickers.append("star")
	var total_finishes := 0
	for saved in records.values():
		total_finishes += int(saved.get("finishes", 0))
	if (lifetime_stars >= 30 or total_finishes >= 3) and not stickers.has("lightning"):
		stickers.append("lightning")
	if not save_data():
		records = previous_records
		coins = previous_coins
		lifetime_stars = previous_stars
		stickers = previous_stickers
		return {}
	var result := record.duplicate(true)
	result.improved = improved
	result.new_best = improved
	result.coins_earned = coins_earned
	result.total_coins = coins
	result.medal = "gold" if rank == 1 else ("silver" if rank == 2 else "bronze")
	return result

func load_data() -> void:
	courses = _presets()
	records = {}
	coins = 0
	lifetime_stars = 0
	last_error = ""
	recovery_backup_path = ""
	_save_blocked = false
	stickers.clear()
	selected_style = 0
	selected_color = 0
	selected_sticker = "plain"
	selected_course_id = "desk"
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_quarantine_save()
		return
	if file.get_length() > 262144:
		file.close()
		_quarantine_save()
		return
	var contents := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(contents) != OK:
		_quarantine_save()
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		_quarantine_save()
		return
	var stored_version: Variant = parsed.get("version", -1)
	if not (stored_version is int or stored_version is float) or stored_version != VERSION:
		_quarantine_save()
		return
	var damaged := false
	var raw_courses: Variant = parsed.get("courses", [])
	if raw_courses is Array:
		if raw_courses.size() > MAX_CUSTOM:
			damaged = true
		for raw in raw_courses.slice(0, MAX_CUSTOM):
			var candidate := _decode_course(raw)
			if not candidate.is_empty() and validate_course(candidate).is_empty() and get_course(candidate.id).is_empty():
				courses.append(candidate)
			else:
				damaged = true
	else:
		damaged = true
	var raw_records: Variant = parsed.get("records", {})
	if raw_records is Dictionary:
		for key in raw_records.keys():
			if not key is String or key.length() > 80 or not raw_records[key] is Dictionary:
				damaged = true
				continue
			var parts: PackedStringArray = key.split("|")
			if parts.size() != 2 or get_course(parts[0]).is_empty() or parts[1].length() > 48 or not parts[1].is_valid_identifier():
				damaged = true
				continue
			var item: Dictionary = raw_records[key]
			var t: float = _safe_number(item.get("best_time", -1), -1.0)
			if t <= 0.0 or t > 86400.0:
				damaged = true
				continue
			records[key] = {"best_time":t, "best_stars":clampi(int(_safe_number(item.get("best_stars", 0), 0)), 0, 999), "best_rank":clampi(int(_safe_number(item.get("best_rank", 12), 12)), 1, 12), "finishes":clampi(int(_safe_number(item.get("finishes", 1), 1)), 1, 999999)}
	else:
		damaged = true
	coins = clampi(int(_safe_number(parsed.get("coins", 0), 0)), 0, 999999)
	lifetime_stars = clampi(int(_safe_number(parsed.get("lifetime_stars", 0), 0)), 0, 999999)
	var raw_stickers: Variant = parsed.get("stickers", [])
	if raw_stickers is Array:
		for value in raw_stickers.slice(0, 100):
			if value is String and value in ["star", "lightning"] and not stickers.has(value):
				stickers.append(value)
	selected_style = clampi(int(_safe_number(parsed.get("selected_style", 0), 0)), 0, 2)
	selected_color = clampi(int(_safe_number(parsed.get("selected_color", 0), 0)), 0, 3)
	var picked_sticker: String = str(parsed.get("selected_sticker", "plain"))
	if picked_sticker == "plain" or (picked_sticker in ["star", "lightning"] and stickers.has(picked_sticker)):
		selected_sticker = picked_sticker
	var selection: String = str(parsed.get("selected_course_id", "desk"))
	if not get_course(selection).is_empty():
		selected_course_id = selection
	if damaged:
		_quarantine_save()

func _quarantine_save() -> void:
	var original := ProjectSettings.globalize_path(save_path)
	var backup := original + ".damaged_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var moved := DirAccess.rename_absolute(original, backup) == OK
	if not moved and DirAccess.copy_absolute(original, backup) != OK:
		_save_blocked = true
		last_error = "Your old rally save could not be backed up. Its file is untouched."
		return
	recovery_backup_path = backup
	last_error = "Recovered rally data. A copy of the old save was kept."

static func _safe_number(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		if is_finite(float(value)):
			return float(value)
	return fallback

static func _decode_course(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var id: String = str(raw.get("id", ""))
	if not id.begins_with("custom_") or not id.is_valid_identifier() or id.length() > 64:
		return {}
	var raw_points: Variant = raw.get("points", [])
	if not raw_points is Array or raw_points.size() < 6 or raw_points.size() > 20:
		return {}
	var points: Array = []
	for pair in raw_points:
		if not pair is Array or pair.size() != 2:
			return {}
		var x := _safe_number(pair[0], NAN)
		var y := _safe_number(pair[1], NAN)
		if not is_finite(x) or not is_finite(y):
			return {}
		points.append(Vector2(x, y))
	var raw_stamps: Variant = raw.get("stamps", [])
	if not raw_stamps is Array or raw_stamps.size() > MAX_STAMPS:
		return {}
	var stamps: Array = []
	for raw_stamp in raw_stamps:
		if not raw_stamp is Dictionary:
			return {}
		stamps.append({"kind":str(raw_stamp.get("kind", "")), "u":_safe_number(raw_stamp.get("u", NAN), NAN), "lane":_safe_number(raw_stamp.get("lane", NAN), NAN)})
	return {"id":id, "title":str(raw.get("title", "")), "theme":str(raw.get("theme", "")), "points":points, "stamps":stamps, "seed":clampi(int(_safe_number(raw.get("seed", 0), 0)), 0, 2147483647), "preset":false}

func save_data() -> bool:
	if _save_blocked:
		last_error = "The old rally save needs a safe backup before changes can be saved."
		return false
	last_error = ""
	var custom: Array = []
	for course in courses:
		if bool(course.get("preset", false)):
			continue
		if not validate_course(course).is_empty():
			continue
		var points: Array = []
		for point in course.points:
			points.append([point.x, point.y])
		custom.append({"id":course.id, "title":course.title, "theme":course.theme, "seed":int(course.get("seed", 0)), "points":points, "stamps":course.get("stamps", [])})
	var payload := {"version":VERSION, "courses":custom, "records":records, "coins":coins, "stickers":stickers, "lifetime_stars":lifetime_stars, "selected_style":selected_style, "selected_color":selected_color, "selected_sticker":selected_sticker if selected_sticker == "plain" or stickers.has(selected_sticker) else "plain", "selected_course_id":selected_course_id}
	var temp_path := save_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open the rally save file."
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var saved := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path)) == OK
	if not saved:
		last_error = "Could not finish saving the rally data."
	return saved
