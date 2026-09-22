extends Node2D
## Packed RGBA pose/effect renderer. Fighter physics and attack timing stay in fighter.gd.
var fighter_id: String = ""
var frames: Dictionary = {}
var effects: Dictionary = {}
var pixels_to_local: float = 0.1
var available: bool = false
var body: Sprite2D
var behind: Sprite2D
var in_front: Sprite2D
var debris: Sprite2D
var ground: Sprite2D
var shown_frame: String = ""
var was_running: bool = false
var run_age: float = 0.0
var was_grounded: bool = true
var landing_age: float = 1.0

func _ensure_nodes() -> void:
	if body != null: return
	behind = Sprite2D.new()
	behind.name = "PackSpeedAndSwing"
	behind.z_index = -1
	add_child(behind)
	body = Sprite2D.new()
	body.name = "PackBody"
	body.centered = false
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(body)
	ground = Sprite2D.new()
	ground.name = "PackGroundDust"
	ground.z_index = 1
	add_child(ground)
	debris = Sprite2D.new()
	debris.name = "PackDebris"
	debris.z_index = 2
	add_child(debris)
	in_front = Sprite2D.new()
	in_front.name = "PackImpact"
	in_front.z_index = 3
	add_child(in_front)
	for effect in [behind,ground,debris,in_front]: effect.visible = false

func configure(id: String) -> void:
	_ensure_nodes()
	fighter_id = id
	var file := "res://assets/character_art/%s/art.json" % id
	if not FileAccess.file_exists(file):
		available = false
		visible = false
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not parsed is Dictionary:
		push_warning("Invalid character art manifest: " + file)
		available = false
		visible = false
		return
	var data: Dictionary = parsed
	frames = data.get("frames",{})
	effects = data.get("effects",{})
	pixels_to_local = float(data.get("local_height",145.0)) / maxf(1.0,float(data.get("idle_alpha_height",1200.0)))
	available = frames.has("idle")
	visible = available
	if available: _show_frame("idle")

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path,"Texture2D"):
		var imported = load(path)
		if imported is Texture2D: return imported
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty(): return ImageTexture.create_from_image(image)
	return null

func _show_frame(key: String) -> void:
	if key == shown_frame or not frames.has(key): return
	var frame: Dictionary = frames[key]
	var texture := _load_texture(str(frame.get("path","")))
	if texture == null:
		available = false
		visible = false
		push_warning("Could not load packed pose %s/%s" % [fighter_id,key])
		return
	body.texture = texture
	var offset: Array = frame.get("offset",[0,0])
	body.position = Vector2(float(offset[0]),float(offset[1])) * pixels_to_local
	var factor := pixels_to_local * float(frame.get("source_per_pixel",1.0))
	body.scale = Vector2.ONE * factor
	shown_frame = key

func _set_effect(node: Sprite2D, kind: String, center: Vector2, max_side: float, opacity: float) -> void:
	if not effects.has(kind) or opacity <= 0.0:
		node.visible = false
		return
	var record: Dictionary = effects[kind]
	var path: String = str(record.get("path",""))
	if node.texture == null or node.get_meta("pack_path","") != path:
		node.texture = _load_texture(path)
		node.set_meta("pack_path",path)
	if node.texture == null:
		node.visible = false
		return
	node.visible = true
	node.position = center
	node.scale = Vector2.ONE * max_side / maxf(1.0,maxf(node.texture.get_width(),node.texture.get_height()))
	node.modulate = Color(1,1,1,clampf(opacity,0,1))

func is_rendering() -> bool:
	return available and visible and body != null and body.texture != null

func pose(delta: float, state: Dictionary, phase: float) -> void:
	if not available: return
	var defeated: bool = bool(state.get("defeated",false))
	var victory: bool = bool(state.get("victory",false))
	# The source packs contain no result poses. The existing expressive result rig
	# provides the celebration, fallen body, and orbiting stars in those states.
	visible = not defeated and not victory
	if not visible: return
	var reduced: bool = bool(state.get("reduced_motion",false))
	var velocity: Vector2 = state.get("velocity",Vector2.ZERO)
	var grounded: bool = bool(state.get("grounded",true))
	var running: bool = grounded and absf(velocity.x) > 25.0
	if running:
		run_age = run_age + delta if was_running else 0.0
	else: run_age = 0.0
	if grounded and not was_grounded: landing_age = 0.0
	else: landing_age += delta
	was_running = running
	was_grounded = grounded
	var attack: float = float(state.get("attack_progress",-1.0))
	var windup: float = float(state.get("attack_windup_ratio",0.2))
	var active: float = float(state.get("attack_active_ratio",0.4))
	var special: bool = bool(state.get("special",false))
	var cast: String = str(state.get("boss_cast",""))
	var charge: float = float(state.get("boss_charge",0.0))
	var frame := "idle"
	if not grounded:
		frame = "jump_takeoff" if velocity.y < -180.0 else "jump_apex"
	elif landing_age < 0.15:
		frame = "jump_landing"
	elif running:
		frame = "run_start" if run_age < 0.11 else "run"
	if bool(state.get("dodging",false)): frame = "run_start"
	if bool(state.get("hurt",false)): frame = "attack_recover"
	if attack >= 0.0:
		var heavy: bool = fighter_id == "red" and special
		if attack < windup:
			frame = "heavy_windup" if heavy else "attack_windup"
		elif attack < windup + active:
			if heavy: frame = "heavy_impact"
			elif special: frame = "special_impact"
			elif frames.has("basic_impact"): frame = "basic_impact"
			else: frame = "attack_recover"
		else:
			frame = "attack_recover"
	if cast != "" and fighter_id in ["h4ck3r","dark_lord"]:
		var pack_match: bool = (fighter_id == "h4ck3r" and cast == "firewall_scan") or (fighter_id == "dark_lord" and cast in ["void_orb","rift"])
		frame = "attack_windup" if charge < 0.54 else ("special_impact" if pack_match else "attack_recover")
	_show_frame(frame)
	if not available: return
	# Small visual deformation only. The hitbox, reach, and damage windows never move.
	body.rotation = -0.10 if bool(state.get("hurt",false)) else 0.0
	body.modulate = Color(1.0,0.87,0.87,1.0) if bool(state.get("hurt",false)) else Color.WHITE
	var attack_active: bool = attack >= windup and attack < windup+active and attack >= 0.0
	var burst_age: float = attack-windup
	var boss_burst: bool = cast != "" and charge >= 0.54 and charge < 0.73
	if reduced:
		for node in [behind,ground,debris,in_front]: node.visible = false
		return
	if attack_active:
		_set_effect(behind,"swing_trail",Vector2(35,-87),210.0,0.72 if special else 0.43)
	elif running:
		_set_effect(behind,"speed_lines",Vector2(-38,-77),140.0,0.32)
	else: behind.visible = false
	if landing_age < 0.18:
		_set_effect(ground,"dust",Vector2(0,-6),135.0,0.50*(1.0-landing_age/0.18))
	elif attack_active and special and fighter_id in ["red","blue","pac_man"]:
		_set_effect(ground,"dust",Vector2(43,-3),155.0,0.46)
	else: ground.visible = false
	if (attack_active and burst_age < 0.12) or boss_burst:
		var ground_hit: bool = fighter_id == "red" and special
		_set_effect(in_front,"impact_burst",Vector2(50,-20) if ground_hit else Vector2(77,-84),173.0,0.68)
	else: in_front.visible = false
	if attack_active and special:
		var weight: float = 0.57 if fighter_id in ["red","blue","pac_man","h4ck3r","dark_lord"] else 0.32
		_set_effect(debris,"debris",Vector2(50,-34),155.0,weight)
	else: debris.visible = false
