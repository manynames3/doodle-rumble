extends RefCounted
## Presentation only: custom kits reuse the same articulated body and combat clocks.

static func apply(rig, state: Dictionary, angle: float) -> float:
	if state.get("victory",false) or state.get("defeated",false) or state.get("hurt",false): return angle
	var attack := float(state.get("attack_progress",-1.0))
	if attack < 0:
		if rig.custom_kit == "bat":
			rig.front_hand = rig.shoulder+Vector2(20,0)
			return -1.30
		if rig.custom_kit == "rubber_chicken":
			rig.front_hand = rig.shoulder+Vector2(27,-12)
			return -1.10
		if rig.custom_kit == "giant_crayon":
			rig.front_hand = rig.shoulder+Vector2(24,-18)
			return -1.18
		if rig.custom_kit == "ball": return 0.0
		return angle
	var windup := float(state.get("attack_windup_ratio",0.25))
	var active := float(state.get("attack_active_ratio",0.2))
	var anticipation := clampf(attack/maxf(windup,0.01),0,1)
	var swing := smoothstep(windup,windup+active,attack)
	var recovery := smoothstep(windup+active,1.0,attack)
	var strength := 1.0-recovery
	match rig.custom_kit:
		"bat":
			rig.shoulder.x += lerpf(-8,11,swing)*strength
			rig.head.x += lerpf(-5,9,swing)*strength
			rig.front_hand = rig.shoulder+Vector2(lerpf(8,40,swing),lerpf(-14,7,swing))
			rig.back_hand = rig.front_hand+Vector2(-8,4)
			angle = lerpf(-1.75-anticipation*0.30,0.38,swing)
		"bone":
			rig.front_hand = rig.shoulder+Vector2(lerpf(13,45,swing),lerpf(-15,-4,swing))
			rig.front_elbow = rig.shoulder+Vector2(20,10)
			angle = lerpf(-1.50-anticipation*0.25,0.22,swing)
		"pixel_pick":
			rig.shoulder.x += swing*9*strength
			rig.head.x += swing*7*strength
			rig.front_hand = rig.shoulder+Vector2(28,lerpf(-17,15,swing))
			angle = lerpf(-1.8,0.70,swing)
		"ball":
			rig.shoulder.x -= 7*strength
			rig.head.x -= 8*strength
			rig.right_knee = Vector2(lerpf(-8,20,swing),-22)
			rig.right_foot = Vector2(lerpf(-28,53,swing),lerpf(-3,-15,swing))
			rig.front_hand = rig.shoulder+Vector2(27,-3)
			rig.back_hand = rig.shoulder+Vector2(-34,-10)
			# The ball stays in front of the kicking foot throughout the hit window.
			angle = 0.0
		"rubber_chicken":
			rig.shoulder.x += lerpf(-9,13,swing)*strength
			rig.head.x += lerpf(-4,11,swing)*strength
			rig.front_hand = rig.shoulder+Vector2(lerpf(11,43,swing),lerpf(-23,5,swing))
			rig.back_hand = rig.shoulder+Vector2(lerpf(-20,-29,swing),-6)
			angle = lerpf(-1.75-anticipation*0.38,0.48,swing)
		"giant_crayon":
			rig.shoulder.x += lerpf(-11,15,swing)*strength
			rig.head.x += lerpf(-8,10,swing)*strength
			rig.front_hand = rig.shoulder+Vector2(lerpf(9,46,swing),lerpf(-25,5,swing))
			rig.back_hand = rig.shoulder+Vector2(-29,-10)
			angle = lerpf(-1.92-anticipation*0.32,0.36,swing)
	return lerp_angle(angle,0.0 if rig.custom_kit == "ball" else -0.85,recovery)

static func paint(rig, state: Dictionary) -> void:
	var attack := float(state.get("attack_progress",-1.0))
	if attack < 0 or state.get("defeated",false) or state.get("victory",false): return
	var windup := float(state.get("attack_windup_ratio",0.25))
	var active := float(state.get("attack_active_ratio",0.2))
	if attack < windup or attack > windup+active+0.09: return
	var center: Vector2 = rig.right_foot if rig.custom_kit == "ball" else rig.front_hand
	var tint: Color = rig.accent
	var points := PackedVector2Array()
	var radius := 53.0 if rig.custom_kit == "ball" else 95.0
	for i in range(20):
		var theta := lerpf(-1.6,0.7,float(i)/19.0)
		points.append(center+Vector2.from_angle(theta)*radius)
	rig.draw_polyline(points,Color(tint,0.13),15,true)
	rig.draw_polyline(points,Color("080b19"),5,true)
	rig.draw_polyline(points,tint.lightened(0.5),2.7,true)
	if rig.custom_kit == "rubber_chicken":
		var squeak := PackedVector2Array([center+Vector2(14,-9),center+Vector2(28,-25),center+Vector2(39,-10),center+Vector2(52,-30)])
		rig.draw_polyline(squeak,Color("fff4bf"),9.0,true)
		rig.draw_polyline(squeak,Color("ed8d32"),4.0,true)
	elif rig.custom_kit == "giant_crayon":
		var palette := [Color("ff5369"),Color("ffaf35"),Color("f6ec52"),Color("5cda81"),Color("44c9f4"),Color("ad68ec")]
		for i in palette.size():
			var rainbow := PackedVector2Array([center+Vector2(9,-4+i*2),center+Vector2(35,-28+i*2),center+Vector2(62,-4+i*2),center+Vector2(92,-32+i*2)])
			rig.draw_polyline(rainbow,Color(palette[i],0.78),3.5,true)
