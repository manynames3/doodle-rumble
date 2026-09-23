extends Control
## Illustrated card surface. The parent Button owns input and text labels.
var gallery_mode := false
var fighter_id: String = "orange"
var tint := Color("ff9e28")
var is_selected: bool = false
var texture: Texture2D
var action_texture: Texture2D
var transparent_character_art: bool = false
var elapsed: float = 0.0
var engagement: float = 0.0
var asset_retry: float = 0.0
var was_active: bool = false
var was_reduced: bool = false

func _ready() -> void:
	add_to_group("selection_cards")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	_try_load_art()
	queue_redraw()

func configure(id: String, color: Color, selected: bool) -> void:
	if fighter_id != id:
		texture = null
		action_texture = null
		transparent_character_art = false
	fighter_id = id
	tint = color
	is_selected = selected
	asset_retry = 0.0
	_try_load_art()
	queue_redraw()

func _try_load_art() -> void:
	if texture != null:
		return
	var pack_path: String = "res://assets/character_art/%s/canonical.png" % fighter_id
	texture = _read_texture(pack_path)
	transparent_character_art = texture != null
	action_texture = _read_texture("res://assets/selection/%s_action.png" % fighter_id)
	if texture == null: texture = action_texture
	if texture != null: queue_redraw()
	asset_retry = 1.0

func _read_texture(path: String) -> Texture2D:
	# Exported resources use Godot's importer. Raw PNGs also work during authoring.
	var raw_exists: bool = FileAccess.file_exists(path)
	var has_import: bool = FileAccess.file_exists(path+".import")
	if ResourceLoader.exists(path,"Texture2D") and (has_import or not raw_exists):
		var candidate = load(path)
		if candidate is Texture2D:
			return candidate
	if raw_exists:
		var picture := Image.load_from_file(path)
		if picture != null and not picture.is_empty():
			return ImageTexture.create_from_image(picture)
	return null

func _reduced_motion() -> bool:
	var settings := get_node_or_null("/root/Settings")
	return settings != null and bool(settings.get("reduced_motion"))

func _active() -> bool:
	var button := get_parent() as BaseButton
	return is_selected or (button != null and (button.has_focus() or button.is_hovered()))

func _process(delta: float) -> void:
	if texture == null:
		asset_retry -= delta
		if asset_retry <= 0.0:
			_try_load_art()
	var active: bool = _active()
	var reduced: bool = _reduced_motion()
	var previous: float = engagement
	if reduced:
		engagement = 1.0 if active else 0.0
	else:
		engagement = move_toward(engagement,1.0 if active else 0.0,delta*3.2)
		if active or engagement > 0.0:
			elapsed += delta
	if active != was_active or reduced != was_reduced or not is_equal_approx(previous,engagement) or (active and not reduced):
		queue_redraw()
	was_active = active
	was_reduced = reduced

func _scrim(top: bool, height: float) -> void:
	for i in range(20):
		var fraction: float = float(i)/19.0
		var y: float = float(i)*height/20.0 if top else size.y-height+float(i)*height/20.0
		var opacity: float = lerpf(0.84,0.04,fraction) if top else lerpf(0.02,0.92,fraction)
		draw_rect(Rect2(0,y,size.x,height/20.0+0.5),Color(0.018,0.022,0.045,opacity))

func _sparks() -> void:
	# Every accent stays at the margins, leaving the illustrated fighter unobscured.
	match fighter_id:
		"orange":
			var center := Vector2(size.x*0.50,size.y+11.0)
			for i in range(2):
				var start: float = -2.86+float(i)*1.79+sin(elapsed*0.46)*0.04
				draw_arc(center,size.x*0.55,start,start+0.32,10,Color(tint,engagement*0.40),1.3,true)
		"red":
			for i in range(4):
				var age: float = fposmod(elapsed*0.24+float(i)*0.237,1.0)
				var from := Vector2(size.x*(0.10+float(i)*0.265),size.y-11-age*19)
				var alpha: float = sin(age*PI)*engagement*0.55
				draw_line(from,from+Vector2(-4.0 if i%2 == 0 else 4.0,-9),Color(tint.lightened(0.35),alpha),1.4,true)
		"green":
			for i in range(2):
				var age: float = fposmod(elapsed*0.16+float(i)*0.46,1.0)
				var x: float = 11.0 if i == 0 else size.x-11.0
				var y: float = 44.0+age*maxf(10.0,size.y-104.0)
				var direction: float = 1.0 if i == 0 else -1.0
				var path := PackedVector2Array([Vector2(x,y-10),Vector2(x+direction*5,y-4),Vector2(x+direction*2,y),Vector2(x+direction*7,y+8)])
				draw_polyline(path,Color(tint,sin(age*PI)*engagement*0.50),1.2,true)
		"blue":
			for i in range(4):
				var age: float = fposmod(elapsed*0.18+float(i)*0.24,1.0)
				var x: float = 12.0+float(i%2)*5.0 if i < 2 else size.x-12.0-float(i%2)*5.0
				var center := Vector2(x,43.0+age*maxf(10.0,size.y-96.0))
				var alpha: float = sin(age*PI)*engagement*0.62
				var chunk := PackedVector2Array([center+Vector2(-2,-3),center+Vector2(3,-2),center+Vector2(2,3),center+Vector2(-3,2),center+Vector2(-2,-3)])
				draw_colored_polygon(chunk,Color(tint,alpha*0.30))
				draw_polyline(chunk,Color(tint.lightened(0.35),alpha),1.1,true)


		"purple":
			for i in range(2):
				var age: float = fposmod(elapsed*0.24+float(i)*0.5,1.0)
				draw_arc(Vector2(size.y*0.75,size.y*0.45),10+age*20,-0.65,0.65,12,Color(tint,(1-age)*engagement*0.45),1.3,true)
		"yellow":
			for i in range(3):
				var age: float = fposmod(elapsed*0.20+float(i)*0.31,1.0)
				var at := Vector2(12+float(i)*76,size.y-15-age*18)
				var c := Color(tint,sin(age*PI)*engagement*0.7)
				draw_line(at-Vector2(3,0),at+Vector2(3,0),c,1.3,true)
				draw_line(at-Vector2(0,3),at+Vector2(0,3),c,1.3,true)

func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var reduced: bool = _reduced_motion()
	var active: bool = _active()
	draw_rect(Rect2(Vector2.ZERO,size),Color("121629"))
	if texture != null:
		var dimensions: Vector2 = texture.get_size()
		if transparent_character_art:
			var field: Vector2 = size if gallery_mode else Vector2(size.y,size.y)
			# Keep the original action painting as a dim ink-and-light backdrop.
			# The supplied transparent fighter is the only bright figure on the page.
			if action_texture != null:
				var action_size: Vector2 = action_texture.get_size()
				var cover: float = maxf(field.x/action_size.x,field.y/action_size.y)
				var source_size: Vector2 = field/cover
				var source := Rect2((action_size-source_size)*0.5,source_size)
				draw_texture_rect_region(action_texture,Rect2(Vector2.ZERO,field),source,Color(0.72,0.72,0.79,1.0))
				draw_rect(Rect2(Vector2.ZERO,field),Color(0.015,0.018,0.037,0.35 if gallery_mode else 0.57))
				if gallery_mode:
					# The old poster has its own fighter in the middle. Sink that
					# silhouette into the ink while its energetic edges stay visible.
					draw_circle(field*Vector2(0.51,0.48),field.x*0.34,Color(0.01,0.013,0.027,0.39))
			else:
				draw_rect(Rect2(Vector2.ZERO,field),Color(tint.darkened(0.87)))
			var flare := Vector2(field.x*0.52,field.y*0.63)
			for ring in range(5,0,-1):
				draw_circle(flare,field.x*(0.23+float(ring)*0.095),Color(tint,0.014 if ring > 1 else 0.045))
			for index in range(5):
				var slant := float(index)*field.x/4.0
				draw_line(Vector2(slant-42,field.y),Vector2(slant+50,0),Color(tint,0.12+0.02*float(index%2)),2.0,true)
			# The caption begins at y=134; leave an ink margin below the weapon.
			var art_height: float = field.y-36.0 if gallery_mode else field.y-12.0
			var pulse: float = 1.0 if reduced else 1.0+engagement*(0.018+sin(elapsed*0.8)*0.004)
			var fit: float = minf((field.x-21.0)/dimensions.x,(art_height-9.0)/dimensions.y)*pulse
			var destination := Rect2(Vector2((field.x-dimensions.x*fit)*0.5,(art_height-dimensions.y*fit)*0.5+8.0),dimensions*fit)
			draw_rect(Rect2(8,art_height-7,field.x-16,4),Color(tint,0.22))
			draw_texture_rect(texture,destination,false)
		else:
			var art_size := Vector2(size.x,size.y) if gallery_mode else Vector2(size.y,size.y)
			var cover: float = maxf(art_size.x/dimensions.x,art_size.y/dimensions.y)
			var zoom: float = 1.0 if reduced else 1.0+engagement*(0.014+sin(elapsed*0.42)*0.002)
			var source_size: Vector2 = art_size/(cover*zoom)
			var pan := Vector2.ZERO
			if not reduced:
				pan = Vector2(sin(elapsed*0.31),cos(elapsed*0.27))*dimensions*0.002*engagement
			var source := Rect2((dimensions-source_size)*0.5+pan,source_size)
			draw_texture_rect_region(texture,Rect2(Vector2.ZERO,art_size),source)
		if not active:
			draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.02,0.04,0.07))
	else:
		# A quiet temporary surface is replaced automatically when the asset arrives.
		draw_rect(Rect2(8,8,size.x-16,size.y-16),Color(tint,0.08))
	if not gallery_mode: draw_rect(Rect2(size.y,0,maxf(0,size.x-size.y),size.y),Color("101426"))
	if not gallery_mode: draw_line(Vector2(size.y,12),Vector2(size.y,size.y-12),Color(tint,0.30),1.0,true)
	if active and not reduced:
		_sparks()
	_scrim(true,minf(40.0,size.y*0.30))
	_scrim(false,70.0 if gallery_mode else minf(42.0,size.y*0.30))
	var frame := PackedVector2Array([Vector2(4,7),Vector2(size.x*0.23,4),Vector2(size.x*0.65,5),Vector2(size.x-4,3),Vector2(size.x-5,size.y*0.44),Vector2(size.x-3,size.y-5),Vector2(size.x*0.58,size.y-4),Vector2(size.x*0.22,size.y-6),Vector2(4,size.y-3),Vector2(5,size.y*0.57),Vector2(4,7)])
	draw_polyline(frame,Color("060912"),4.8,true)
	var opacity: float = 0.82 if active else 0.34
	if active and not reduced:
		opacity += sin(elapsed*1.8)*0.09
	draw_polyline(frame,Color(tint,opacity),2.3 if active else 1.2,true)
	if active:
		var edge := tint.lightened(0.56)
		for corner in [Vector2(7,9),Vector2(size.x-7,size.y-9)]:
			var direction: float = 1.0 if corner.x < size.x*0.5 else -1.0
			draw_line(corner,corner+Vector2(17*direction,-1*direction),Color(edge,0.88),1.5,true)
