extends Node2D
## Poses one imported cutout or set of drawn strokes on the shared fighter rig.
## All coordinates in saved records are on a 512 x 512 binding canvas.

const CANVAS := 512.0
const LOCAL_SCALE := 0.32
## The actor is displayed at about 145 px high, so a 0.75 render scale remains
## crisp while avoiding a 640x640 redraw for every moving custom fighter.
const RENDER_SCALE := 0.75
const FEET_Y := 460.0
const PAPER_SHADER = preload("res://assets/shaders/custom_paper_edge.gdshader")
const PARTS := ["left_leg", "right_leg", "left_arm", "body", "head", "right_arm"]
const SEGMENTS := ["left_leg_proximal", "left_leg_distal", "right_leg_proximal", "right_leg_distal",
	"left_arm_proximal", "left_arm_distal", "body", "head", "right_arm_proximal", "right_arm_distal"]

class Painter extends Node2D:
	var art: Node2D
	func _draw() -> void:
		if is_instance_valid(art): art._draw_in_viewport(self)

class StaticPainter extends Node2D:
	var art: Node2D
	var segment: String
	func _draw() -> void:
		if is_instance_valid(art): art._draw_static_segment(self, segment)

var record: Dictionary = {}
var visual_height: float = 145.0
var visual_head: Vector2 = Vector2(0, -112)
var margin_world_px: float = 2.5
@export_range(32, 128, 8) var canvas_padding_px: int = 64
var _viewport: SubViewport
var _painter: Painter
var _sprite: Sprite2D
var _photo: Texture2D
var _photo_image: Image
var _posed: Dictionary = {}
var _bind: Dictionary = {}
var _state: Dictionary = {}
var _photo_geometry: Dictionary = {}
var _strokes_by_segment: Dictionary = {}
var _deform_transforms: Dictionary = {}
var _static_viewports: Array[SubViewport] = []
var _segment_nodes: Dictionary = {}
var _bake_warmup_frames := 0

func _ready() -> void:
	_ensure_nodes()
	if not record.is_empty(): pose_preview()
	if _bake_warmup_frames == 0: set_process(false)

func _process(_delta: float) -> void:
	# A composite can sample a freshly added SubViewport before its cached
	# texture has rendered. Refresh only during the first three display frames.
	if _bake_warmup_frames > 0:
		_bake_warmup_frames -= 1
		_request_draw()
	if _bake_warmup_frames == 0: set_process(false)

func _ensure_nodes() -> void:
	if _viewport != null: return
	_viewport = SubViewport.new()
	_viewport.name = "PosedCutoutComposite"
	_viewport.size = Vector2i(roundi((512.0 + canvas_padding_px * 2.0) * RENDER_SCALE), roundi((512.0 + canvas_padding_px * 2.0) * RENDER_SCALE))
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	add_child(_viewport)
	_painter = Painter.new()
	_painter.art = self
	_painter.name = "PaintedParts"
	_viewport.add_child(_painter)
	_sprite = Sprite2D.new()
	_sprite.name = "PaperCutout"
	_sprite.texture = _viewport.get_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.position = Vector2(0, (256.0 - FEET_Y) * LOCAL_SCALE)
	_sprite.scale = Vector2.ONE * (LOCAL_SCALE / RENDER_SCALE)
	add_child(_sprite)
	_set_margin()

func set_canvas_padding(pixels: int) -> void:
	canvas_padding_px = clampi(pixels, 32, 128)
	if _viewport != null:
		_viewport.size = Vector2i(roundi((512.0 + canvas_padding_px * 2.0) * RENDER_SCALE), roundi((512.0 + canvas_padding_px * 2.0) * RENDER_SCALE))
		_rebuild_static_parts()
		_set_margin()
		_request_draw()

func set_paper_margin(world_pixels: float) -> void:
	margin_world_px = clampf(world_pixels, 1.0, 5.0)
	_set_margin()

func refresh_art() -> void:
	_build_deform_transforms()
	_sync_segment_transforms()
	_request_draw()

func _request_draw() -> void:
	if _painter == null or _viewport == null: return
	if _photo != null: _painter.queue_redraw()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func configure(value: Dictionary) -> void:
	_ensure_nodes()
	record = value.duplicate(true)
	_bind = record.get("joints", {}).duplicate(true)
	var defaults: Dictionary = {"head":[256,105],"shoulder":[256,185],"hip":[256,300],
		"back_elbow":[185,235],"back_hand":[150,280],"front_elbow":[327,235],"front_hand":[362,280],
		"left_knee":[215,385],"left_foot":[190,460],"right_knee":[297,385],"right_foot":[322,460]}
	for key in defaults.keys():
		if not _bind.has(key): _bind[key] = defaults[key]
	_photo = null
	_photo_image = null
	var path: String = str(record.get("photo_path", ""))
	if path.is_empty() and record.get("photo_settings", null) is Dictionary:
		path = str(record.photo_settings.get("matte_path", ""))
	if not path.is_empty() and FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			# A 512 square is the binding convention; importing an odd image never
			# changes its saved joint or polygon coordinates.
			if image.get_size() != Vector2i(512, 512): image.resize(512, 512, Image.INTERPOLATE_LANCZOS)
			_photo_image = image
			_photo = ImageTexture.create_from_image(image)
	var photo_settings: Dictionary = record.get("photo_settings", {}) if record.get("photo_settings", {}) is Dictionary else {}
	margin_world_px = 2.5 if bool(photo_settings.get("paper_edge", true)) else 0.0
	_build_photo_geometry()
	_prepare_render_strokes()
	_rebuild_static_parts()
	_set_margin()
	pose_preview()

func _set_margin() -> void:
	if _sprite == null: return
	# Drawn fighters do not need the alpha-expansion pass at all.
	if _photo == null:
		_sprite.material = null
		return
	if _sprite.material == null:
		var paper := ShaderMaterial.new()
		paper.shader = PAPER_SHADER
		_sprite.material = paper
	var material: ShaderMaterial = _sprite.material
	material.set_shader_parameter("edge_pixels", margin_world_px * RENDER_SCALE / LOCAL_SCALE)
	material.set_shader_parameter("edge_opacity", 0.98 if margin_world_px > 0.0 else 0.0)

func _build_photo_geometry() -> void:
	_photo_geometry.clear()
	if _photo == null: return
	var photo_parts: Variant = record.get("photo_parts", {})
	if not photo_parts is Dictionary: return
	for part in PARTS:
		var raw: Variant = photo_parts.get(part, null)
		if not raw is Array or raw.size() < 3: continue
		var original := PackedVector2Array()
		for point in raw: original.append(_vec(point))
		var shapes: Array[Dictionary] = []
		if part.ends_with("_arm") or part.ends_with("_leg"):
			var elbow_key := "back_elbow" if part == "left_arm" else "front_elbow" if part == "right_arm" else "left_knee" if part == "left_leg" else "right_knee"
			var root_key := "shoulder" if part.ends_with("_arm") else "hip"
			var root := _vec(_bind[root_key])
			var elbow := _vec(_bind[elbow_key])
			var axis := (elbow-root).normalized()
			var side := axis.orthogonal() * 1024.0
			var far := axis * 1024.0
			var overlap := axis * 2.0
			var proximal := PackedVector2Array([elbow-side-far*2.0, elbow+side-far*2.0, elbow+side+overlap, elbow-side+overlap])
			var distal := PackedVector2Array([elbow-side-overlap, elbow+side-overlap, elbow+side+far*2.0, elbow-side+far*2.0])
			for clipped in Geometry2D.intersect_polygons(original, proximal):
				if clipped.size() >= 3: shapes.append({"points":clipped,"distal":false})
			for clipped in Geometry2D.intersect_polygons(original, distal):
				if clipped.size() >= 3: shapes.append({"points":clipped,"distal":true})
		else:
			shapes.append({"points":original,"distal":false})
		var cached: Array[Dictionary] = []
		for shape in shapes:
			var polygon: PackedVector2Array = shape.points
			if Geometry2D.triangulate_polygon(polygon).is_empty(): continue
			var uvs := PackedVector2Array()
			var colors := PackedColorArray()
			for point in polygon:
				uvs.append(point / CANVAS)
				colors.append(Color.WHITE)
			cached.append({"points":polygon,"uvs":uvs,"colors":colors,"distal":bool(shape.distal)})
		if not cached.is_empty(): _photo_geometry[part] = cached

func _build_deform_transforms() -> void:
	_deform_transforms.clear()
	var pairs := {
		"body":["shoulder","hip"],
		"left_arm_proximal":["shoulder","back_elbow"],"left_arm_distal":["back_elbow","back_hand"],
		"right_arm_proximal":["shoulder","front_elbow"],"right_arm_distal":["front_elbow","front_hand"],
		"left_leg_proximal":["hip","left_knee"],"left_leg_distal":["left_knee","left_foot"],
		"right_leg_proximal":["hip","right_knee"],"right_leg_distal":["right_knee","right_foot"]
	}
	for key in pairs:
		var pair: Array = pairs[key]
		_deform_transforms[key] = _bone_transform(str(pair[0]),str(pair[1]))
	var center := _vec(_bind.get("head",[256,105]))
	var destination: Vector2 = _posed.get("head",_canvas_to_local(center))
	var angle: float = float(_state.get("head_tilt",0.0))
	var x_axis := Vector2(cos(angle),sin(angle))*LOCAL_SCALE
	var y_axis := Vector2(-sin(angle),cos(angle))*LOCAL_SCALE
	_deform_transforms["head"] = Transform2D(x_axis,y_axis,destination-x_axis*center.x-y_axis*center.y)

func _bone_transform(start_key: String, end_key: String) -> Transform2D:
	var bind_start := _vec(_bind[start_key])
	var bind_end := _vec(_bind[end_key])
	var bind_tangent := bind_end-bind_start
	var length_sq := maxf(bind_tangent.length_squared(),1.0)
	var bind_length := sqrt(length_sq)
	var posed_start: Vector2 = _posed.get(start_key,_canvas_to_local(bind_start))
	var posed_end: Vector2 = _posed.get(end_key,_canvas_to_local(bind_end))
	var posed_tangent := posed_end-posed_start
	var normal := -posed_tangent.normalized().orthogonal() if posed_tangent.length_squared() > 0.0001 else -bind_tangent.normalized().orthogonal()
	var x_axis := posed_tangent*(bind_tangent.x/length_sq)+normal*(LOCAL_SCALE*(-bind_tangent.y/bind_length))
	var y_axis := posed_tangent*(bind_tangent.y/length_sq)+normal*(LOCAL_SCALE*(bind_tangent.x/bind_length))
	return Transform2D(x_axis,y_axis,posed_start-x_axis*bind_start.x-y_axis*bind_start.y)

func _prepare_render_strokes() -> void:
	_strokes_by_segment.clear()
	var strokes: Variant = record.get("strokes", [])
	if not strokes is Array: return
	for stroke in strokes:
		if not stroke is Dictionary or str(stroke.get("part", "")) not in PARTS: continue
		var raw: Variant = stroke.get("points", [])
		if not raw is Array or raw.size() < 2: continue
		var points := PackedVector2Array()
		var last := Vector2.ZERO
		for value in raw:
			var point := _vec(value)
			if points.is_empty() or point.distance_squared_to(last) >= 1.44:
				points.append(point)
				last = point
		var endpoint := _vec(raw.back())
		if points.is_empty() or points[points.size()-1].distance_squared_to(endpoint) > 0.04:
			points.append(endpoint)
		if points.size() < 2: continue
		var part: String = str(stroke.part)
		var color := Color(str(stroke.get("color", record.get("color", "#f6a047"))))
		var width := clampf(float(stroke.get("width",10.0)),1.0,60.0)
		var current_distal := _is_distal(part,points[0])
		var path := PackedVector2Array([points[0]])
		for index in range(1, points.size()):
			var next_distal := _is_distal(part,points[index])
			if next_distal != current_distal:
				# Split at the elbow/knee's binding-plane boundary. Both cached
				# pieces share this endpoint, so the stroke remains joined in motion.
				var cut := _stroke_joint_cut(part,points[index-1],points[index])
				path.append(cut)
				_add_static_stroke(_segment_key(part,current_distal),path,color,width)
				path = PackedVector2Array([cut])
				current_distal = next_distal
			path.append(points[index])
		_add_static_stroke(_segment_key(part,current_distal),path,color,width)

func _add_static_stroke(segment: String, path: PackedVector2Array, color: Color, width: float) -> void:
	if path.size() < 2: return
	if not _strokes_by_segment.has(segment): _strokes_by_segment[segment] = []
	_strokes_by_segment[segment].append({"points":path,"color":color,"width":width})

func _segment_key(part: String, distal: bool) -> String:
	if part.ends_with("_arm") or part.ends_with("_leg"):
		return part + ("_distal" if distal else "_proximal")
	return part

func _stroke_joint_cut(part: String, first: Vector2, second: Vector2) -> Vector2:
	var root_key := "shoulder" if part.ends_with("_arm") else "hip"
	var joint_key := "back_elbow" if part == "left_arm" else "front_elbow" if part == "right_arm" else "left_knee" if part == "left_leg" else "right_knee"
	var root := _vec(_bind[root_key])
	var joint := _vec(_bind[joint_key])
	var axis := joint-root
	var first_side := (first-joint).dot(axis)
	var second_side := (second-joint).dot(axis)
	return first.lerp(second,clampf(-first_side/(second_side-first_side),0.0,1.0)) if absf(second_side-first_side) > 0.0001 else first.lerp(second,0.5)

func _rebuild_static_parts() -> void:
	for node in _segment_nodes.values():
		if is_instance_valid(node): node.queue_free()
	_segment_nodes.clear()
	for viewport in _static_viewports:
		if is_instance_valid(viewport): viewport.queue_free()
	_static_viewports.clear()
	if _viewport == null or record.is_empty(): return
	var page_size := Vector2i(roundi((CANVAS+canvas_padding_px*2.0)*RENDER_SCALE),roundi((CANVAS+canvas_padding_px*2.0)*RENDER_SCALE))
	for segment in SEGMENTS:
		if not _strokes_by_segment.has(segment) and not _has_photo_segment(segment): continue
		var page := SubViewport.new()
		page.name = "Cached_" + segment
		page.size = page_size
		page.transparent_bg = true
		page.disable_3d = true
		page.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(page)
		var painter := StaticPainter.new()
		painter.art = self
		painter.segment = segment
		page.add_child(painter)
		_static_viewports.append(page)
		var bone := Node2D.new()
		bone.name = "Posed_" + segment
		_viewport.add_child(bone)
		var image := Sprite2D.new()
		image.texture = page.get_texture()
		image.centered = false
		image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		image.position = Vector2.ONE * -float(canvas_padding_px)
		image.scale = Vector2.ONE / RENDER_SCALE
		bone.add_child(image)
		_segment_nodes[segment] = bone
	_sync_segment_transforms()
	_bake_warmup_frames = 3
	set_process(true)

func _has_photo_segment(segment: String) -> bool:
	if _photo == null: return false
	var part := segment.trim_suffix("_proximal").trim_suffix("_distal")
	for shape in _photo_geometry.get(part, []):
		if _segment_key(part,bool(shape.distal)) == segment: return true
	return false

func _sync_segment_transforms() -> void:
	var factor := RENDER_SCALE / LOCAL_SCALE
	var viewport_from_local := Transform2D(Vector2(factor,0),Vector2(0,factor),Vector2(256+canvas_padding_px,FEET_Y+canvas_padding_px)*RENDER_SCALE)
	for segment in _segment_nodes:
		if _deform_transforms.has(segment):
			_segment_nodes[segment].transform = viewport_from_local * _deform_transforms[segment]

func pose_preview(state: Dictionary = {}) -> void:
	_state = state.duplicate()
	_posed.clear()
	for key in _bind.keys():
		_posed[key] = _canvas_to_local(_vec(_bind[key]))
	_build_deform_transforms()
	if bool(state.get("reduced_motion", false)):
		_sync_segment_transforms()
		_request_draw()
		return
	var age: float = float(state.get("age", 0.0))
	var move: float = float(state.get("move", 0.0))
	var breathe: float = sin(age * 2.8) * 1.2
	for key in ["head", "shoulder", "back_elbow", "front_elbow", "back_hand", "front_hand"]:
		_posed[key] += Vector2(move * 2.0, breathe)
	_posed.left_knee += Vector2(sin(age * 8.0) * move * 5.0, 0)
	_posed.right_knee += Vector2(-sin(age * 8.0) * move * 5.0, 0)
	_build_deform_transforms()
	_sync_segment_transforms()
	_request_draw()

func pose_from_rig(rig: Node2D, state: Dictionary = {}) -> void:
	if _painter == null: _ensure_nodes()
	_state = state.duplicate()
	_posed.clear()
	for key in _bind.keys():
		var value: Variant = rig.get(key)
		_posed[key] = value if value is Vector2 else _canvas_to_local(_vec(_bind[key]))
	_state.head_tilt = float(rig.get("head_tilt"))
	visual_head = _posed.get("head", Vector2(0,-112))
	_build_deform_transforms()
	_sync_segment_transforms()
	_request_draw()

func is_rendering() -> bool:
	return visible and _sprite != null

func _draw_in_viewport(canvas: Node2D) -> void:
	if _photo == null: return
	var photo_parts: Variant = record.get("photo_parts", {})
	if photo_parts is Dictionary: _draw_joint_bridges(canvas, photo_parts)

func _draw_static_segment(canvas: Node2D, segment: String) -> void:
	# Pencil marks and original photo pixels are rasterized only once. During
	# combat, ten small textured pieces follow the rig instead of resubmitting
	# thousands of lines and circles to the renderer every animation frame.
	canvas.draw_set_transform(Vector2.ONE * float(canvas_padding_px) * RENDER_SCALE,0.0,Vector2.ONE * RENDER_SCALE)
	if _photo != null:
		var part := segment.trim_suffix("_proximal").trim_suffix("_distal")
		for shape in _photo_geometry.get(part, []):
			if _segment_key(part,bool(shape.distal)) == segment:
				canvas.draw_polygon(shape.points,shape.colors,shape.uvs,_photo)
	for stroke in _strokes_by_segment.get(segment, []):
		var path: PackedVector2Array = stroke.points
		var color: Color = stroke.color
		var width: float = stroke.width
		var ink_width := width + 2.5
		canvas.draw_polyline(path, Color("13121c"), ink_width, true)
		canvas.draw_polyline(path, color, width, true)
		# Tiny decoration lines look round at gameplay size without four extra
		# cap commands each. Keep the drawn marker caps on broad silhouette lines.
		if width >= 6.0:
			canvas.draw_circle(path[0],ink_width*0.5,Color("13121c"))
			canvas.draw_circle(path[path.size()-1],ink_width*0.5,Color("13121c"))
			canvas.draw_circle(path[0],width*0.5,color)
			canvas.draw_circle(path[path.size()-1],width*0.5,color)

func _draw_joint_bridges(canvas: Node2D, parts: Dictionary) -> void:
	if _photo_image == null: return
	# The game's rig can stretch farther than the 512 binding pose. Underpaint
	# joins using colors from the original image before any textured cutouts.
	# The final shader then sees one silhouette, not white rings on each piece.
	var bridges := [
		["head","shoulder","head",Vector2(255,155),23.0],
		["shoulder","back_elbow","left_arm",Vector2(215,215),18.0],
		["back_elbow","back_hand","left_arm",Vector2(168,257),18.0],
		["shoulder","front_elbow","right_arm",Vector2(300,215),18.0],
		["front_elbow","front_hand","right_arm",Vector2(342,257),18.0],
		["hip","left_knee","left_leg",Vector2(229,344),20.0],
		["left_knee","left_foot","left_leg",Vector2(201,423),20.0],
		["hip","right_knee","right_leg",Vector2(283,344),20.0],
		["right_knee","right_foot","right_leg",Vector2(311,423),20.0]
	]
	for bridge in bridges:
		if not parts.has(bridge[2]): continue
		var sample: Vector2 = bridge[3]
		var color: Color = _photo_image.get_pixelv(Vector2i(sample))
		if color.a < 0.2: continue
		var start: Vector2 = _posed[bridge[0]]
		var finish: Vector2 = _posed[bridge[1]]
		canvas.draw_line(_viewport_point(start),_viewport_point(finish),color,float(bridge[4])*RENDER_SCALE,true)

func _deform(part: String, point: Vector2, distal: bool = false) -> Vector2:
	var key := part
	if part in ["left_arm","right_arm","left_leg","right_leg"]:
		key += "_distal" if distal else "_proximal"
	if _deform_transforms.has(key): return _deform_transforms[key]*point
	return _canvas_to_local(point)

func _is_distal(part: String, point: Vector2) -> bool:
	var root_key := "shoulder" if part.ends_with("_arm") else "hip"
	var joint_key := "back_elbow" if part == "left_arm" else "front_elbow" if part == "right_arm" else "left_knee" if part == "left_leg" else "right_knee" if part == "right_leg" else ""
	if joint_key.is_empty(): return false
	var root := _vec(_bind[root_key])
	var joint := _vec(_bind[joint_key])
	return (point-joint).dot(joint-root) > 0.0

static func _vec(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() >= 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

static func _canvas_to_local(point: Vector2) -> Vector2:
	return (point - Vector2(256, FEET_Y)) * LOCAL_SCALE

func _viewport_point(point: Vector2) -> Vector2:
	return (point / LOCAL_SCALE + Vector2(256 + canvas_padding_px, FEET_Y + canvas_padding_px)) * RENDER_SCALE
