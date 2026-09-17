extends RefCounted
## Character acting only. The fighter owns every movement and damage window.

static func stance(rig, state: Dictionary, angle: float, breathe: float, running: bool) -> float:
	if not bool(state.get("grounded",true)): return angle
	if running:
		# The planted foot drives the sketch; the shoulders answer a beat later.
		var plant: float = absf(sin(rig.phase))
		rig.hip.y += plant*3.5
		rig.shoulder += Vector2(5.0,plant*2.0)
		rig.head += Vector2(7.0,plant*1.5)
		rig.head_tilt = 0.09
		rig.front_elbow = rig.shoulder+Vector2(20,-1-sin(rig.phase)*9)
		rig.front_hand = rig.shoulder+Vector2(25,12-sin(rig.phase)*13)
		rig.back_elbow = rig.shoulder+Vector2(-21,8+sin(rig.phase)*8)
		rig.back_hand = rig.shoulder+Vector2(-30,18+sin(rig.phase)*12)
		return angle+0.08*sin(rig.phase)
	match rig.fighter_id:
		"orange":
			rig.hip += Vector2(-3,4)
			rig.shoulder += Vector2(3,4)
			rig.head += Vector2(6,3)
			rig.left_knee += Vector2(-7,-2)
			rig.left_foot.x -= 10
			rig.right_knee += Vector2(8,-4)
			rig.right_foot.x += 12
			rig.front_hand = rig.shoulder+Vector2(30,10)
			rig.back_hand = rig.shoulder+Vector2(-30,9)
			angle = -1.02+breathe*0.016
		"red":
			rig.hip += Vector2(-6,5)
			rig.shoulder += Vector2(-7,3)
			rig.head += Vector2(-10,2)
			rig.left_foot.x -= 13
			rig.right_foot.x += 12
			rig.left_knee.x -= 8
			rig.right_knee += Vector2(9,2)
			rig.front_hand = rig.shoulder+Vector2(26,9)
			rig.front_elbow = rig.shoulder+Vector2(11,20)
			angle = -1.18
			rig.back_hand = rig.front_hand+Vector2(20,0).rotated(angle)
			rig.back_elbow = rig.shoulder+Vector2(-15,3)
		"green":
			rig.hip += Vector2(-6,3)
			rig.shoulder += Vector2(8,5)
			rig.head += Vector2(11,5)
			rig.left_foot.x -= 12
			rig.right_foot.x += 20
			rig.right_knee += Vector2(14,3)
			rig.front_hand = rig.shoulder+Vector2(29,6)
			rig.back_hand = rig.shoulder+Vector2(-32,-4)
			angle = -0.36+breathe*0.009
		"blue":
			rig.hip += Vector2(4,1)
			rig.shoulder += Vector2(-5,2)
			rig.head += Vector2(-8,1)
			rig.head_tilt = -0.15
			rig.left_foot.x -= 5
			rig.right_foot.x += 9
			rig.front_hand = rig.shoulder+Vector2(31,21)
			rig.back_hand = rig.shoulder+Vector2(-23,16)
			angle = -1.08
		"purple":
			rig.hip += Vector2(-4,2)
			rig.shoulder += Vector2(-4,0)
			rig.head += Vector2(-6,-1)
			rig.head_tilt = -0.06
			rig.left_knee.x -= 5
			rig.right_knee.x += 4
			rig.left_foot.x -= 9
			rig.right_foot.x += 11
			rig.back_hand = rig.shoulder+Vector2(-25,14)
		"yellow":
			rig.hip += Vector2(3,-2)
			rig.shoulder += Vector2(5,-3)
			rig.head += Vector2(7,-3)
			rig.left_knee += Vector2(-7,-6)
			rig.left_foot += Vector2(-6,-2)
			rig.right_foot.x += 8
			rig.back_hand = rig.shoulder+Vector2(-31,-5)
			angle = -0.86+breathe*0.022
	return angle

static func action(rig, state: Dictionary, angle: float) -> float:
	if bool(state.get("hurt",false)) or bool(state.get("defeated",false)) or bool(state.get("victory",false)): return angle
	var attack: float = float(state.get("attack_progress",-1.0))
	var kind: String = str(state.get("air_basic_kind",""))
	if attack >= 0 and not bool(state.get("special",false)):
		var windup: float = float(state.get("attack_windup_ratio",0.25))
		var active: float = float(state.get("attack_active_ratio",0.36))
		var swing: float = smoothstep(windup,windup+active,attack)
		if kind in ["hammer_drop","staff_drop"]:
			rig.shoulder += Vector2(6,swing*12)
			rig.head += Vector2(8,swing*8)
			rig.front_hand = rig.shoulder+Vector2(15,-21+swing*52)
			angle = lerpf(-1.8,1.20,swing)
			rig.back_hand = rig.front_hand+Vector2(18,0).rotated(angle)
			rig.back_elbow = rig.shoulder+Vector2(-15,4)
		elif kind == "pick_uppercut":
			rig.front_hand = rig.shoulder+Vector2(20,-5-swing*17)
			angle = lerpf(0.6,-1.22,swing)
			rig.back_hand = rig.shoulder+Vector2(-28,3)
		elif kind == "diagonal_slash":
			rig.shoulder.x += 11
			rig.head.x += 14
			rig.front_hand = rig.shoulder+Vector2(33,-4+swing*13)
			angle = lerpf(-0.84,0.60,swing)
			rig.left_foot = rig.hip+Vector2(-39,13)
		elif kind == "fork_sweep":
			rig.front_hand = rig.shoulder+Vector2(29,13)
			angle = lerpf(-2.5,0.45,swing)
			rig.back_hand = rig.shoulder+Vector2(-34,-6)
		elif kind == "aimed_arrow":
			rig.front_hand = rig.shoulder+Vector2(47,-3)
			rig.back_hand = rig.front_hand+Vector2(-34,0)
			angle = 0
		elif rig.fighter_id == "red":
			rig.back_hand = rig.front_hand+Vector2(18,0).rotated(angle)
			rig.back_elbow = rig.shoulder+Vector2(-11,9)
	if bool(state.get("dodging",false)):
		# Low, committed body language makes the brief defensive window readable.
		var tuck: float = 0.76 if bool(state.get("reduced_motion",false)) else sin(clampf(float(state.get("dodge_progress",0.0)),0,1)*PI)
		rig.hip = Vector2(-7,-33+tuck*5)
		rig.shoulder = Vector2(13,-59+tuck*11)
		rig.head = Vector2(27,-83+tuck*11)
		rig.head_tilt = 0.24
		rig.left_knee = Vector2(-26,-22)
		rig.left_foot = Vector2(-41,-3)
		rig.right_knee = Vector2(20,-17)
		rig.right_foot = Vector2(36,-1)
		rig.front_elbow = rig.shoulder+Vector2(5,17)
		rig.front_hand = rig.shoulder+Vector2(24,22)
		rig.back_elbow = rig.shoulder+Vector2(-23,3)
		rig.back_hand = rig.shoulder+Vector2(-37,-5)
		angle = -0.13 if rig.fighter_id == "purple" else -0.48
	if rig.fighter_id == "purple" and bool(state.get("shield_guard",false)):
		var brace: float = clampf(float(state.get("shield_progress",0.0)),0.0,1.0)
		rig.hip += Vector2(-7,5)
		rig.shoulder += Vector2(-10,7)
		rig.head += Vector2(-14,8)
		rig.head_tilt = -0.18
		rig.left_knee += Vector2(-8,-3)
		rig.left_foot += Vector2(-13,0)
		rig.right_knee += Vector2(12,3)
		rig.right_foot += Vector2(11,0)
		rig.back_elbow = rig.shoulder+Vector2(7,5)
		rig.back_hand = rig.shoulder+Vector2(30,-1-brace*4)
		rig.front_elbow = rig.shoulder+Vector2(18,16)
		rig.front_hand = rig.shoulder+Vector2(30,18)
		angle = -0.05
	return angle
