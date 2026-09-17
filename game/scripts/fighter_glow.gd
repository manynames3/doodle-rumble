extends Node2D
## Additive pools light the drawn figure and desk; never participate in combat.
var rig: Node2D

func _ready() -> void:
	z_index = -1
	var light_material := CanvasItemMaterial.new()
	light_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = light_material

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(rig) or rig.current.is_empty(): return
	var state: Dictionary = rig.current
	if bool(state.get("defeated",false)): return
	var attack: float = float(state.get("attack_progress",-1.0))
	var reduced: bool = bool(state.get("reduced_motion",false))
	var charge: float = sin(clampf(attack,0,1)*PI) if attack >= 0 else 0.0
	var color: Color = rig.accent
	if rig.fighter_id == "h4ck3r" and str(state.get("boss_cast","")) != "":
		var command_charge: float = clampf(float(state.get("boss_charge",0.0)),0.0,1.0)
		var strength: float = 0.62+command_charge*0.38
		# The monitor and handheld tablet are the light sources for the command.
		for source in [rig.head+Vector2(-2,-17),rig.front_hand+Vector2(5,0)]:
			for i in range(12):
				var t: float = float(i)/12.0
				draw_circle(source,lerpf(67,4,t),Color(color,(0.006+command_charge*0.007)*strength*t*t))
		if bool(state.get("grounded",false)):
			draw_set_transform(Vector2(0,-2),0,Vector2(1.60,0.17))
			for i in range(9):
				var t: float = float(i)/9.0
				draw_circle(Vector2.ZERO,lerpf(65,6,t),Color(color,0.013*strength*t*t))
			draw_set_transform(Vector2.ZERO)
		return
	if rig.fighter_id == "dark_lord":
		var cast_charge: float = clampf(float(state.get("boss_charge",0.0)),0.0,1.0)
		var enraged: bool = bool(state.get("boss_enraged",false))
		var intensity: float = 0.75+cast_charge*0.45+(0.22 if enraged else 0.0)
		# Several uneven local pools suggest torn violet ink spilling into the page.
		for center in [Vector2(-23,-45),Vector2(14,-82),Vector2(30,-37)]:
			for i in range(12):
				var t: float = float(i)/12.0
				draw_circle(center,lerpf(68,6,t),Color(color,(0.008+cast_charge*0.007)*intensity*t*t))
		if bool(state.get("grounded",false)):
			draw_set_transform(Vector2(0,-2),0,Vector2(2.15,0.20))
			for i in range(13):
				var t: float = float(i)/13.0
				draw_circle(Vector2.ZERO,lerpf(68,5,t),Color(color,0.020*intensity*t*t))
			draw_set_transform(Vector2.ZERO)
		return
	var strength: float = 0.010 + charge * (0.011 if reduced else 0.030)
	# Nested low-opacity circles approximate a soft radial falloff with no texture dependency.
	draw_set_transform(Vector2(15,-70),0,Vector2(1.1,0.92))
	for i in range(18):
		var t: float = float(i)/18.0
		draw_circle(Vector2.ZERO,lerpf(145,12,t),Color(color,strength*t*t))
	if charge > 0.02:
		# The glow follows the hand that actually carries the tool.
		draw_set_transform(rig.front_hand,0,Vector2(1.26,0.88))
		for i in range(10):
			var t: float = float(i)/10.0
			draw_circle(Vector2.ZERO,lerpf(66,5,t),Color(color,(0.013 if reduced else 0.027)*charge*t*t))
	if bool(state.get("grounded",false)):
		draw_set_transform(Vector2(0,-2),0,Vector2(1.8,0.22))
		for i in range(14):
			var t: float = float(i)/14.0
			draw_circle(Vector2.ZERO,lerpf(76,5,t),Color(color,(0.018+charge*0.025)*t*t))
	draw_set_transform(Vector2.ZERO)
