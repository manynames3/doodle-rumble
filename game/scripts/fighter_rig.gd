extends Node2D
## Shared procedural joint rig. Root drives pose from fixed-step gameplay state.
const FighterPose = preload("res://scripts/fighter_pose.gd")
const WeaponArt = preload("res://scripts/weapon_art.gd")
const CharacterArt = preload("res://scripts/character_art.gd")
const CustomPose = preload("res://scripts/custom_pose.gd")
const INK = Color("060913")
const PAPER = Color("f5f4ff")

class PackedCueOverlay extends Node2D:
	var source: Node2D

	func _draw() -> void:
		if not is_instance_valid(source) or not source.has_packed_art(): return
		var state: Dictionary = source.current
		var art = source.packed_art
		var cue_head: Vector2 = art.visual_head
		if bool(state.get("dodging",false)):
			var alpha: float = 0.70 if bool(state.get("dodge_invulnerable",false)) else 0.25
			for i in range(1 if bool(state.get("reduced_motion",false)) else 3):
				var off := Vector2(-18-i*14,2+i*3)
				var swoosh := PackedVector2Array([cue_head+off+Vector2(-18,-12),Vector2(0,-art.visual_height*0.54)+off+Vector2(-24,0),Vector2(0,-art.visual_height*0.28)+off+Vector2(-17,4)])
				draw_polyline(swoosh,Color(source.accent,alpha/(i+1)),2.4,true)
		if bool(state.get("counter_ready",false)):
			var diamond := PackedVector2Array([cue_head+Vector2(-4,-37),cue_head+Vector2(0,-44),cue_head+Vector2(5,-37),cue_head+Vector2(0,-31),cue_head+Vector2(-4,-37)])
			draw_polyline(diamond,Color("060913"),5.0,true)
			draw_polyline(diamond,Color("fff0ab"),2.0,true)
		if source.fighter_id == "purple" and bool(state.get("shield_guard",false)):
			var shield_center: Vector2 = Vector2(-48,-art.visual_height*0.51)
			var rim: Color = Color("fff0ab") if bool(state.get("shield_perfect",false)) else source.accent.lightened(0.45)
			draw_arc(shield_center,33.0,-2.8,2.8,28,Color(source.accent,0.17),14.0,true)
			draw_arc(shield_center,32.0,-2.8,2.8,28,Color("060913"),5.0,true)
			draw_arc(shield_center,32.0,-2.8,2.8,28,rim,2.5,true)
var fighter_id: String = "orange"
var accent: Color = Color("f39232")
var preview: bool = false
var weapon: Node2D
var packed_art
var custom_art
var custom_kit := ""
var packed_cues: PackedCueOverlay
var elapsed: float = 0.0
var result_age: float = 0.0
var result_kind: String = ""
var phase: float = 0.0
var current: Dictionary = {}
var hip := Vector2(0,-43)
var shoulder := Vector2(0,-76)
var head := Vector2(0,-108)
var left_knee := Vector2(-15,-23)
var left_foot := Vector2(-21,0)
var right_knee := Vector2(11,-22)
var right_foot := Vector2(21,0)
var back_elbow := Vector2(-22,-62)
var back_hand := Vector2(-30,-46)
var front_elbow := Vector2(12,-57)
var front_hand := Vector2(27,-65)
var head_tilt: float = 0.0
var trail: float = -1.0
var opponent_tell: String = ""
var opponent_tell_progress: float = 0.0
var hurt_age: float = 1.0
var was_hurt: bool = false

func _ready() -> void:
	_ensure_weapon()
	pose(0.0,{})

func _ensure_weapon() -> void:
	if weapon == null:
		weapon = WeaponArt.new()
		add_child(weapon)
		weapon.configure("pitchfork",accent)

func configure(definition: Dictionary) -> void:
	if get_node_or_null("ColorSpill") == null:
		var spill = load("res://scripts/fighter_glow.gd").new()
		spill.name = "ColorSpill"
		spill.rig = self
		add_child(spill)
	fighter_id = str(definition.get("id","orange"))
	custom_kit = str(definition.get("kit","")) if bool(definition.get("custom",false)) else ""
	if not custom_kit.is_empty():
		if custom_art == null:
			custom_art = load("res://scripts/custom_art.gd").new()
			custom_art.name = "ChildsDrawing"
			add_child(custom_art)
		custom_art.configure(definition.get("custom_record",{}))
		custom_art.show()
	elif is_instance_valid(custom_art):
		custom_art.hide()
	accent = Color(str(definition.get("color","#f39232")))
	_ensure_weapon()
	var weapon_value = definition.get("weapon","pitchfork")
	var weapon_name: String = str(weapon_value)
	if weapon_value is Dictionary:
		weapon_name = str(weapon_value.get("id",weapon_value.get("type","pitchfork")))
	weapon.configure(weapon_name,accent)
	if packed_art == null:
		packed_art = CharacterArt.new()
		packed_art.name = "PackedCharacterArt"
		add_child(packed_art)
	packed_art.configure(fighter_id)
	if packed_cues == null:
		packed_cues = PackedCueOverlay.new()
		packed_cues.name = "PackedCueOverlay"
		packed_cues.z_index = 4
		packed_cues.source = self
		add_child(packed_cues)
	weapon.visible = fighter_id != "pac_man" and not packed_art.is_rendering()
	queue_redraw()

func has_packed_art() -> bool:
	return packed_art != null and packed_art.is_rendering()

func set_opponent_tell(message: String, progress: float = 0.0) -> void:
	opponent_tell = message
	opponent_tell_progress = clampf(progress,0.0,1.0)
	queue_redraw()

func _process(delta: float) -> void:
	if preview:
		# Keep the menu's facing direction and accessibility settings between frames.
		pose(delta,current if not current.is_empty() else {"grounded":true})

func pose(delta: float, state: Dictionary) -> void:
	current = state
	elapsed += delta
	var next_result: String = "defeated" if bool(state.get("defeated",false)) else "victory" if bool(state.get("victory",false)) else ""
	if next_result != result_kind:
		result_kind = next_result
		result_age = 0.0
	else:
		result_age += delta
	var result_pose: bool = next_result != ""
	# Only explicit cinematic seeks use absolute time. A gameplay result enters
	# through pose(0) too, and must begin its fall or celebration at age zero.
	var cinematic_seek: bool = result_pose and state.has("presentation_time")
	if cinematic_seek:
		result_age = fposmod(float(state["presentation_time"]),5.0)
	var hurting: bool = bool(state.get("hurt",false))
	if hurting and not was_hurt: hurt_age = 0.0
	elif hurting: hurt_age += delta
	was_hurt = hurting
	var velocity: Vector2 = state.get("velocity",Vector2.ZERO)
	var grounded: bool = state.get("grounded",true)
	var reduced: bool = state.get("reduced_motion",false)
	var running: bool = absf(velocity.x) > 25.0 and grounded
	phase += delta * (15.0 if running else 3.1)
	var breathe: float = 0.0 if reduced else sin(phase) * 1.8
	var lean: float = clampf(velocity.x / 55.0,-5.0,5.0) * float(state.get("facing",1))
	var stride: float = sin(phase) * (21.0 if running else 0.0)
	scale.x = -absf(scale.x) if int(state.get("facing",1)) < 0 else absf(scale.x)
	hip = Vector2(lean * 0.3,-43 + breathe)
	shoulder = Vector2(lean,-76 + breathe)
	head = Vector2(lean + (0.0 if reduced else sin(phase * 0.5)),-108 + breathe)
	head_tilt = lean * 0.015
	left_knee = Vector2(-13 + stride * 0.55,-23 + maxf(0.0,stride * 0.3))
	right_knee = Vector2(12 - stride * 0.55,-22 + maxf(0.0,-stride * 0.3))
	left_foot = Vector2(-20 + stride,-maxf(0.0,stride * 0.35))
	right_foot = Vector2(20 - stride,-maxf(0.0,-stride * 0.35))
	back_elbow = shoulder + Vector2(-20,-stride * 0.3 + 13)
	back_hand = back_elbow + Vector2(-9,16)
	front_elbow = shoulder + Vector2(15,18)
	front_hand = shoulder + Vector2(28,11)
	var weapon_angle: float = -0.85 + breathe * 0.013
	var bow_pull: float = 0.0
	var arrow_ready: bool = true
	if fighter_id == "purple":
		front_elbow = shoulder+Vector2(21,19)
		front_hand = shoulder+Vector2(43,14)
		weapon_angle = 0.23+breathe*0.008
	elif fighter_id == "h4ck3r":
		back_elbow = shoulder+Vector2(-24,8)
		back_hand = shoulder+Vector2(-35,22)
		front_elbow = shoulder+Vector2(22,17)
		front_hand = shoulder+Vector2(38,8)
		weapon_angle = -0.13
	elif fighter_id == "dark_lord":
		back_elbow = shoulder+Vector2(-31,17)
		back_hand = shoulder+Vector2(-52,29)
		front_elbow = shoulder+Vector2(27,12)
		front_hand = shoulder+Vector2(42,22)
		weapon_angle = -1.32
	elif fighter_id == "yellow":
		front_elbow = shoulder+Vector2(17,9)
		front_hand = shoulder+Vector2(28,-7)
		back_hand += Vector2(-4,-4)
		weapon_angle = -1.08+breathe*0.015
	weapon_angle = FighterPose.stance(self,state,weapon_angle,breathe,running)
	trail = -1.0
	if not grounded:
		left_knee = hip + Vector2(-21,15)
		left_foot = left_knee + Vector2(-11,13)
		right_knee = hip + Vector2(18,5)
		right_foot = right_knee + Vector2(15,12)
		back_elbow = shoulder + Vector2(-24,5)
		back_hand = back_elbow + Vector2(-11,-13)
		head_tilt = -0.12
		weapon_angle = -1.05
	var attack: float = float(state.get("attack_progress",-1.0))
	var windup: float = float(state.get("attack_windup_ratio",0.20))
	var active: float = float(state.get("attack_active_ratio",0.40))
	var resting_angle: float = weapon_angle
	var resting_hip: Vector2 = hip
	var resting_shoulder: Vector2 = shoulder
	var resting_head: Vector2 = head
	var resting_left_knee: Vector2 = left_knee
	var resting_right_knee: Vector2 = right_knee
	var resting_front: Vector2 = front_hand
	var resting_back: Vector2 = back_hand
	if attack >= 0.0 and not result_pose:
		var swing: float = smoothstep(windup,windup+active,attack)
		var reach: float = sin(swing * PI)
		var anticipation: float = sin(clampf(attack/maxf(windup,0.01),0.0,1.0)*PI*0.5)*10.0 if attack < windup else 0.0
		hip.y += anticipation
		shoulder += Vector2(-anticipation*0.85,anticipation*1.28)
		head += Vector2(-anticipation*1.05,anticipation*1.36)
		left_knee.x -= anticipation*0.22
		right_knee.x += anticipation*0.22
		shoulder.x += reach * 18.0
		head.x += reach * 14.0
		head_tilt += -anticipation*0.011+reach*0.11
		front_hand = shoulder + Vector2(33 + reach * 19.0,7 + swing * 11)
		front_elbow = shoulder + Vector2(23,15)
		back_elbow = shoulder + Vector2(-14,15)
		back_hand = shoulder + Vector2(12,15)
		weapon_angle = lerpf(-1.57,0.8,swing)
		if bool(state.get("special",false)):
			if fighter_id == "orange":
				weapon_angle = lerpf(-1.7,0.6,swing) if reduced else attack * TAU * 2.0 - 1.0
				front_hand = shoulder + Vector2(cos(weapon_angle) * 21.0,sin(weapon_angle) * 10.0)
			elif fighter_id == "green":
				weapon_angle = -0.05
				front_hand.x += 13.0
			elif fighter_id == "red":
				weapon_angle = lerpf(-2.4,1.0,swing)
				front_hand.y += swing * 28.0
		trail = attack if attack >= (windup*0.55 if bool(state.get("special",false)) else windup) and attack < windup+active+0.10 else -1.0
		if fighter_id == "purple":
			var release_point: float = windup
			bow_pull = clampf(attack/release_point,0.0,1.0) if attack < release_point else maxf(0.0,1.0-(attack-release_point)*12.0)
			var recoil: float = sin(clampf((attack-release_point)/0.23,0.0,1.0)*PI)*5.0
			front_hand = shoulder+Vector2(48-recoil,-5)
			front_elbow = shoulder+Vector2(24-recoil,3)
			back_hand = front_hand+Vector2(-23-bow_pull*18,0)
			back_elbow = shoulder+Vector2(-11,12)
			weapon_angle = -0.025-recoil*0.007
			arrow_ready = attack < release_point+0.025 or attack > 0.84
		elif fighter_id == "h4ck3r":
			front_elbow = shoulder+Vector2(25,4)
			front_hand = shoulder+Vector2(43+reach*11,-12)
			back_elbow = shoulder+Vector2(-23,1)
			back_hand = shoulder+Vector2(-32,-19) if bool(state.get("special",false)) else shoulder+Vector2(-35,14)
			weapon_angle = -0.04 if bool(state.get("special",false)) else lerpf(-0.62,0.20,swing)
		elif fighter_id == "yellow" and bool(state.get("special",false)):
			front_elbow = shoulder+Vector2(16,-13)
			front_hand = shoulder+Vector2(25,-32)
			back_elbow = shoulder+Vector2(-17,-11)
			back_hand = shoulder+Vector2(-29,-26)
			head_tilt = -0.08
			weapon_angle = -1.38
	weapon_angle = FighterPose.action(self,state,weapon_angle)
	if attack >= windup+active and attack >= 0 and not result_pose:
		var recover: float = smoothstep(windup+active,1.0,attack)
		weapon_angle = lerp_angle(weapon_angle,resting_angle,recover)
		front_hand = front_hand.lerp(resting_front,recover)
		back_hand = back_hand.lerp(resting_back,recover)
		hip = hip.lerp(resting_hip,recover)
		shoulder = shoulder.lerp(resting_shoulder,recover)
		head = head.lerp(resting_head,recover)
		left_knee = left_knee.lerp(resting_left_knee,recover)
		right_knee = right_knee.lerp(resting_right_knee,recover)
	if bool(state.get("hurt",false)) and not result_pose:
		var recoil: float = 1.0 if reduced else exp(-hurt_age*7.0)
		shoulder += Vector2(-11-12*recoil,5+recoil*3)
		head += Vector2(-16-15*recoil,6+recoil*4)
		head_tilt = -0.20-0.18*recoil
		left_knee.x -= 7*recoil
		right_knee.x += 5*recoil
		front_hand = shoulder + Vector2(20,-3-recoil*9)
		back_hand = shoulder + Vector2(-30,2-recoil*9)
		weapon_angle = -1.3
	if fighter_id == "dark_lord" and not bool(state.get("hurt",false)) and not result_pose:
		var cast: String = str(state.get("boss_cast",""))
		var charge: float = clampf(float(state.get("boss_charge",0.0)),0.0,1.0)
		if cast != "":
			# The sword hand holds the scythe high while the free hand marks the spell.
			front_elbow = shoulder+Vector2(21,-4-charge*8)
			front_hand = shoulder+Vector2(31,-19-charge*13)
			back_elbow = shoulder+Vector2(-22,-4-charge*6)
			back_hand = shoulder+Vector2(-37,-19-charge*9)
			head_tilt = -0.08
			weapon_angle = -1.34
			if cast == "rift" or cast == "quake":
				back_elbow = shoulder+Vector2(-27,23)
				back_hand = shoulder+Vector2(-43,36)
				front_hand = shoulder+Vector2(37,9)
				weapon_angle = -0.42
		elif bool(state.get("boss_guard",false)):
			back_elbow = shoulder+Vector2(-23,5)
			back_hand = shoulder+Vector2(-16,-23)
			front_elbow = shoulder+Vector2(19,-7)
			front_hand = shoulder+Vector2(9,-28)
			weapon_angle = -1.42
	if fighter_id == "h4ck3r" and not bool(state.get("hurt",false)) and not result_pose:
		var command: String = str(state.get("boss_cast",""))
		var command_charge: float = clampf(float(state.get("boss_charge",0.0)),0.0,1.0)
		if command != "" and attack < 0.0:
			# The screen leads the acting. These poses only echo the controller's
			# fixed tell; they never choose or extend a damage window.
			hip.x -= 3.0+command_charge*3.0
			shoulder.x -= 5.0+command_charge*4.0
			head.x -= 7.0+command_charge*4.0
			head_tilt = -0.04-command_charge*0.08
			front_elbow = shoulder+Vector2(22,-2-command_charge*8)
			front_hand = shoulder+Vector2(42,-14-command_charge*10)
			back_elbow = shoulder+Vector2(-20,10)
			back_hand = shoulder+Vector2(-31,4)
			weapon_angle = -0.11-command_charge*0.08
			if command in ["ink_geyser","eraser_drop","firewall_scan"]:
				front_hand = shoulder+Vector2(35,-24-command_charge*12)
				weapon_angle = -0.52
			if command == "checksum_volley":
				back_hand = shoulder+Vector2(-30,-17)
				front_hand = shoulder+Vector2(47,-8)
				weapon_angle = 0.02
	if bool(state.get("victory",false)):
		# Show off after the round: one happy hop, then a clear arm wave and
		# alternating little steps. This only moves painted joints, never the body.
		var salute: float = 0.0 if reduced else sin(result_age*4.5)
		var opening_hop: float = 0.0 if reduced else sin(PI*clampf(result_age/0.52,0.0,1.0))*16.0
		var bounce: float = 0.0 if reduced else maxf(0.0,sin(result_age*5.4))*6.0
		var lift: float = opening_hop+bounce
		hip = Vector2(2+salute*2.0,-47-lift*0.6)
		shoulder = Vector2(7+salute*5.0,-83-lift)
		head = Vector2(10+salute*6.0,-117-lift)
		left_knee = hip+Vector2(-19,20+lift*0.2)
		left_foot = Vector2(-31,-2-lift*0.55)
		right_knee = hip+Vector2(19,18-lift*0.2)
		right_foot = Vector2(30,-2-lift*0.75)
		back_elbow = shoulder+Vector2(-24,-20-salute*5.0)
		back_hand = shoulder+Vector2(-36,-47-salute*8.0)
		front_elbow = shoulder+Vector2(19,-19)
		front_hand = shoulder+Vector2(37,-42+salute*5.0)
		weapon_angle = -1.27+salute*0.18
		head_tilt = -0.10+salute*0.10
		match fighter_id:
			"red":
				shoulder.x -= 7
				head.x -= 11
				front_hand = shoulder+Vector2(35,-35)
				weapon_angle = -1.42
			"green":
				shoulder.x += 7
				head.x += 9
				front_hand = shoulder+Vector2(51,-37)
				weapon_angle = -1.05
			"blue":
				head_tilt = -0.22
				front_hand = shoulder+Vector2(47,-33)
				weapon_angle = -1.38
			"purple":
				back_elbow = shoulder+Vector2(-23,-25)
				back_hand = shoulder+Vector2(-28,-51)
				front_hand = shoulder+Vector2(49,-31)
				weapon_angle = -1.39
			"yellow":
				head.y -= 2
				front_hand = shoulder+Vector2(35,-40)
				weapon_angle = -1.12
	if bool(state.get("defeated",false)):
		hip = Vector2(1,-13)
		shoulder = Vector2(-29,-22)
		head = Vector2(-60,-25)
		head_tilt = -0.6
		left_knee = Vector2(22,-20)
		left_foot = Vector2(43,-7)
		right_knee = Vector2(20,-5)
		right_foot = Vector2(50,-2)
		back_elbow = Vector2(-10,-5)
		back_hand = Vector2(-36,-3)
		front_elbow = Vector2(-17,-13)
		front_hand = Vector2(2,-8)
		# Rest every oversized tool above the floor instead of letting its head sink through it.
		weapon_angle = -0.48
		match fighter_id:
			"red":
				# The hammer fighter folds on one knee before the heavy head settles.
				shoulder = Vector2(-20,-31)
				head = Vector2(-47,-32)
				left_knee = Vector2(-13,-9)
				left_foot = Vector2(-24,-2)
				right_knee = Vector2(25,-14)
				front_hand = Vector2(4,-13)
			"green":
				head = Vector2(-65,-19)
				shoulder = Vector2(-35,-19)
				left_foot = Vector2(38,-2)
				front_hand = Vector2(-4,-10)
			"blue":
				head = Vector2(-44,-32)
				shoulder = Vector2(-17,-26)
				left_knee = Vector2(2,-19)
				left_foot = Vector2(23,-2)
				right_foot = Vector2(38,-2)
			"purple":
				head = Vector2(-53,-30)
				back_hand = Vector2(-31,-12)
				front_hand = Vector2(9,-8)
				weapon_angle = -0.20
			"yellow":
				head = Vector2(-49,-27)
				left_foot = Vector2(34,-2)
				front_hand = Vector2(4,-9)
	elif not reduced and fighter_id not in ["pac_man","dark_lord"]:
		_apply_body_squash(attack,bool(state.get("hurt",false)))
	if fighter_id == "yellow":
		# A smaller drawn silhouette; the shared movement and hurtbox stay unchanged.
		hip *= 0.90
		shoulder *= 0.90
		head *= 0.90
		left_knee *= 0.90
		left_foot *= 0.90
		right_knee *= 0.90
		right_foot *= 0.90
		back_elbow *= 0.90
		back_hand *= 0.90
		front_elbow *= 0.90
		front_hand *= 0.90
	_ensure_weapon()
	weapon.position = front_hand
	if not custom_kit.is_empty():
		weapon_angle = CustomPose.apply(self,state,weapon_angle)
		weapon.position = right_foot+Vector2(14,-10) if custom_kit == "ball" and not result_pose else front_hand
	weapon.rotation = weapon_angle
	weapon.scale = Vector2(0.82,-0.82) if fighter_id == "dark_lord" else Vector2.ONE
	weapon.glowing = attack >= 0.0 and not result_pose and (bool(state.get("special",false)) or fighter_id == "h4ck3r")
	if fighter_id == "h4ck3r": weapon.draw_progress = clampf(attack,0.0,1.0) if attack >= 0.0 else 0.0
	else: weapon.draw_progress = bow_pull
	weapon.arrow_visible = arrow_ready
	weapon.queue_redraw()
	if packed_art != null:
		packed_art.pose(delta,state,phase,result_age if cinematic_seek else -1.0)
		weapon.visible = fighter_id != "pac_man" and not packed_art.is_rendering()
	if is_instance_valid(custom_art) and not custom_kit.is_empty():
		custom_art.pose_from_rig(self,state)
		weapon.z_index = 2
		weapon.visible = not bool(state.get("weapon_hidden",false))
	if packed_cues != null:
		packed_cues.queue_redraw()
	if bool(state.get("invulnerable",false)):
		modulate.a = 0.78 if reduced else (0.64 if fmod(elapsed,0.14) < 0.07 else 1.0)
	else:
		modulate.a = 1.0
	queue_redraw()

func _apply_body_squash(attack: float, hurt: bool) -> void:
	# A restrained pose deformation sells weight without touching the authoritative node scale.
	var width_scale: float = 1.0
	var height_scale: float = 1.0
	if hurt:
		width_scale = 1.055
		height_scale = 0.955
	elif attack >= 0.0:
		if attack < 0.22:
			var gather: float = sin(clampf(attack/0.22,0.0,1.0)*PI*0.5)
			width_scale = 1.0+gather*0.035
			height_scale = 1.0-gather*0.045
		else:
			var release: float = sin(clampf((attack-0.22)/0.43,0.0,1.0)*PI)
			width_scale = 1.0+release*0.055
			height_scale = 1.0-release*0.025
	if is_equal_approx(width_scale,1.0) and is_equal_approx(height_scale,1.0):
		return
	hip = Vector2(hip.x*width_scale,hip.y*height_scale)
	shoulder = Vector2(shoulder.x*width_scale,shoulder.y*height_scale)
	head = Vector2(head.x*width_scale,head.y*height_scale)
	left_knee = Vector2(left_knee.x*width_scale,left_knee.y*height_scale)
	left_foot = Vector2(left_foot.x*width_scale,left_foot.y*height_scale)
	right_knee = Vector2(right_knee.x*width_scale,right_knee.y*height_scale)
	right_foot = Vector2(right_foot.x*width_scale,right_foot.y*height_scale)
	back_elbow = Vector2(back_elbow.x*width_scale,back_elbow.y*height_scale)
	back_hand = Vector2(back_hand.x*width_scale,back_hand.y*height_scale)
	front_elbow = Vector2(front_elbow.x*width_scale,front_elbow.y*height_scale)
	front_hand = Vector2(front_hand.x*width_scale,front_hand.y*height_scale)

func _brush_bone(start: Vector2, finish: Vector2, near_width: float, far_width: float, back: bool) -> void:
	var length: float = start.distance_to(finish)
	if length < 2.0: return
	var axis: Vector2 = (finish-start)/length
	var normal: Vector2 = axis.orthogonal()
	var tint: Color = accent.darkened(0.30) if back else accent
	if bool(current.get("hurt",false)): tint = accent.lightened(0.43)
	# A narrow ink-filled mark bends around its own hand-drawn contour.
	var silhouette := PackedVector2Array([
		start-normal*(near_width+1.6),finish-normal*(far_width+1.2),
		finish+normal*(far_width+1.5),start+normal*(near_width+1.4)
	])
	draw_colored_polygon(silhouette,INK)
	var body := PackedVector2Array([
		start-normal*near_width,finish-normal*far_width,
		finish+normal*far_width,start+normal*near_width
	])
	draw_colored_polygon(body,tint.darkened(0.10))
	var edge := PackedVector2Array([
		start-normal*(near_width+1.3),start.lerp(finish,0.38)-normal*(lerpf(near_width,far_width,0.38)+2.1)+axis*0.7,
		start.lerp(finish,0.70)-normal*(lerpf(near_width,far_width,0.70)+0.7),finish-normal*(far_width+1.8)
	])
	draw_polyline(edge,Color(INK,0.85),1.35,true)
	var hot := PackedVector2Array([
		start.lerp(finish,0.10)-normal*(near_width*0.46),
		start.lerp(finish,0.39)-normal*(lerpf(near_width,far_width,0.39)*0.36)+normal*1.1,
		start.lerp(finish,0.56)-normal*(lerpf(near_width,far_width,0.56)*0.45)
	])
	draw_polyline(hot,Color(tint.lightened(0.72),0.66 if not back else 0.36),1.45,true)
	draw_line(start.lerp(finish,0.68)+normal*0.2,start.lerp(finish,0.89)-normal*(far_width*0.18),Color(tint.lightened(0.50),0.38),1.0,true)
	var nick: Vector2 = start.lerp(finish,0.48)
	draw_line(nick-normal*0.9,nick+normal*1.5+axis*1.8,Color(INK,0.50),1.0,true)

func _limb(points: Array, back: bool = false, leg: bool = false) -> void:
	var broad: float = 5.0 if leg else 4.25
	if fighter_id == "red": broad *= 1.18
	if fighter_id == "green": broad *= 0.93
	if fighter_id == "yellow": broad *= 0.85
	if back: broad *= 0.86
	_brush_bone(points[0],points[1],broad,broad*0.70,back)
	_brush_bone(points[1],points[2],broad*0.76,broad*(0.58 if leg else 0.50),back)
	var joint: Vector2 = points[1]
	var bend: Vector2 = (points[2]-points[0]).normalized().orthogonal()
	draw_line(joint-bend*2.8,joint+bend*2.1,INK,2.1,true)
	draw_line(joint-bend*1.3,joint+bend*1.7,Color(accent.lightened(0.45),0.63 if not back else 0.35),0.9,true)

func _draw_torso() -> void:
	var lean_axis: Vector2 = (hip-shoulder).normalized()
	var side: Vector2 = lean_axis.orthogonal()
	var top_width: float = 7.8
	var waist_width: float = 6.2
	match fighter_id:
		"red": top_width = 9.0; waist_width = 7.0
		"green": top_width = 7.0; waist_width = 5.7
		"blue": top_width = 7.5; waist_width = 6.0
		"purple": top_width = 6.7; waist_width = 5.2
		"yellow": top_width = 6.0; waist_width = 4.8
	var top: Vector2 = shoulder+lean_axis*2.0
	var bottom: Vector2 = hip-lean_axis*1.0
	var shell := PackedVector2Array([top-side*(top_width+2.2),top-lean_axis*1.2+side*(top_width+1.8),top.lerp(bottom,0.52)+side*(waist_width+2.1),bottom+side*(waist_width+1.6),bottom+lean_axis*2.5-side*(waist_width+1.7),top.lerp(bottom,0.42)-side*(top_width+1.6)])
	draw_colored_polygon(shell,INK)
	var fill := PackedVector2Array([top-side*top_width,top+side*top_width,top.lerp(bottom,0.53)+side*waist_width,bottom+side*waist_width,bottom-side*waist_width,top.lerp(bottom,0.45)-side*(top_width-1)])
	draw_colored_polygon(fill,accent.darkened(0.22 if fighter_id == "red" else 0.13))
	# Broken marker highlights retain form without turning the torso into armor.
	draw_line(top-side*(top_width+1.5),top+side*(top_width+1.8),INK,1.6,true)
	var light_mark := PackedVector2Array([top-side*(top_width*0.42),top.lerp(bottom,0.33)-side*(waist_width*0.24)+side*1.2,top.lerp(bottom,0.56)-side*(waist_width*0.34)])
	draw_polyline(light_mark,Color(accent.lightened(0.76),0.64),1.3,true)
	draw_line(top.lerp(bottom,0.70)+side*0.8,bottom+side*(waist_width*0.22),Color(accent.lightened(0.55),0.44),1.0,true)
	for i in range(2):
		var nick: Vector2 = top.lerp(bottom,0.29+float(i)*0.36)+side*(waist_width*0.70)
		draw_line(nick,nick+side*2.1+lean_axis*1.1,Color(INK,0.48),0.9,true)

func _draw_boot(at: Vector2, behind: bool) -> void:
	var tint: Color = accent.darkened(0.33 if behind else 0.16)
	var toe: float = 12.0 if fighter_id == "red" else 9.0
	var sole := PackedVector2Array([at+Vector2(-7,-5),at+Vector2(4,-7),at+Vector2(toe,0),at+Vector2(toe+2,3),at+Vector2(-9,3)])
	draw_colored_polygon(sole,INK)
	var boot := PackedVector2Array([at+Vector2(-5,-4),at+Vector2(4,-5),at+Vector2(toe-1,0),at+Vector2(-7,0)])
	draw_colored_polygon(boot,tint)
	draw_line(at+Vector2(-7,1),at+Vector2(toe+1,1),accent.lightened(0.38),1.2,true)
	draw_line(at+Vector2(0,-4),at+Vector2(5,-3),Color(accent.lightened(0.7),0.72),1.0,true)

func _draw_grip(at: Vector2, elbow: Vector2, behind: bool) -> void:
	var direction: Vector2 = (at-elbow).normalized()
	var side: Vector2 = direction.orthogonal()
	var glove := PackedVector2Array([at-direction*3-side*2.8,at+direction*3.8-side*2.6,at+direction*5+side*1.6,at+direction*1.4+side*3.4,at-direction*3+side*2.4])
	draw_colored_polygon(glove,INK)
	draw_line(at-direction*1.5-side*1.0,at+direction*3+side*0.2,accent.darkened(0.25 if behind else 0.03),1.8,true)
	draw_line(at+direction*3-side*1.3,at+direction*5-side*1.0,Color(accent.lightened(0.65),0.67),0.8,true)

func _head_path(center: Vector2, size: Vector2, tilt: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var seed: float = float(fighter_id.length())*0.61
	for i in range(33):
		var angle: float = TAU * float(i) / 32.0
		var wobble: float = 1.0 + sin(angle * 3.0 + seed) * 0.060 + cos(angle * 7.0 + seed*0.7) * 0.034
		var point := Vector2(cos(angle) * size.x * wobble,sin(angle) * size.y * wobble)
		points.append(center + point.rotated(tilt))
	return points

func _energy(path: PackedVector2Array, width: float = 3.0, opacity: float = 1.0) -> void:
	# Several translucent local passes approximate additive light without a screen flash.
	draw_polyline(path,Color(accent,0.035*opacity),width+38.0,true)
	draw_polyline(path,Color(accent,0.075*opacity),width+23.0,true)
	draw_polyline(path,Color(accent,0.18*opacity),width+11.0,true)
	draw_polyline(path,Color(INK,0.30*opacity),width+2.0,true)
	draw_polyline(path,Color(accent,opacity),width,true)
	draw_polyline(path,Color(accent.lightened(0.86),opacity),maxf(1.15,width*0.30),true)
	# Broken secondary ink gives the arc variable thickness instead of a clean vector edge.
	if path.size() > 7:
		var echo := PackedVector2Array()
		for i in range(1,path.size()-1,3):
			echo.append(path[i]+(path[i]-path[i-1]).normalized().orthogonal()*(width*0.8+float(i%2)))
		if echo.size() > 1:
			draw_polyline(echo,Color(INK,0.24*opacity),0.8,true)

func _sweep(center: Vector2, radii: Vector2, start: float, end: float, offset: float = 0.0) -> PackedVector2Array:
	var path := PackedVector2Array()
	for i in range(49):
		var angle: float = lerpf(start,end,float(i)/48.0)
		var rough: float = 1.0+sin(float(i)*2.8+offset)*0.004
		path.append(center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y)*rough)
	return path

func _energy_ribbon(path: PackedVector2Array, start_width: float, end_width: float, opacity: float = 1.0) -> void:
	if path.size() < 2:
		return
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in range(path.size()):
		var before: Vector2 = path[maxi(0,i-1)]
		var after: Vector2 = path[mini(path.size()-1,i+1)]
		var tangent: Vector2 = (after-before).normalized()
		var normal: Vector2 = tangent.orthogonal()
		var amount: float = lerpf(start_width,end_width,float(i)/float(path.size()-1))
		amount *= 1.0+sin(float(i)*2.37)*0.07
		upper.append(path[i]+normal*amount)
		lower.insert(0,path[i]-normal*amount)
	var shape := PackedVector2Array(upper)
	shape.append_array(lower)
	draw_colored_polygon(shape,Color(accent.lightened(0.12),0.82*opacity))
	shape.append(shape[0])
	draw_polyline(shape,Color(accent,0.055*opacity),26.0,true)
	draw_polyline(shape,Color(INK,0.35*opacity),1.6,true)
	draw_polyline(shape,Color(accent.lightened(0.30),0.85*opacity),1.7,true)
	_energy(path,maxf(2.8,end_width*0.58),opacity)

func _attack_color_spill() -> void:
	# Kept local and low-alpha so attacks light their fighter without washing the arena.
	var attack: float = float(current.get("attack_progress",-1.0))
	if attack < 0.0 or bool(current.get("reduced_motion",false)):
		return
	var strength: float = sin(clampf(attack,0.0,1.0)*PI)
	if strength <= 0.02:
		return
	var center := hip+Vector2(24,-35)
	for i in range(3):
		var radius: float = 66.0+float(i)*27.0
		draw_circle(center,radius,Color(accent,(0.024-float(i)*0.005)*strength))
	var floor_glow := PackedVector2Array([
		Vector2(-105,0),Vector2(-73,-13),Vector2(15,-18),Vector2(108,-7),
		Vector2(145,0),Vector2(57,8),Vector2(-61,7)
	])
	draw_colored_polygon(floor_glow,Color(accent,0.055*strength))

func _block(center: Vector2, size: float, angle: float, color: Color) -> void:
	var corners := PackedVector2Array()
	for point in [Vector2(-0.8,-0.6),Vector2(0.28,-1.0),Vector2(0.94,-0.28),Vector2(0.55,0.85),Vector2(-0.65,0.68)]:
		corners.append(center+point.rotated(angle)*size)
	draw_colored_polygon(corners,color.lightened(0.18) if fighter_id == "blue" else color.darkened(0.54))
	corners.append(corners[0])
	draw_polyline(corners,INK,4.0,true)
	draw_polyline(corners,color,1.6,true)
	draw_line(corners[0],center,Color(color.lightened(0.75),0.95),1.1,true)
	draw_line(center,corners[2],color.lightened(0.35),1.1,true)
	draw_line(center,corners[3],INK,1.4,true)

func _attack_trail() -> void:
	var center := shoulder+Vector2(18,8)
	if fighter_id == "dark_lord":
		if str(current.get("boss_cast","")) not in ["","reaper"]:
			return
		var slash := _sweep(shoulder+Vector2(4,3),Vector2(141,123),-1.76,0.68)
		draw_polyline(slash,Color(accent,0.085),23.0,true)
		draw_polyline(slash,INK,7.0,true)
		for i in range(slash.size()-3):
			if i%4 == 0:
				var root: Vector2 = slash[i]
				var direction: Vector2 = (root-shoulder).normalized()
				draw_line(root,root+direction*(10.0+float(i%3)*4.0),Color(accent,0.72),1.5,true)
		var edge := PackedVector2Array()
		for i in range(0,slash.size(),2): edge.append(slash[i]+Vector2(-3,1))
		draw_polyline(edge,Color(accent.lightened(0.44),0.77),1.7,true)
		return
	if fighter_id == "h4ck3r":
		var origin: Vector2 = front_hand+Vector2(24,-2)
		var end: Vector2 = origin+Vector2(108,-5)
		var signal_line := PackedVector2Array([origin,origin+Vector2(25,-2),origin+Vector2(30,-8),origin+Vector2(56,-8),origin+Vector2(62,-4),end])
		draw_polyline(signal_line,Color(accent,0.09),15.0,true)
		draw_polyline(signal_line,INK,4.0,true)
		draw_polyline(signal_line,Color("d9fff9"),1.7,true)
		for i in range(4):
			var chip: Vector2 = origin+Vector2(19+float(i)*24,-15+float(i%2)*22)
			draw_rect(Rect2(chip,Vector2(3,3)),Color(accent,0.73),true)
		if bool(current.get("special",false)):
			var upper := PackedVector2Array([origin+Vector2(1,-19),origin+Vector2(37,-31),origin+Vector2(52,-18),end+Vector2(10,-29)])
			draw_polyline(upper,Color(accent,0.48),1.5,true)
		return
	if fighter_id == "purple":
		var muzzle := front_hand+Vector2(63,-2)
		if bool(current.get("special",false)):
			_energy(_sweep(muzzle,Vector2(28,73),0.0,TAU),4.2,0.96)
			_energy(_sweep(muzzle+Vector2(12,0),Vector2(18,58),-1.8,2.0),2.0,0.76)
			var signal_path := PackedVector2Array([muzzle-Vector2(28,0),muzzle+Vector2(34,-4),muzzle+Vector2(91,3),muzzle+Vector2(158,-2)])
			_energy_ribbon(signal_path,10.0,2.0,0.92)
			for i in range(6):
				var spark := muzzle+Vector2(4+i*14,-57+i*21)
				draw_line(spark,spark+Vector2(18+float(i%2)*8,0),Color(accent.lightened(0.45),0.84),1.6+float(i%3)*0.35,true)
		else:
			_energy(_sweep(muzzle,Vector2(16,28),-1.35,1.35),1.8,0.72)
			_energy(_sweep(muzzle+Vector2(-9,0),Vector2(12,35),-1.20,1.20),1.1,0.46)
			draw_line(muzzle-Vector2(18,0),muzzle+Vector2(82,0),Color(accent.lightened(0.62),0.72),2.0,true)
		return
	if not bool(current.get("special",false)) and not str(current.get("air_basic_kind","")).is_empty():
		var air_kind: String = str(current.air_basic_kind)
		var air_path: PackedVector2Array
		if air_kind == "fork_sweep":
			air_path = _sweep(hip+Vector2(0,-25),Vector2(138,47),-2.95,2.80)
		elif air_kind == "pick_uppercut":
			air_path = _sweep(shoulder+Vector2(6,0),Vector2(123,119),0.26,-2.0)
		elif air_kind == "diagonal_slash":
			air_path = _sweep(shoulder+Vector2(6,-4),Vector2(140,115),-1.22,0.76)
		elif air_kind == "staff_drop":
			air_path = PackedVector2Array([shoulder+Vector2(16,-39),shoulder+Vector2(56,-5),hip+Vector2(74,32),hip+Vector2(67,67)])
		else:
			air_path = _sweep(shoulder+Vector2(0,9),Vector2(123,137),-1.63,1.23)
		_energy_ribbon(air_path,1.4,7.0,0.82)
		return
	if not bool(current.get("special",false)):
		var slash := _sweep(center,Vector2(162,148),-1.53,0.70)
		_energy_ribbon(slash,1.2,11.0,0.86)
		_energy(_sweep(center+Vector2(-3,2),Vector2(190,173),-1.43,0.48),1.4,0.62)
		for i in range(5):
			var streak_start := center+Vector2(-49-float(i)*13,-66+float(i)*35)
			draw_line(streak_start,streak_start+Vector2(82+float(i%2)*31,-5+float(i%3)*4),Color(accent,0.32),1.0+float(i%3)*0.55,true)
		return
	match fighter_id:
		"yellow":
			var preparing: bool = float(current.get("attack_progress",0.0)) < 0.28/0.96
			if not preparing:
				return
			_energy(_sweep(hip+Vector2(0,-19),Vector2(116,67),0.0,TAU),2.4,0.74)
			_energy(_sweep(hip+Vector2(6,-22),Vector2(154,91),-2.84,-0.18),1.5,0.54)
			var origins := [Vector2(-58,-5),Vector2(-43,-48),Vector2(66,-7)]
			for i in range(3):
				var origin: Vector2 = origins[i]
				var hop: float = sin(trail*PI*2.0+float(i))*4.0
				_tiny_helper(origin+Vector2(0,hop))
				var mote := origin+Vector2(13,-35)
				draw_line(mote-Vector2(3,0),mote+Vector2(3,0),accent.lightened(0.55),1.1,true)
				draw_line(mote-Vector2(0,3),mote+Vector2(0,3),accent.lightened(0.55),1.1,true)
		"orange":
			var spin_center := hip+Vector2(0,-5)
			for i in range(4):
				var start: float = trail*TAU*0.84+float(i)*1.57-0.31
				var arc_length: float = 1.30+float(i%2)*0.13
				var rx: float = 166.0+float((i*3)%4)*12.0
				var ry: float = 53.0+float((i*2)%3)*10.0
				var sweep := PackedVector2Array()
				for j in range(25):
					var t: float = float(j)/24.0
					var theta: float = start+arc_length*t
					var ragged: float = 1.0+sin(float(j)*2.7+float(i)*1.9)*0.011+cos(float(j)*1.13+float(i))*0.007
					sweep.append(spin_center+Vector2(cos(theta)*rx,sin(theta)*ry)*ragged)
				draw_polyline(sweep,Color(accent,0.08),21.0,true)
				# Three nested partial strokes swell in the center and leave torn tips.
				draw_polyline(sweep,Color(INK,0.85),4.4,true)
				draw_polyline(sweep.slice(3,22),Color(INK,0.92),8.2,true)
				draw_polyline(sweep.slice(6,19),Color(INK,0.84),11.0,true)
				draw_polyline(sweep,Color(accent,0.89),2.7,true)
				draw_polyline(sweep.slice(3,22),Color(accent,0.93),5.6,true)
				draw_polyline(sweep.slice(6,19),Color(accent.lightened(0.17),0.88),8.2,true)
				draw_polyline(sweep.slice(4,16),Color(accent.lightened(0.82),0.75),1.25,true)
				var tip: Vector2 = sweep[sweep.size()-1]
				var outward: Vector2 = (tip-spin_center).normalized()
				draw_line(tip,tip+outward*(7.0+float(i%3)*4.0),Color(INK,0.8),1.4,true)
				draw_line(tip+outward*3,tip+outward*(12.0+float(i%3)*4.0),accent.lightened(0.76),1.1,true)
			for i in range(9):
				var angle: float = float(i)*0.72+trail*7.0
				var spark := spin_center+Vector2(cos(angle)*211,sin(angle)*88)
				draw_line(spark,spark+Vector2(-sin(angle)*18,cos(angle)*7),accent.lightened(0.48),1.5+float(i%3)*0.4,true)
		"green":
			_energy_ribbon(_sweep(center,Vector2(177,164),-1.69,0.40),2.0,13.0,0.94)
			_energy(_sweep(center+Vector2(-8,4),Vector2(218,188),-1.40,0.34),2.2,0.72)
			for i in range(6):
				var angle: float = -1.50+float(i)*0.34
				var anchor := center+Vector2(cos(angle)*187,sin(angle)*171)
				var bolt := PackedVector2Array([anchor,anchor+Vector2(12,-13),anchor+Vector2(2,-27),anchor+Vector2(18,-41),anchor+Vector2(10,-64)])
				_energy(bolt,2.2,0.88)
			for i in range(4):
				draw_line(hip+Vector2(-142,-i*22),hip+Vector2(-28,-i*22-6),Color(accent,0.66),1.5+float(i%2),true)
		"red":
			if trail < 0.34:
				_energy_ribbon(_sweep(center,Vector2(176,171),-2.05,-0.12),2.0,12.0,0.83)
				_energy(_sweep(center+Vector2(-2,3),Vector2(211,201),-1.93,-0.35),1.8,0.58)
			else:
				var impact := Vector2(88,-2)
				var punch := PackedVector2Array([impact+Vector2(-112,0),impact+Vector2(-57,-28),impact+Vector2(-82,-91),impact+Vector2(-24,-47),impact+Vector2(-7,-164),impact+Vector2(13,-53),impact+Vector2(78,-126),impact+Vector2(49,-39),impact+Vector2(137,-69),impact+Vector2(98,0)])
				draw_polyline(punch,Color(accent,0.055),38.0,true)
				draw_colored_polygon(punch,Color(accent.lightened(0.20),0.52))
				_energy(punch,3.2,0.90)
				for i in range(6):
					var angle: float = -2.92+float(i)*0.51
					var debris := impact+Vector2.from_angle(angle)*(52.0+float(i%3)*31.0)
					_block(debris,6.0+float(i%3)*3.1,float(i)*0.83,accent.darkened(0.30))
				_energy(PackedVector2Array([impact+Vector2(-137,0),impact+Vector2(-63,-4),impact,impact+Vector2(88,-2),impact+Vector2(166,1)]),5.2,0.96)
				for i in range(5):
					var ray_start := impact+Vector2(-18+float(i)*9,-35-float(i)*18)
					draw_line(ray_start,ray_start+Vector2(81+float(i)*19,-31-float(i)*8),Color(accent.lightened(0.55),0.74),1.3+float(i%2),true)
		"blue":
			var muzzle := front_hand+Vector2(73,-4).rotated(weapon.rotation)
			# The moving fragment owns the long trail; the rig only shows its release flare.
			var muzzle_flash := PackedVector2Array([muzzle-Vector2(18,0),muzzle+Vector2(9,-4),muzzle+Vector2(29,4),muzzle+Vector2(46,-2)])
			_energy_ribbon(muzzle_flash,9.0,1.0,0.90)
			_energy(_sweep(muzzle,Vector2(19,38),-1.62,1.54),1.8,0.66)
			for i in range(4):
				var spark := muzzle+Vector2(4+float(i)*9,-24+float(i)*15)
				draw_line(spark,spark+Vector2(16+float(i%2)*7,0),Color(accent.lightened(0.52),0.72),1.4+float(i%2)*0.6,true)
		_:
			# Keep the two bonus silhouettes' established scale and shape language.
			_energy(_sweep(center,Vector2(101,104),-1.9,1.1),3.5,0.9)
			for i in range(4):
				var angle: float = -1.7+float(i)*0.86
				_block(center+Vector2.from_angle(angle)*111.0,5.0+float(i%2)*3.0,float(i),accent.darkened(0.10))

func _tiny_helper(at: Vector2) -> void:
	var body := PackedVector2Array([at+Vector2(-7,0),at+Vector2(-1,-8),at+Vector2(2,-17),at+Vector2(6,-8),at+Vector2(10,-1)])
	draw_polyline(body,Color(accent,0.12),8.0,true)
	draw_polyline(body,INK,4.5,true)
	draw_polyline(body,accent,2.0,true)
	var arms := PackedVector2Array([at+Vector2(-8,-13),at+Vector2(2,-17),at+Vector2(10,-15)])
	draw_polyline(arms,INK,4.5,true)
	draw_polyline(arms,accent,2.0,true)
	draw_circle(at+Vector2(2,-23),5.4,INK)
	draw_arc(at+Vector2(2,-23),5.4,0.0,TAU,18,accent,1.8,true)

func _purple_shield() -> void:
	var shield_center := back_hand+Vector2(1,-4)
	var shield_size := Vector2(18,23)
	var guarding: bool = bool(current.get("shield_guard",false))
	var perfect: bool = bool(current.get("shield_perfect",false))
	if has_packed_art():
		shield_center = Vector2(-48,-packed_art.visual_height*0.51)
	if guarding:
		if not has_packed_art(): shield_center = back_hand+Vector2(5,-1)
		shield_size = Vector2(21,29)
	elif float(current.get("attack_progress",-1.0)) >= 0.0:
		shield_center = back_elbow+Vector2(-9,9)
	if bool(current.get("defeated",false)):
		shield_center = Vector2(-31,-11)
		shield_size = Vector2(23,9)
	var outline := _head_path(shield_center,shield_size,-0.12)
	draw_polyline(outline,Color(accent,0.22 if guarding else 0.12),17.0 if guarding else 10.0,true)
	draw_colored_polygon(outline,accent.darkened(0.84))
	draw_polyline(outline,INK,6.0,true)
	draw_polyline(outline,accent.lightened(0.48) if perfect else accent,3.6 if guarding else 2.8,true)
	var inner := _head_path(shield_center,shield_size*0.73,-0.12)
	draw_polyline(inner,Color(accent,0.55),1.4,true)
	if guarding:
		var edge := PackedVector2Array()
		for i in range(8,24): edge.append(outline[i]+Vector2(2,-1))
		draw_polyline(edge,Color(accent.lightened(0.8),0.92 if perfect else 0.62),2.4,true)
		for i in range(3):
			var at: Vector2 = shield_center+Vector2(18+float(i)*7,-19+float(i)*15)
			draw_line(at,at+Vector2(6+float(i)*2,-5+float(i)*4),Color(accent.lightened(0.72),0.75 if perfect else 0.39),1.4,true)
	draw_circle(shield_center,4.2,accent.darkened(0.30))
	draw_arc(shield_center,4.2,-2.8,-0.9,8,accent.lightened(0.60),1.2,true)
	for offset in [Vector2(-7,-12),Vector2(7,-11),Vector2(-7,12),Vector2(7,11)]:
		if not bool(current.get("defeated",false)):
			draw_line(shield_center+offset,shield_center+offset+Vector2(3,-1),Color(accent,0.70),1.1,true)

func _pacman_tell_marks(center: Vector2, radius: Vector2, reduced: bool) -> void:
	if opponent_tell == "" or bool(current.get("defeated",false)):
		return
	var charge: float = opponent_tell_progress
	var ink_yellow: Color = Color(accent,0.48+charge*0.37)
	var hot: Color = accent.lightened(0.75)
	# Each warning has a fixed silhouette at reduced motion; only the subtle
	# breathing and chomp animation elsewhere are suppressed.
	match opponent_tell:
		"BITE!":
			var jaw_guide := _sweep(center+Vector2(6,0),Vector2(radius.x+12+charge*11,radius.y+10+charge*10),-0.77,0.77)
			draw_polyline(jaw_guide,INK,5.5,true)
			draw_polyline(jaw_guide,ink_yellow,2.4,true)
			for i in range(3):
				var fang: Vector2 = center+Vector2(53+float(i)*8,-20+float(i)*20)
				draw_line(fang,fang+Vector2(8+charge*5,0),hot,1.5,true)
		"CHARGE!":
			for i in range(3):
				var trail_root: Vector2 = center+Vector2(-radius.x-13-float(i)*15,-22+float(i)*22)
				draw_line(trail_root-Vector2(22+charge*14,0),trail_root,INK,4.0,true)
				draw_line(trail_root-Vector2(22+charge*14,0),trail_root,ink_yellow,1.9,true)
			var rush := PackedVector2Array([center+Vector2(46,-7),center+Vector2(72+charge*22,-7),center+Vector2(63+charge*22,-15),center+Vector2(76+charge*22,-7),center+Vector2(63+charge*22,1)])
			draw_polyline(rush,INK,4.0,true)
			draw_polyline(rush,hot,1.5,true)
		"PELLET SPIT!":
			for i in range(3):
				var lane: float = float(i)-1.0
				var seed: Vector2 = center+Vector2(radius.x+13+charge*10,lane*19)
				draw_circle(seed,7.0,INK)
				draw_arc(seed,6.7,0,TAU,18,ink_yellow,2.2,true)
				draw_circle(seed+Vector2(-1,-2),1.7,hot)
		"HOP CHOMP!":
			var arrow := PackedVector2Array([center+Vector2(48,22),center+Vector2(59,4),center+Vector2(83,-22-charge*12),center+Vector2(76,-21-charge*12),center+Vector2(86,-30-charge*12),center+Vector2(90,-15-charge*12)])
			draw_polyline(arrow,INK,5.0,true)
			draw_polyline(arrow,ink_yellow,2.0,true)
			for i in range(3):
				var hop: Vector2 = center+Vector2(-22+float(i)*19,radius.y+8)
				draw_arc(hop,8.0,-2.8,-0.3,10,ink_yellow,1.5,true)
	if not reduced:
		for i in range(3):
			var t: float = float(i)/3.0
			var arc := _sweep(center,Vector2(radius.x+13+t*12,radius.y+13+t*12),-2.56,2.57)
			draw_polyline(arc,Color(accent,(0.05+charge*0.025)*(1.0-t)),7.0-t*2.0,true)

func _draw_pacman() -> void:
	var reduced: bool = bool(current.get("reduced_motion",false))
	var defeated: bool = bool(current.get("defeated",false))
	var hurt: bool = bool(current.get("hurt",false))
	var velocity: Vector2 = current.get("velocity",Vector2.ZERO)
	var running: bool = absf(velocity.x) > 25.0
	var bob: float = 0.0 if reduced else sin(phase)*(2.0 if running else 0.7)
	var center := Vector2(0,-51+bob)
	var radius := Vector2(41,43)
	var mouth: float = 0.48+(0.0 if reduced else absf(sin(phase))*0.08)
	var attack: float = float(current.get("attack_progress",-1.0))
	var special: bool = bool(current.get("special",false)) and attack >= 0.0
	if not bool(current.get("grounded",true)):
		radius = Vector2(33,48)
		mouth = 0.65
	if opponent_tell != "" and not hurt and not defeated:
		mouth = 0.62+opponent_tell_progress*0.30
		if opponent_tell == "CHARGE!":
			center += Vector2(-4-opponent_tell_progress*4,4)
			radius = Vector2(43,40)
			# A short floor arrow follows the normal facing direction during the tell.
			var arrow := PackedVector2Array([Vector2(44,-5),Vector2(133,-5),Vector2(121,-12),Vector2(133,-5),Vector2(121,2)])
			draw_polyline(arrow,Color(accent,0.20+opponent_tell_progress*0.35),1.8,true)
	if attack >= 0.0:
		if special:
			mouth = 0.91 if attack < 0.24 else 0.58
			if attack >= 0.22 and attack < 0.54:
				center.x += 8
				radius = Vector2(44,40)
				if not reduced:
					for i in range(4):
						var from := center+Vector2(-49-float(i%2)*13,-29+i*18)
						draw_line(from-Vector2(38,0),from,Color(accent,0.68),2.0,true)
		else:
			# Jaw anticipation uses the same .24/.14/.58 bite phases as the data.
			mouth = lerpf(0.49,1.0,clampf(attack/0.25,0.0,1.0)) if attack < 0.25 else lerpf(0.10,0.48,clampf((attack-0.40)/0.60,0.0,1.0))
			center.x += sin(clampf(attack/0.45,0.0,1.0)*PI)*6.0
			if attack >= 0.25 and attack < 0.40 and not reduced:
				for i in range(3):
					var spark := center+Vector2(42+i*13,-18+i*16)
					draw_line(spark,spark+Vector2(10,0),accent.lightened(0.7),1.8,true)
	if hurt:
		center += Vector2(-7,4)
		radius = Vector2(43,40)
		mouth = 0.66
	if bool(current.get("victory",false)):
		center.y -= 3.0+(0.0 if reduced else absf(sin(elapsed*4.5))*8.0)
		mouth = 0.58
	if defeated:
		center = Vector2(-3,-28)
		radius = Vector2(42,26)
		mouth = 0.12
	_pacman_tell_marks(center,radius,reduced)
	draw_set_transform(Vector2(0,3),0,Vector2(1,0.18))
	draw_circle(Vector2.ZERO,38,Color(0.0,0.0,0.02,0.60))
	draw_set_transform(Vector2.ZERO)
	# Little reaching arms sit behind the heavy rounded body.
	if not defeated:
		for side in [-1.0,1.0]:
			var shoulder_nub: Vector2 = center+Vector2(-29,8*side)
			var reach: Vector2 = shoulder_nub+Vector2(-15,7*side)
			draw_polyline(PackedVector2Array([shoulder_nub,reach,reach+Vector2(-5,-3*side)]),INK,6.8,true)
			draw_polyline(PackedVector2Array([shoulder_nub,reach]),accent.darkened(0.15),3.8,true)
			draw_circle(reach+Vector2(-5,-3*side),3.2,accent.lightened(0.27))
	# The shadowed circular back makes the opening a deep black maw.
	draw_set_transform(center,0,Vector2(radius.x/radius.y,1.0))
	draw_circle(Vector2.ZERO,radius.y+1.0,INK)
	draw_set_transform(Vector2.ZERO)
	var body := PackedVector2Array([center+Vector2(-3,2)])
	for i in range(49):
		var angle: float = lerpf(mouth,TAU-mouth,float(i)/48.0)
		var rough: float = 1.0+sin(float(i)*2.31)*0.012
		body.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y)*rough)
	body.append(body[0])
	draw_polyline(body,Color(accent,0.08),18.0,true)
	draw_polyline(body,Color(accent,0.20),10.0,true)
	draw_colored_polygon(body,accent.lightened(0.28) if hurt else accent)
	draw_polyline(body,INK,5.0,true)
	# A smaller crescent of paper-bright pigment and a rough shadow preserve
	# the original yellow cut-paper mass even during a very open chomp.
	draw_arc(center+Vector2(-3,-2),radius.x-7.0,3.65,5.34,19,Color(accent.lightened(0.80),0.72),2.1,true)
	draw_arc(center+Vector2(3,3),radius.x-5.0,1.02,2.58,17,Color(accent.darkened(0.43),0.50),2.8,true)
	# Ink scuffs and uneven reflected edges give the yellow mass some depth.
	for i in range(6):
		var scratch := center+Vector2(-29+float(i%3)*8,-18+float(i/3)*25)
		draw_line(scratch,scratch+Vector2(3+float(i%2)*3,-3),Color(INK,0.34),1.15,true)
		draw_line(scratch+Vector2(3,3),scratch+Vector2(6,0),Color(accent.lightened(0.55),0.50),1.0,true)
	draw_arc(center+Vector2(-4,-1),radius.x-4,1.82,3.90,21,Color(accent.darkened(0.40),0.26),2.5,true)
	var hot_edge := PackedVector2Array()
	for i in range(22,39):
		hot_edge.append(body[i]+Vector2(-0.4,-0.7))
	draw_polyline(hot_edge,accent.lightened(0.85),1.5,true)
	# Irregular little pen echoes keep the round creature in the same drawn world.
	for i in [6,13,20,29,40]:
		var outward := (body[i]-center).normalized()
		draw_line(body[i]+outward*2,body[i+2]+outward*3.5,INK,1.1,true)
	var eye := center+Vector2(2,-radius.y*0.54)
	if defeated:
		draw_line(eye+Vector2(-4,-4),eye+Vector2(4,4),INK,2.5,true)
		draw_line(eye+Vector2(-4,4),eye+Vector2(4,-4),INK,2.5,true)
	elif hurt:
		draw_polyline(PackedVector2Array([eye+Vector2(-5,-3),eye+Vector2(1,0),eye+Vector2(-5,3)]),INK,2.5,true)
	else:
		draw_circle(eye,5.3,INK)
		draw_circle(eye+Vector2(-1.5,-1.5),1.2,PAPER)
		if opponent_tell != "" or special:
			draw_line(eye+Vector2(-7,-9),eye+Vector2(5,-5),INK,2.4,true)
	if not defeated:
		var upper: Vector2 = center+Vector2(cos(mouth)*radius.x,-sin(mouth)*radius.y)
		var lower: Vector2 = center+Vector2(cos(mouth)*radius.x,sin(mouth)*radius.y)
		var hinge: Vector2 = body[0]
		var maw_depth := PackedVector2Array([hinge+Vector2(4,0),upper-Vector2(3,-2),lower-Vector2(3,2)])
		draw_colored_polygon(maw_depth,Color("23130b"))
		draw_polyline(PackedVector2Array([upper,hinge+Vector2(4,0),lower]),Color("8d4c14"),1.6,true)
		for edge in [PackedVector2Array([hinge,upper]),PackedVector2Array([hinge,lower])]:
			draw_polyline(edge,INK,3.6,true)
		for i in range(5):
			var t: float = 0.25+float(i)*0.145
			var up: Vector2 = hinge.lerp(upper,t)
			var down: Vector2 = hinge.lerp(lower,t)
			var width: float = 3.7+float(i%2)
			var depth: float = 6.2+float((i+1)%3)*2.0
			draw_colored_polygon(PackedVector2Array([up+Vector2(-width,-1),up+Vector2(width,0),up+Vector2(1,depth)]),accent.lightened(0.55))
			draw_colored_polygon(PackedVector2Array([down+Vector2(-width,1),down+Vector2(width,0),down+Vector2(1,-depth)]),accent.lightened(0.50))
			draw_line(up+Vector2(-width,-1),up+Vector2(1,depth),INK,1.25,true)
			draw_line(down+Vector2(-width,1),down+Vector2(1,-depth),INK,1.25,true)
	if not defeated:
		# Tiny grounded nubs make its landing point unambiguous without stick limbs.
		for x in [-18.0,17.0]:
			var foot := PackedVector2Array([Vector2(x-7,-7),Vector2(x+5,-8),Vector2(x+8,-1),Vector2(x-8,-1)])
			draw_colored_polygon(foot,accent.darkened(0.25))
			foot.append(foot[0])
			draw_polyline(foot,INK,2.7,true)

func _dark_patch(points: Array, fill: Color, edge: Color = INK) -> void:
	var shape := PackedVector2Array(points)
	draw_colored_polygon(shape,fill)
	shape.append(shape[0])
	draw_polyline(shape,edge,2.4,true)
	# Sparse scratch contours are deliberately uneven and stable across frames.
	for i in range(0,shape.size()-1,3):
		var a: Vector2 = shape[i]
		var b: Vector2 = shape[i+1]
		draw_line(a+Vector2(-1.8,0.5),b+Vector2(1.1,-1.3),INK,1.3,true)

func _dark_bone(start: Vector2, end: Vector2, width: float, back: bool = false) -> void:
	var axis: Vector2 = (end-start).normalized()
	var side: Vector2 = axis.orthogonal()
	var shade := Color("0b0915") if back else Color("090711")
	_dark_patch([start+side*width,start+side*(width+3)+axis*6,end+side*(width*0.55),end+axis*5,end-side*(width*0.72),start-side*(width*0.85)],shade)
	draw_line(start-side*(width*0.24),end-side*(width*0.17),Color(accent,0.49),1.1,true)
	draw_line(start+side*(width*0.70),end+side*(width*0.44),Color(accent,0.25),0.8,true)
	for t in [0.34,0.70]:
		var nick: Vector2 = start.lerp(end,t)
		draw_line(nick-side*(width+2),nick+side*width+axis*3,INK,1.6,true)

func _dark_hand(at: Vector2, direction: Vector2) -> void:
	var axis: Vector2 = direction.normalized()
	var side: Vector2 = axis.orthogonal()
	_dark_patch([at-side*5,at+axis*7-side*4,at+axis*9+side*3,at+side*5],Color("0a0812"))
	for i in range(3):
		var root: Vector2 = at+axis*7+side*(float(i)-1.0)*3.3
		var tip: Vector2 = root+axis*(8.0+float(i%2)*3.0)+side*(float(i)-1.0)*3.5
		draw_line(root,tip,INK,3.4,true)
		draw_line(root,tip,Color(accent,0.70),0.9,true)

func _dark_shard(at: Vector2, size: float, tilt: float) -> void:
	var contour := PackedVector2Array()
	for point in [Vector2(-0.9,-0.45),Vector2(0.05,-1.0),Vector2(0.75,-0.44),Vector2(1.0,0.41),Vector2(0.12,0.92),Vector2(-0.95,0.37)]:
		contour.append(at+point.rotated(tilt)*size)
	draw_colored_polygon(contour,Color("0b0819"))
	contour.append(contour[0])
	draw_polyline(contour,INK,2.2,true)
	draw_polyline(PackedVector2Array([contour[0],contour[1],contour[2]]),Color(accent,0.85),1.5,true)
	draw_line(contour[1],contour[4],Color(accent,0.30),1.0,true)

func _dark_cast_marks(cast: String, charge: float) -> void:
	if cast == "" or bool(current.get("defeated",false)):
		return
	var violet: Color = Color(accent,0.54+charge*0.36)
	var hot: Color = accent.lightened(0.57)
	match cast:
		"quake":
			# The crown points down while angular ground cracks grow underfoot.
			for side in [-1.0,1.0]:
				var start: Vector2 = Vector2(side*(39.0+charge*18.0),-2)
				var crack := PackedVector2Array([start,start+Vector2(side*12,-17),start+Vector2(side*24,-12),start+Vector2(side*41,-27)])
				draw_polyline(crack,INK,5.5,true)
				draw_polyline(crack,violet,1.8,true)
				_dark_shard(crack[3],3.8+charge*2.0,side*0.42)
		"void_orb":
			var focus: Vector2 = back_hand+Vector2(-17,-4)
			var inner: float = 12.0+charge*13.0
			draw_circle(focus,inner+6.0,Color(accent,0.075))
			draw_circle(focus,inner,INK)
			draw_arc(focus,inner,0.10,5.93,31,violet,2.5,true)
			draw_arc(focus,inner*0.58,-2.35,1.95,26,hot,1.1,true)
			for i in range(5):
				var angle: float = float(i)*TAU/5.0+0.18
				var root: Vector2 = focus+Vector2.from_angle(angle)*(inner+4.0)
				_dark_shard(root,3.2+float(i%2)*2.0,angle)
		"eclipse_volley":
			var focus: Vector2 = back_hand+Vector2(-19,-5)
			var radius: float = 14.0+charge*15.0
			for ring in range(3):
				draw_arc(focus,radius+float(ring)*7.0,-2.6+float(ring)*0.38,2.0+float(ring)*0.38,30,Color(accent,0.56-float(ring)*0.12),2.3,true)
			for i in range(7):
				var angle: float = float(i)*TAU/7.0+charge*0.24
				_dark_shard(focus+Vector2.from_angle(angle)*(radius+5.0),4.0+float(i%2)*2.0,angle)
			var tear := PackedVector2Array([focus+Vector2(-3,-radius),focus+Vector2(7,-7),focus+Vector2(-5,4),focus+Vector2(2,radius)])
			draw_polyline(tear,INK,5.5,true)
			draw_polyline(tear,hot,1.8,true)
		"eclipse_wave":
			var span: float = 46.0+charge*75.0
			for side in [-1.0,1.0]:
				var fissure := PackedVector2Array([Vector2(0,-3),Vector2(side*span*0.32,-14),Vector2(side*span*0.51,-6),Vector2(side*span,-24-charge*18.0)])
				draw_polyline(fissure,Color(accent,0.22+charge*0.20),13.0,true)
				draw_polyline(fissure,INK,5.2,true)
				draw_polyline(fissure,violet,2.0,true)
				_dark_shard(fissure[-1],6.0+charge*5.0,side*0.45)
		"void_pillar":
			var gate: Vector2 = back_hand+Vector2(-24,-2)
			var radius: float = 13.0+charge*10.0
			draw_circle(gate,radius+6.0,Color(accent,0.07+charge*0.07))
			draw_arc(gate,radius,0,TAU,32,violet,2.4,true)
			draw_arc(gate,radius*0.66,-2.6,2.3,24,hot,1.5,true)
			for side in [-1.0,1.0]:
				var ray := PackedVector2Array([gate+Vector2(side*4,-radius),gate+Vector2(side*10,-radius*0.25),Vector2(side*(16+charge*10),-7)])
				draw_polyline(ray,Color(accent,0.38+charge*0.44),5.0,true)
				draw_polyline(ray,hot,1.2,true)
		"reaper":
			var base: Vector2 = shoulder+Vector2(4,-3)
			var radius: Vector2 = Vector2(108+charge*40,104+charge*34)
			var warning := _sweep(base,radius,-1.70,0.62)
			draw_polyline(warning,Color(accent,0.08),24.0,true)
			draw_polyline(warning,INK,5.8,true)
			draw_polyline(warning,violet,2.0,true)
			for i in range(5,warning.size()-2,8):
				var root: Vector2 = warning[i]
				draw_line(root,root+(root-base).normalized()*(8+charge*8),hot,1.4,true)
		"rift":
			var center: Vector2 = back_hand+Vector2(-32,-3)
			for i in range(3):
				var offset: float = float(i)-1.0
				var tear := PackedVector2Array([center+Vector2(offset*12,-29),center+Vector2(offset*10-5,-11),center+Vector2(offset*14+4,5),center+Vector2(offset*12-3,24)])
				draw_polyline(tear,INK,7.0,true)
				draw_polyline(tear,violet,2.0,true)
				draw_line(tear[1],tear[2],hot,0.8,true)
		"camera":
			var mark: Vector2 = back_hand+Vector2(-34,-6)
			var corner: float = 16.0+charge*8.0
			for sx in [-1.0,1.0]:
				for sy in [-1.0,1.0]:
					var outer: Vector2 = mark+Vector2(sx*corner,sy*corner)
					draw_line(outer,outer+Vector2(-sx*7,0),violet,2.0,true)
					draw_line(outer,outer+Vector2(0,-sy*7),violet,2.0,true)
			draw_circle(mark,3.0,hot)
			draw_arc(mark,9.0,0.2,TAU+0.2,24,violet,1.1,true)
	# The free hand visibly owns the spell. Reduced motion retains every mark.
	draw_line(back_hand+Vector2(-3,-4),back_hand+Vector2(-16-charge*8,-12),violet,1.8,true)
	draw_circle(back_hand+Vector2(-16-charge*8,-12),2.4,hot)

func _draw_dark_lord() -> void:
	var reduced: bool = bool(current.get("reduced_motion",false))
	var defeated: bool = bool(current.get("defeated",false))
	var cast: String = str(current.get("boss_cast",""))
	var charge: float = clampf(float(current.get("boss_charge",0.0)),0.0,1.0)
	var pulse: float = 0.0 if reduced else sin(elapsed*2.3)*2.0
	if cast == "quake" or cast == "rift":
		# Warning ink stays on the floor so the impending wave is readable.
		var spread: float = 37.0+charge*70.0
		var fissure := PackedVector2Array([Vector2(-spread,-3),Vector2(-spread*0.66,-9),Vector2(-spread*0.36,-4),Vector2(-8,-14),Vector2(12,-5),Vector2(spread*0.43,-12),Vector2(spread,-3)])
		draw_polyline(fissure,Color(accent,0.08+charge*0.12),16.0,true)
		draw_polyline(fissure,INK,5.2,true)
		draw_polyline(fissure,Color(accent,0.55+charge*0.32),1.5,true)
		for i in range(4):
			var crack: Vector2 = Vector2(-spread*0.73+float(i)*spread*0.48,-7)
			draw_line(crack,crack+Vector2(10,-9-float(i%2)*8),Color(accent,0.36+charge*0.42),1.2,true)
	# Two displaced ink wings broaden the ruler-sized final-boss silhouette.
	var cape_left: float = -5.0 if reduced else sin(elapsed*1.35)*4.0
	_dark_patch([shoulder+Vector2(-12,1),shoulder+Vector2(-28,-9),hip+Vector2(-53+cape_left,-5),hip+Vector2(-42+cape_left,15),hip+Vector2(-62+cape_left,22),hip+Vector2(-37,30),hip+Vector2(-23,13)],Color("100a1c"),Color(accent,0.23))
	_dark_patch([shoulder+Vector2(8,1),shoulder+Vector2(25,-7),hip+Vector2(48-cape_left,2),hip+Vector2(38-cape_left,20),hip+Vector2(55-cape_left,25),hip+Vector2(26,28),hip+Vector2(17,12)],Color("110b20"),Color(accent,0.20))
	for wing_root in [shoulder+Vector2(-29,-6),shoulder+Vector2(25,-6)]:
		var sign: float = -1.0 if wing_root.x < shoulder.x else 1.0
		draw_line(wing_root,hip+Vector2(sign*48,8),Color(accent,0.32),1.3,true)
	# Black mantle fans out from a narrow collar into torn, asymmetrical tails.
	var top: Vector2 = shoulder+Vector2(0,4)
	var hem: Vector2 = hip+Vector2(0,5)
	_dark_patch([top+Vector2(-13,-4),top+Vector2(9,-7),top+Vector2(19,2),hem+Vector2(33,17),hem+Vector2(20,13),hem+Vector2(18,36),hem+Vector2(8,21),hem+Vector2(-1,32),hem+Vector2(-9,17),hem+Vector2(-29,35),hem+Vector2(-23,11),hem+Vector2(-39,21),top+Vector2(-23,10)],Color("090711"))
	for i in range(8):
		var from: Vector2 = top+Vector2(-14+float(i)*4.2,4)
		var to: Vector2 = hem+Vector2(-27+float(i)*7.5,15+float((i*3)%4)*4)
		draw_line(from,to,INK,1.3+float(i%3)*0.4,true)
		if i%2 == 0:
			draw_line(from+Vector2(2,2),to+Vector2(1,-3),Color(accent,0.44),0.8,true)
	var breastplate := PackedVector2Array([shoulder+Vector2(-8,10),shoulder+Vector2(2,7),hip+Vector2(6,-5),hip+Vector2(0,4),hip+Vector2(-10,-3)])
	draw_colored_polygon(breastplate,Color("1e1230"))
	breastplate.append(breastplate[0])
	draw_polyline(breastplate,INK,2.4,true)
	draw_polyline(PackedVector2Array([shoulder+Vector2(-5,12),hip+Vector2(1,-7),hip+Vector2(-6,0)]),Color(accent,0.64),1.2,true)
	for i in range(3):
		var seam: Vector2 = shoulder+Vector2(-16+float(i)*10,9)
		draw_line(seam,seam+Vector2(-3+float(i)*2,15),Color(accent,0.30),1.0,true)
	# Stroke density peaks at the joints, but the exposed negative space remains legible.
	_dark_bone(hip,left_knee,5.6,true)
	_dark_bone(left_knee,left_foot,4.4,true)
	_dark_bone(shoulder,back_elbow,5.3,true)
	_dark_bone(back_elbow,back_hand,3.8,true)
	_dark_bone(hip,right_knee,6.1)
	_dark_bone(right_knee,right_foot,4.4)
	_dark_bone(shoulder,front_elbow,5.4)
	_dark_bone(front_elbow,front_hand,4.0)
	for foot in [left_foot,right_foot]:
		_dark_patch([foot+Vector2(-9,1),foot+Vector2(-4,-4),foot+Vector2(7,-3),foot+Vector2(13,2),foot+Vector2(3,3)],Color("090711"))
	_dark_hand(back_hand,(back_hand-back_elbow))
	_dark_hand(front_hand,(front_hand-front_elbow))
	# A rough black ring keeps the sketchbook's hollow head, without a neon halo.
	var contour := PackedVector2Array()
	for i in range(33):
		var theta: float = TAU*float(i)/32.0
		var rough: float = 1.0+sin(theta*7.0+0.6)*0.052+cos(theta*11.0)*0.023
		contour.append(head+Vector2(cos(theta)*23.0*rough,sin(theta)*25.5*rough).rotated(head_tilt))
	draw_polyline(contour,Color(accent,0.08),13,true)
	draw_colored_polygon(contour,Color("03040a"))
	draw_polyline(contour,INK,5.6,true)
	for from in [0,4,10,16,23,28]:
		var arc := PackedVector2Array()
		for j in range(4): arc.append(contour[from+j])
		draw_polyline(arc,Color(accent,0.69 if from%2 == 0 else 0.35),1.7,true)
	for side in [-1.0,1.0]:
		var eye: Vector2 = head+Vector2(side*7.0,-1)
		_dark_patch([eye+Vector2(-2.6,-2),eye+Vector2(1,-1),eye+Vector2(2.4,1),eye+Vector2(-0.5,2.4)],accent.lightened(0.45),accent)
	# The three teeth of the crown sit close to the head, like ink spikes.
	_dark_patch([head+Vector2(-19,-20),head+Vector2(-21,-38),head+Vector2(-11,-30),head+Vector2(-2,-44),head+Vector2(6,-31),head+Vector2(18,-40),head+Vector2(18,-20)],Color("090611"))
	draw_polyline(PackedVector2Array([head+Vector2(-20,-35),head+Vector2(-12,-28),head+Vector2(-2,-42),head+Vector2(6,-30),head+Vector2(17,-38)]),Color(accent,0.86),1.8,true)
	for i in range(4):
		var thorn: Vector2 = shoulder+Vector2(-13+float(i)*10,3)
		draw_line(thorn,thorn+Vector2((float(i)-1.5)*4,-8-float(i%2)*5),INK,2.6,true)
	# Displaced fragments frame the figure; reduced motion locks them in place.
	if not defeated:
		for i in range(7):
			var side: float = -1.0 if i%2 == 0 else 1.0
			var sway: float = 0.0 if reduced else sin(elapsed*(1.5+float(i%3)*0.2)+float(i)*1.7)*3.0
			var at := head+Vector2(side*(39.0+float((i*7)%3)*10.0)+sway,-18.0+float(i)*15.0+pulse)
			_dark_shard(at,3.0+float(i%3)*2.0,float(i)*0.61)
	if cast != "" and not defeated:
		if cast == "void_orb":
			var focus: Vector2 = back_hand+Vector2(-14,-5)
			var size: float = 5.0+charge*9.0
			for ring in range(4):
				draw_arc(focus,size+float(ring)*5.0,0.15+float(ring)*0.9,2.35+float(ring)*0.9,14,Color(accent,0.72-float(ring)*0.13),1.5,true)
			_dark_shard(focus,size*0.65,charge*0.8)
			for i in range(3):
				var spark: Vector2 = focus+Vector2(-22+float(i)*17,-18+float(i%2)*25)
				draw_line(spark,spark+Vector2(4,-6),Color(accent,0.5+charge*0.4),1.2,true)
		elif cast == "reaper":
			var center: Vector2 = shoulder+Vector2(5,-9)
			var radius: float = 60.0+charge*50.0
			var guide := _sweep(center,Vector2(radius,radius*0.80),-1.55,0.18)
			draw_polyline(guide,Color(accent,0.08+charge*0.12),12.0,true)
			for i in range(0,guide.size()-1,5):
				draw_line(guide[i],guide[i]+(guide[i]-center).normalized()*9.0,Color(accent,0.50+charge*0.32),1.1,true)
		elif cast == "rift":
			for i in range(4):
				var point: Vector2 = back_hand+Vector2(-23+float(i)*10,5+float(i%2)*9)
				draw_line(point,point+Vector2(4,-8),Color(accent,0.55+charge*0.34),1.3,true)
	if bool(current.get("boss_guard",false)) and not defeated:
		for i in range(3):
			var path := PackedVector2Array([head+Vector2(-28-float(i)*7,-36),shoulder+Vector2(-38-float(i)*6,-2),hip+Vector2(-27-float(i)*7,9)])
			draw_polyline(path,Color(accent,0.38+float(i)*0.10),1.8,true)
	_dark_cast_marks(cast,charge)
	if bool(current.get("hurt",false)):
		for i in range(3):
			var star: Vector2 = head+Vector2(-21+float(i)*18,-38)
			draw_line(star-Vector2(3,0),star+Vector2(3,0),accent,1.7,true)
			draw_line(star-Vector2(0,3),star+Vector2(0,3),accent,1.7,true)

func _draw() -> void:
	if is_instance_valid(custom_art) and not custom_kit.is_empty():
		_attack_color_spill()
		CustomPose.paint(self,current)
		_draw_result_marks()
		return
	if has_packed_art():
		_attack_color_spill()
		if trail >= 0.0 and not bool(current.get("reduced_motion",false)):
			_attack_trail()
		if fighter_id == "pac_man" and opponent_tell != "":
			_pacman_tell_marks(Vector2(2,-66),Vector2(47,47),bool(current.get("reduced_motion",false)))
		if fighter_id == "h4ck3r" and str(current.get("boss_cast","")) != "":
			_hacker_command_marks(head+Vector2(0,-9),head)
		if fighter_id == "dark_lord":
			_dark_cast_marks(str(current.get("boss_cast","")),float(current.get("boss_charge",0.0)))
		_draw_result_marks()
		return
	if fighter_id == "pac_man":
		_draw_pacman()
		_draw_result_marks()
		return
	_attack_color_spill()
	if trail >= 0.0 and not bool(current.get("reduced_motion",false)):
		_attack_trail()
	if fighter_id == "dark_lord":
		_draw_dark_lord()
		_draw_result_marks()
		return
	if fighter_id == "h4ck3r":
		_draw_hacker()
		_draw_result_marks()
		return
	_draw_motion_cues()
	_limb([hip,left_knee,left_foot],true,true)
	_limb([shoulder,back_elbow,back_hand],true)
	_draw_boot(left_foot,true)
	_draw_grip(back_hand,back_elbow,true)
	if fighter_id == "purple":
		_purple_shield()
	_draw_torso()
	_limb([hip,right_knee,right_foot],false,true)
	_draw_boot(right_foot,false)
	_limb([shoulder,front_elbow,front_hand])
	_draw_grip(front_hand,front_elbow,false)
	var head_size := Vector2(23,24)
	match fighter_id:
		"orange": head_size = Vector2(27,27)
		"green": head_size = Vector2(22,31)
		"red": head_size = Vector2(20,23)
		"blue": head_size = Vector2(24,24)
		"purple": head_size = Vector2(24,25)
		"yellow": head_size = Vector2(19,20)
		"dark_lord": head_size = Vector2(26,28)
	var outline := _head_path(head,head_size,head_tilt - (0.2 if fighter_id == "red" else 0.0))
	draw_polyline(outline,Color(accent,0.06),20.0,true)
	draw_polyline(outline,Color(accent,0.13),12.0,true)
	draw_colored_polygon(outline,INK)
	draw_polyline(outline,INK,10.0,true)
	draw_polyline(outline,accent.darkened(0.18),6.8,true)
	draw_polyline(outline,accent,4.2,true)
	for section in [1,8,15,23,29]:
		var scratch := PackedVector2Array()
		for j in range(3):
			var at: Vector2 = outline[(section+j)%32]
			scratch.append(head+(at-head)*1.08+Vector2(-1.1,0.8))
		draw_polyline(scratch,Color(INK,0.82),1.5,true)
	# Broken hot edge echoes the painted rings in the poster without adding a face.
	var head_edge := PackedVector2Array()
	for i in range(17,27):
		head_edge.append(outline[i]+Vector2(-0.6,-0.5))
	draw_polyline(head_edge,accent.lightened(0.72),1.4,true)
	for i in [2,7,14,19,28]:
		var radial := (outline[i]-head).normalized()
		draw_line(outline[i]+radial*1.5,outline[i]+radial*5.2+Vector2(-1,0),INK,1.3,true)
	if fighter_id == "dark_lord":
		for i in range(3):
			var scribble := _head_path(head+Vector2(float(i)-1.0,0),head_size+Vector2(4+i*2,2+i*3),float(i)*0.74)
			draw_polyline(scribble,INK,2.0,true)
			draw_polyline(scribble,Color(accent,0.60),0.8,true)
		var crown := PackedVector2Array([head+Vector2(-23,-24),head+Vector2(-27,-48),head+Vector2(-13,-37),head+Vector2(-1,-54),head+Vector2(9,-37),head+Vector2(25,-48),head+Vector2(23,-24)])
		draw_colored_polygon(crown,Color("140b24"))
		crown.append(crown[0])
		draw_polyline(crown,Color(accent,0.17),9.0,true)
		draw_polyline(crown,INK,6.5,true)
		draw_polyline(crown,accent,2.5,true)
		draw_line(head+Vector2(-17,-30),head+Vector2(17,-29),accent.lightened(0.45),1.3,true)
		for side in [-1,1]:
			var eye := head+Vector2(side*8.0,1)
			var diamond := PackedVector2Array([eye+Vector2(-2,-3.5),eye+Vector2(2,-1),eye+Vector2(2,2.5),eye+Vector2(-1,4)])
			draw_colored_polygon(diamond,accent.lightened(0.65))
	if fighter_id == "orange":
		var inner := _head_path(head + Vector2(-1,0),Vector2(17,18),head_tilt)
		draw_polyline(inner,Color(accent,0.73),1.8,true)
	draw_arc(head + Vector2(-1,1),head_size.x + 5.0,-2.7,-1.8,8,Color(accent,0.60),1.4,true)
	if fighter_id == "orange" and trail >= 0.0 and bool(current.get("special",false)) and not bool(current.get("reduced_motion",false)):
		for i in range(3):
			var slash := PackedVector2Array([hip+Vector2(-84+i*18,8+i*6),hip+Vector2(-43+i*14,27+i*5),hip+Vector2(21+i*12,30+i*4),hip+Vector2(77+i*9,5+i*3)])
			draw_polyline(slash,Color(accent,0.45),2.6-float(i)*0.4,true)
	if bool(current.get("hurt",false)):
		for i in range(3):
			var star_bob: float = 0.0 if bool(current.get("reduced_motion",false)) else sin(elapsed * 12 + i) * 3
			var star := head + Vector2(-20 + i * 20,-41 + star_bob)
			draw_line(star-Vector2(4,0),star+Vector2(4,0),Color("e3b849"),2.5,true)
			draw_line(star-Vector2(0,4),star+Vector2(0,4),Color("e3b849"),2.5,true)
	_draw_result_marks()

func _draw_motion_cues() -> void:
	var cue_head: Vector2 = packed_art.visual_head if has_packed_art() else head
	var cue_shoulder: Vector2 = Vector2(0,-packed_art.visual_height*0.54) if has_packed_art() else shoulder
	var cue_hip: Vector2 = Vector2(0,-packed_art.visual_height*0.28) if has_packed_art() else hip
	if bool(current.get("dodging",false)):
		var alpha: float = 0.70 if bool(current.get("dodge_invulnerable",false)) else 0.25
		for i in range(1 if bool(current.get("reduced_motion",false)) else 3):
			var off := Vector2(-18-i*14,2+i*3)
			var swoosh := PackedVector2Array([cue_head+off+Vector2(-18,-12),cue_shoulder+off+Vector2(-24,0),cue_hip+off+Vector2(-17,4)])
			draw_polyline(swoosh,Color(accent,alpha/(i+1)),2.4,true)
	if bool(current.get("counter_ready",false)):
		var diamond := PackedVector2Array([cue_head+Vector2(-4,-37),cue_head+Vector2(0,-44),cue_head+Vector2(5,-37),cue_head+Vector2(0,-31),cue_head+Vector2(-4,-37)])
		draw_polyline(diamond,INK,5,true)
		draw_polyline(diamond,Color("fff0ab"),2,true)

func _draw_result_marks() -> void:
	var reduced: bool = bool(current.get("reduced_motion",false))
	if bool(current.get("defeated",false)):
		# Four uneven paper stars orbit just above the fallen head. Reduced motion
		# freezes the same readable constellation in place.
		var fallen_head: Vector2 = packed_art.visual_head if has_packed_art() else Vector2(-3,-28) if fighter_id == "pac_man" else head
		var center: Vector2 = fallen_head+Vector2(0,-51 if fighter_id == "dark_lord" else -43)
		var orbit := _sweep(center,Vector2(38,9),0.0,TAU)
		draw_polyline(orbit,Color("f2d67b",0.22),1.25,true)
		for i in range(4):
			var angle: float = float(i)*TAU/4.0+(-0.58 if reduced else result_age*2.7)
			var at: Vector2 = center+Vector2(cos(angle)*38.0,sin(angle)*9.0)
			var radius: float = 8.0+(2.0 if i%2 == 0 else 0.0)
			var star := PackedVector2Array()
			for point in range(10):
				var tip: float = radius if point%2 == 0 else radius*0.43
				var theta: float = float(point)*PI/5.0-PI/2.0-angle*0.45
				star.append(at+Vector2.from_angle(theta)*tip)
			draw_polyline(star,Color("ffe49a",0.11),9.0,true)
			draw_colored_polygon(star,Color("ffe58e"))
			star.append(star[0])
			draw_polyline(star,INK,1.8,true)
			draw_line(at+Vector2(-1,-2),at+Vector2(1,-3),Color("fff9d7"),1.3,true)
	elif bool(current.get("victory",false)):
		for i in range(3):
			var glint: Vector2 = packed_art.visual_head+Vector2(-26+float(i)*29,-10+float(i%2)*10) if has_packed_art() else back_hand+Vector2(-5+float(i)*14,-16+float(i%2)*10)
			if not reduced: glint += Vector2(0,sin(result_age*5.2+float(i)*2.1)*3.0)
			var size: float = 4.0+float(i%2)*2.0
			draw_line(glint+Vector2(-size,0),glint+Vector2(size,0),INK,3.1,true)
			draw_line(glint+Vector2(0,-size),glint+Vector2(0,size),INK,3.1,true)
			draw_line(glint+Vector2(-size,0),glint+Vector2(size,0),Color("fff0ab"),1.8,true)
			draw_line(glint+Vector2(0,-size),glint+Vector2(0,size),Color("fff0ab"),1.8,true)

func _hacker_panel(points: Array, fill: Color, edge: Color = INK) -> void:
	var shape := PackedVector2Array(points)
	draw_colored_polygon(shape,fill)
	shape.append(shape[0])
	draw_polyline(shape,INK,3.0,true)
	draw_polyline(shape,edge,1.1,true)
	for i in range(0,shape.size()-1,2):
		var a: Vector2 = shape[i]
		var b: Vector2 = shape[i+1]
		var outside: Vector2 = (b-a).normalized().orthogonal()*2.0
		draw_line(a.lerp(b,0.13)+outside,b.lerp(a,0.15)+outside,INK,0.9,true)

func _hacker_link(start: Vector2, finish: Vector2, width: float, back: bool = false) -> void:
	var axis: Vector2 = (finish-start).normalized()
	var normal: Vector2 = axis.orthogonal()
	var body := PackedVector2Array([start+normal*width,start+axis*4+normal*(width+1.5),finish+normal*(width*0.7),finish+axis*2,finish-normal*(width*0.8),start-normal*width])
	draw_colored_polygon(body,Color("101b24") if back else Color("0a1019"))
	body.append(body[0])
	draw_polyline(body,INK,2.7,true)
	draw_line(start-normal*(width*0.35),finish-normal*(width*0.23),Color("d7e4e6") if not back else Color(accent,0.60),1.25,true)
	draw_line(start+normal*(width*0.6),finish+normal*(width*0.4),Color(accent,0.55),0.85,true)
	draw_line(start.lerp(finish,0.40)-normal*(width+1.2),start.lerp(finish,0.62)+normal*(width*0.75),INK,1.0,true)

func _hacker_command_label(command: String) -> String:
	match command:
		"cursor_strike": return "CURSOR>"
		"packet_blast": return "PACKETS>"
		"cursor_stamp": return "STAMP>"
		"ink_geyser": return "INK UP!"
		"eraser_drop": return "ERASE!"
		"checksum_volley": return "CHECK x3"
		"firewall_scan": return "FIREWALL"
	return "H4CK3R"

func _hacker_command_marks(screen: Vector2, eye: Vector2) -> void:
	var command: String = str(current.get("boss_cast",""))
	if command == "" or bool(current.get("defeated",false)):
		return
	var charge: float = clampf(float(current.get("boss_charge",0.0)),0.0,1.0)
	var bright: Color = Color("e7fffb")
	var luminous: Color = Color(accent,0.50+charge*0.38)
	# A hand-drawn progress stroke makes the release legible without blinking.
	var gauge := PackedVector2Array([screen+Vector2(-29,23),screen+Vector2(-29+charge*59.0,23)])
	draw_polyline(gauge,INK,5.0,true)
	draw_polyline(gauge,luminous,2.3,true)
	for i in range(4):
		var tick: Vector2 = screen+Vector2(-29+float(i)*19.5,21)
		draw_line(tick,tick+Vector2(0,5),INK,1.2,true)
	match command:
		"cursor_strike":
			var cursor := PackedVector2Array([front_hand+Vector2(13,-10),front_hand+Vector2(13,19),front_hand+Vector2(21,13),front_hand+Vector2(27,26),front_hand+Vector2(33,23),front_hand+Vector2(27,10),front_hand+Vector2(37,10)])
			draw_colored_polygon(cursor,bright)
			cursor.append(cursor[0])
			draw_polyline(cursor,INK,3.0,true)
			draw_polyline(cursor,luminous,1.0,true)
			for offset in [Vector2(54,-21),Vector2(72,2)]:
				draw_line(front_hand+offset,front_hand+offset+Vector2(14,0),luminous,1.5,true)
		"packet_blast":
			for i in range(3):
				var packet: Vector2 = front_hand+Vector2(29+float(i)*20,-18+float(i%2)*16)
				_hacker_panel([packet+Vector2(-7,-5),packet+Vector2(7,-5),packet+Vector2(7,5),packet+Vector2(-7,5)],Color("071b20"),luminous)
				draw_line(packet+Vector2(-3,0),packet+Vector2(3,0),bright,1.3,true)
				if i < 2: draw_line(packet+Vector2(9,0),packet+Vector2(13,0),luminous,1.4,true)
		"cursor_stamp":
			var target: Vector2 = front_hand+Vector2(63,2)
			draw_arc(target,15.0+charge*6.0,0,TAU,24,luminous,1.8,true)
			for axis in [Vector2.RIGHT,Vector2.DOWN]:
				draw_line(target-axis*26,target-axis*9,bright,1.2,true)
				draw_line(target+axis*9,target+axis*26,bright,1.2,true)
			_hacker_panel([target+Vector2(-5,-5),target+Vector2(5,-5),target+Vector2(5,5),target+Vector2(-5,5)],Color("071820"),luminous)
		"ink_geyser":
			for i in range(4):
				var ink: Vector2 = front_hand+Vector2(25+float(i)*14,8+float(i%2)*5)
				var drip := PackedVector2Array([ink+Vector2(-6,-13),ink+Vector2(5,-16),ink+Vector2(7,1),ink+Vector2(2,8),ink+Vector2(-5,5)])
				draw_colored_polygon(drip,Color("06191c"))
				drip.append(drip[0])
				draw_polyline(drip,INK,2.4,true)
				draw_line(ink+Vector2(-2,-9),ink+Vector2(-2,2),luminous,1.4,true)
		"eraser_drop":
			var block: Vector2 = front_hand+Vector2(55,-38)
			_hacker_panel([block+Vector2(-19,-10),block+Vector2(14,-13),block+Vector2(22,8),block+Vector2(-12,11)],Color("e9e8db"),Color("b0c4c2"))
			draw_line(block+Vector2(-8,-7),block+Vector2(-1,8),luminous,2.1,true)
			for i in range(3):
				var fall: Vector2 = block+Vector2(-8+float(i)*12,17)
				draw_line(fall,fall+Vector2(0,10+charge*8),luminous,1.4,true)
		"checksum_volley":
			for i in range(3):
				var lane: float = float(i)-1.0
				var shard: Vector2 = front_hand+Vector2(38+float(i)*6,lane*23)
				var diamond := PackedVector2Array([shard+Vector2(-8,0),shard+Vector2(0,-7),shard+Vector2(13,0),shard+Vector2(0,7)])
				draw_colored_polygon(diamond,Color("0a2428"))
				diamond.append(diamond[0])
				draw_polyline(diamond,INK,3.3,true)
				draw_polyline(diamond,bright,1.1,true)
				draw_line(shard+Vector2(19,0),shard+Vector2(38+charge*10,lane*5),luminous,1.3,true)
		"firewall_scan":
			var left: float = front_hand.x+44.0
			var top: float = front_hand.y-47.0
			var firewall := PackedVector2Array([Vector2(left,top),Vector2(left+21,top-3),Vector2(left+23,top+91),Vector2(left-1,top+88),Vector2(left,top)])
			if charge < 1.0:
				# The narrow guide is a tell; the solid scan appears on release.
				draw_polyline(firewall,Color(accent,0.16+charge*0.33),1.7,true)
				for i in range(5):
					var y: float = top+7.0+float(i)*18.0
					draw_line(Vector2(left+5,y),Vector2(left+12,y-1),luminous,1.1,true)
			else:
				draw_polyline(firewall,Color(accent,0.10),15.0,true)
				draw_polyline(firewall,INK,6.5,true)
				draw_polyline(firewall,luminous,2.2,true)
				for i in range(6):
					var y: float = top+7.0+float(i)*13.5
					draw_line(Vector2(left+3,y),Vector2(left+19,y-2),bright if i%2 == 0 else luminous,1.4,true)
			for i in range(3):
				var arrow: Vector2 = Vector2(left+35+float(i)*11,front_hand.y)
				draw_line(arrow,arrow+Vector2(7,0),luminous,1.4,true)
	# Camera-lens iris contracts in a steady, readable way for every command.
	draw_arc(eye,28.0+charge*3.0,-0.72,0.65,15,luminous,2.0,true)
	draw_arc(eye,28.0+charge*3.0,2.4,3.8,15,luminous,2.0,true)

func _draw_hacker() -> void:
	var defeated: bool = bool(current.get("defeated",false))
	var hurt: bool = bool(current.get("hurt",false))
	var screen: Vector2 = head+Vector2(-2,-17)
	var eye: Vector2 = shoulder+Vector2(-2,-5)
	# Loose wire loops belong behind the machine and do not blink or jitter.
	var cable := PackedVector2Array([screen+Vector2(-32,9),screen+Vector2(-42,4),shoulder+Vector2(-38,-13),shoulder+Vector2(-33,7),hip+Vector2(-25,-3),hip+Vector2(-19,10)])
	draw_polyline(cable,INK,4.1,true)
	draw_polyline(cable,Color(accent,0.62),1.25,true)
	var second_cable := PackedVector2Array([screen+Vector2(26,18),screen+Vector2(35,28),shoulder+Vector2(28,14),hip+Vector2(21,7)])
	draw_polyline(second_cable,INK,3.3,true)
	draw_polyline(second_cable,Color("c5d5d9"),0.9,true)
	# Exposed black rods and pale plate faces replace the generic neon tubes.
	_hacker_link(hip,left_knee,3.2,true)
	_hacker_link(left_knee,left_foot,2.5,true)
	_hacker_link(hip,right_knee,3.4)
	_hacker_link(right_knee,right_foot,2.7)
	for at in [left_foot,right_foot]:
		_hacker_panel([at+Vector2(-7,2),at+Vector2(-2,-4),at+Vector2(6,-3),at+Vector2(9,2)],Color("d4d8d7"),Color(accent,0.75))
	for at in [left_knee,right_knee]:
		draw_circle(at,4.1,INK)
		draw_circle(at,2.3,Color("b8c9cf"))
	# Split armor has a white sketch-paper highlight and several torn edges.
	_hacker_panel([shoulder+Vector2(-13,3),shoulder+Vector2(10,1),hip+Vector2(14,5),hip+Vector2(4,12),hip+Vector2(-12,9),hip+Vector2(-18,-3)],Color("0b121a"),Color(accent,0.53))
	_hacker_panel([shoulder+Vector2(-6,8),shoulder+Vector2(3,7),hip+Vector2(8,-2),hip+Vector2(0,7),hip+Vector2(-7,0)],Color("e4e4dc"),Color("8ba4a9"))
	draw_line(shoulder+Vector2(8,8),hip+Vector2(10,2),Color(accent,0.70),1.2,true)
	for i in range(3):
		var rib: Vector2 = hip+Vector2(-12+float(i)*8,-6)
		draw_line(rib,rib+Vector2(-3,7),INK,1.6,true)
	_hacker_link(shoulder,back_elbow,2.7,true)
	_hacker_link(back_elbow,back_hand,2.4,true)
	_hacker_link(shoulder,front_elbow,3.0)
	_hacker_link(front_elbow,front_hand,2.4)
	for at in [back_elbow,front_elbow,back_hand,front_hand]:
		draw_circle(at,3.0,INK)
		draw_circle(at,1.5,Color("d9e8e8"))
	# Tiny grasping fingers and a folded note at the free hand.
	for i in range(3):
		var finger: Vector2 = back_hand+Vector2(-3,float(i-1)*2.4)
		draw_line(finger,finger+Vector2(-5,2+float(i-1)*2),INK,2.0,true)
		if i == 1: draw_line(finger,finger+Vector2(-5,2),Color(accent,0.75),0.8,true)
	# CRT is a tilted black sign sitting above, rather than replacing, the eye.
	var bezel := PackedVector2Array([screen+Vector2(-34,-22),screen+Vector2(29,-17),screen+Vector2(32,19),screen+Vector2(-36,16)])
	draw_polyline(bezel,Color(accent,0.085),12.0,true)
	draw_colored_polygon(bezel,Color("0c1920"))
	bezel.append(bezel[0])
	draw_polyline(bezel,INK,6.2,true)
	draw_polyline(bezel,Color(accent,0.88),1.8,true)
	draw_line(screen+Vector2(-37,-24),screen+Vector2(12,-22),INK,1.2,true)
	draw_line(screen+Vector2(29,-20),screen+Vector2(35,9),INK,1.1,true)
	var glass := PackedVector2Array([screen+Vector2(-28,-16),screen+Vector2(23,-12),screen+Vector2(26,12),screen+Vector2(-30,10)])
	draw_colored_polygon(glass,Color("061219"))
	glass.append(glass[0])
	draw_polyline(glass,Color(accent,0.38),0.9,true)
	for i in range(3):
		draw_line(screen+Vector2(-25,-8+float(i)*7),screen+Vector2(22,-4+float(i)*7),Color(accent,0.075),0.65,true)
	var message: String = "OFFLINE" if defeated else _hacker_command_label(str(current.get("boss_cast","")))
	var font = preload("res://assets/fonts/Kalam-Bold.ttf")
	# Counter-mirror the letters while the entire mechanical silhouette turns.
	draw_set_transform(screen,0,Vector2(-1 if scale.x<0 else 1,1))
	draw_string(font,Vector2(-29,4),message,HORIZONTAL_ALIGNMENT_CENTER,58,11 if message != "H4CK3R" else 12,Color("d9fff9"))
	draw_arc(Vector2(0,7),3.2,0.12,PI-0.12,9,Color(accent,0.85),1.2,true)
	draw_set_transform(Vector2.ZERO)
	for i in range(3):
		draw_circle(screen+Vector2(-32,-12+float(i)*8),1.2,Color("ffe7a2") if i == 0 else accent)
	# The lens has multiple offset glass and paper rings; its black center is
	# wider than the monitor lettering, as in the title artwork.
	draw_circle(eye,23.0,INK)
	draw_arc(eye,22.0,0.04,TAU-0.04,48,Color("dae4e0"),3.2,true)
	draw_arc(eye+Vector2(-0.8,0.5),18.6,0.22,5.78,40,Color(accent,0.82),1.8,true)
	draw_circle(eye,14.4,Color("061820"))
	draw_circle(eye+Vector2(1.5,-1.2),9.4,Color("0c3940"))
	draw_circle(eye+Vector2(1.5,-1.2),5.7,Color(accent,0.84))
	draw_circle(eye+Vector2(-1.0,-3.8),3.1,PAPER)
	draw_circle(eye+Vector2(3.4,-1.8),1.25,PAPER)
	for i in range(7):
		var angle: float = -2.8+float(i)*0.56
		var outer: Vector2 = eye+Vector2.from_angle(angle)*25.0
		draw_line(outer,outer+Vector2.from_angle(angle)*3.0,INK,1.2,true)
	_hacker_command_marks(screen,eye)
	if hurt:
		for i in range(2):
			var spark: Vector2 = eye+Vector2(-24+float(i)*45,-22)
			draw_line(spark,spark+Vector2(4,-4),Color("f7eaa9"),1.6,true)
	if float(current.get("attack_progress",-1.0)) >= 0.0 and bool(current.get("special",false)):
		for i in range(3):
			var center: Vector2 = front_hand+Vector2(21+float(i)*13,0)
			draw_arc(center,10+float(i)*5,-1.25,1.25,15,Color(accent,0.53-float(i)*0.12),1.2,true)
