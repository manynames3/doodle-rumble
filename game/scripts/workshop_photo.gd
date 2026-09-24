extends RefCounted
## Local paper-photo preparation. The source file is never edited.

const SIDE := 512
const WHITE := Color.WHITE

static func draft_dir() -> String:
	var temp: String = OS.get_environment("TMPDIR")
	if temp.is_empty(): temp = "/tmp"
	var path: String = temp.path_join("doodle_workshop_%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(path)
	return path

static func load_source(path: String) -> Dictionary:
	var image := Image.new()
	var load_path := path
	var ext := path.get_extension().to_lower()
	var orientation := _jpeg_orientation(path) if ext in ["jpg","jpeg"] else 1
	if ext in ["heic", "heif"] or image.load(path) != OK:
		load_path = draft_dir().path_join("import_%d.png" % Time.get_ticks_usec())
		var output: Array = []
		var code := OS.execute("sips", ["-s", "format", "png", path, "--out", load_path], output, true)
		if code != 0:
			return {"error": "This picture could not be opened. Try a JPEG, PNG, HEIC, or HEIF photo."}
		image = Image.new()
		if image.load(load_path) != OK:
			return {"error": "The converted picture could not be opened."}
	image.convert(Image.FORMAT_RGBA8)
	_apply_orientation(image,orientation)
	return {"image": image}

static func _u16(bytes: PackedByteArray, at: int, little: bool) -> int:
	if at < 0 or at+1 >= bytes.size(): return -1
	return int(bytes[at]) + (int(bytes[at+1]) << 8) if little else (int(bytes[at]) << 8) + int(bytes[at+1])

static func _u32(bytes: PackedByteArray, at: int, little: bool) -> int:
	if at < 0 or at+3 >= bytes.size(): return -1
	if little: return int(bytes[at]) + (int(bytes[at+1]) << 8) + (int(bytes[at+2]) << 16) + (int(bytes[at+3]) << 24)
	return (int(bytes[at]) << 24) + (int(bytes[at+1]) << 16) + (int(bytes[at+2]) << 8) + int(bytes[at+3])

static func _jpeg_orientation(path: String) -> int:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return 1
	var bytes: PackedByteArray = file.get_buffer(mini(file.get_length(),262144))
	if bytes.size() < 16 or bytes[0] != 0xff or bytes[1] != 0xd8: return 1
	var at := 2
	while at+10 < bytes.size():
		if bytes[at] != 0xff: break
		var marker: int = bytes[at+1]
		if marker == 0xda or marker == 0xd9: break
		var length: int = _u16(bytes,at+2,false)
		if length < 2 or at+2+length > bytes.size(): break
		var payload: int = at+4
		if marker == 0xe1 and bytes[payload] == 0x45 and bytes[payload+1] == 0x78 and bytes[payload+2] == 0x69 and bytes[payload+3] == 0x66 and bytes[payload+4] == 0 and bytes[payload+5] == 0:
			var tiff: int = payload+6
			var little: bool = bytes[tiff] == 0x49 and bytes[tiff+1] == 0x49
			if not little and not (bytes[tiff] == 0x4d and bytes[tiff+1] == 0x4d): return 1
			var ifd: int = tiff+_u32(bytes,tiff+4,little)
			var count: int = _u16(bytes,ifd,little)
			for i in mini(count,128):
				var entry: int = ifd+2+i*12
				if entry+11 >= bytes.size(): break
				if _u16(bytes,entry,little) == 0x0112:
					var orientation: int = _u16(bytes,entry+8,little)
					return orientation if orientation >= 1 and orientation <= 8 else 1
		at += 2+length
	return 1

static func _apply_orientation(image: Image, orientation: int) -> void:
	match orientation:
		2: image.flip_x()
		3: image.rotate_180()
		4: image.flip_y()
		5:
			image.flip_x()
			image.rotate_90(COUNTERCLOCKWISE)
		6: image.rotate_90(CLOCKWISE)
		7:
			image.flip_x()
			image.rotate_90(CLOCKWISE)
		8: image.rotate_90(COUNTERCLOCKWISE)

static func square_preview(source: Image, turns: int = 0) -> Image:
	var image := Image.create_empty(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	image.fill(WHITE)
	if source == null or source.is_empty():
		return image
	var rotated: bool = posmod(turns, 2) == 1
	var width: int = source.get_height() if rotated else source.get_width()
	var height: int = source.get_width() if rotated else source.get_height()
	var fit: float = minf(float(SIDE) / float(width), float(SIDE) / float(height))
	var draw_width: int = maxi(1, int(round(float(width) * fit)))
	var draw_height: int = maxi(1, int(round(float(height) * fit)))
	var scaled := source.duplicate()
	if turns == 1:
		scaled.rotate_90(CLOCKWISE)
	elif turns == 2:
		scaled.rotate_180()
	elif turns == 3:
		scaled.rotate_90(COUNTERCLOCKWISE)
	scaled.resize(draw_width, draw_height, Image.INTERPOLATE_LANCZOS)
	image.blit_rect(scaled, Rect2i(0, 0, draw_width, draw_height), Vector2i((SIDE-draw_width)/2, (SIDE-draw_height)/2))
	return image

static func make_matte(source_square: Image, settings: Dictionary) -> Image:
	var corners: Array = settings.get("corners", [[32,32],[480,32],[480,480],[32,480]])
	if corners.size() != 4:
		corners = [[32,32],[480,32],[480,480],[32,480]]
	var p0 := Vector2(float(corners[0][0]), float(corners[0][1]))
	var p1 := Vector2(float(corners[1][0]), float(corners[1][1]))
	var p2 := Vector2(float(corners[2][0]), float(corners[2][1]))
	var p3 := Vector2(float(corners[3][0]), float(corners[3][1]))
	var sensitivity: float = clampf(float(settings.get("sensitivity", 0.50)), 0.0, 1.0)
	# Most phone photos of "white paper" are warm gray after shadows and JPEG
	# compression. The old 0.70 floor could not clear backgrounds below that
	# brightness. Ease the control so its middle value handles ordinary shaded
	# paper, while keeping saturated marker colors out of the removal mask.
	var threshold: float = lerpf(0.995, 0.50, pow(sensitivity, 0.30))
	var image := Image.create_empty(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	var base := Image.create_empty(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	for y in SIDE:
		var v := float(y) / float(SIDE-1)
		for x in SIDE:
			var u := float(x) / float(SIDE-1)
			var source_point: Vector2 = p0 * ((1.0-u)*(1.0-v)) + p1 * (u*(1.0-v)) + p2 * (u*v) + p3 * ((1.0-u)*v)
			var color: Color = source_square.get_pixel(clampi(int(round(source_point.x)),0,SIDE-1), clampi(int(round(source_point.y)),0,SIDE-1))
			base.set_pixel(x,y,color)
			var light: float = minf(color.r, minf(color.g, color.b))
			var chroma: float = maxf(color.r,maxf(color.g,color.b)) - light
			var paper_coverage: float = smoothstep(threshold - 0.13, threshold + 0.035, light)
			var neutral_paper: float = 1.0 - smoothstep(0.10,0.30,chroma)
			color.a *= 1.0 - clampf(paper_coverage * neutral_paper,0.0,1.0)
			image.set_pixel(x,y,color)
	if settings.has("correction_strokes"):
		for stroke in settings.get("correction_strokes", []):
			var mode: String = str(stroke.get("mode", ""))
			if mode in ["keep", "erase"]:
				_paint_alpha(image,base,stroke,1.0 if mode == "keep" else 0.0)
	else:
		# Older doodles stored Keep and Erase separately; preserve their original
		# ordering until the first new correction migrates them to one ordered list.
		for stroke in settings.get("keep_strokes", []):
			_paint_alpha(image,base,stroke,1.0)
		for stroke in settings.get("erase_strokes", []):
			_paint_alpha(image,base,stroke,0.0)
	return image

static func _paint_alpha(image: Image, base: Image, stroke: Dictionary, alpha: float) -> void:
	var points: Array = stroke.get("points", [])
	var radius: int = clampi(int(stroke.get("width", 12)), 2, 72)
	for index in points.size():
		var point := Vector2(float(points[index][0]),float(points[index][1]))
		var previous := point if index == 0 else Vector2(float(points[index-1][0]),float(points[index-1][1]))
		var steps: int = maxi(1,int(previous.distance_to(point)))
		for step in steps+1:
			var center := previous.lerp(point,float(step)/float(steps))
			for y in range(maxi(0,int(center.y)-radius),mini(SIDE,int(center.y)+radius+1)):
				for x in range(maxi(0,int(center.x)-radius),mini(SIDE,int(center.x)+radius+1)):
					if Vector2(x,y).distance_squared_to(center) > radius*radius:
						continue
					var color: Color = base.get_pixel(x,y) if alpha > 0.5 else image.get_pixel(x,y)
					color.a = alpha
					image.set_pixel(x,y,color)

static func save_matte(record: Dictionary, source_square: Image) -> String:
	var id: String = str(record.get("id", "draft"))
	var path: String = draft_dir().path_join("%s_matte_draft.png" % id)
	var image := make_matte(source_square, record.get("photo_settings", {}))
	if image.save_png(path) != OK:
		return ""
	return path
