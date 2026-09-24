extends Control
## Live special demonstration uses the real visual rig, never a damaging fighter.
const Rig = preload("res://scripts/fighter_rig.gd")
var rig
var kit_preview
var definition: Dictionary
var clock := 0.0
var tint := Color.WHITE
var trail: Array[Vector2] = []
const PRESENTATION_SCALE := 0.69
const PRESENTATION_TOP := 105.0
const ART_TOP := 85.0
const ART_BOTTOM := 347.0
# Each offset centers the whole attack envelope, not just the idle fighter.
# Keep these fixed through a cycle so the selection art never zooms or pans.
const PRESENTATION_X := {
	"orange": 52.0, "red": 40.0, "green": 40.0,
	"blue": 16.0, "purple": 30.0, "yellow": 51.0
}
# The three swinging tools point below their fighter's feet during part of a
# special. Foreshorten only the tool around its hand so its full head remains
# visible above the caption while the character keeps a substantial scale.
const SWINGING_TOOL_BOUNDS := {
	"orange": Rect2(-20,-37,128,70),
	"red": Rect2(-18,-43,121,88),
	"blue": Rect2(-20,-42,108,84)
}
var art_clip: Control
var presentation_x := 52.0
var presentation_scale := PRESENTATION_SCALE
var presentation_baseline := PRESENTATION_TOP+343.0*PRESENTATION_SCALE

func configure(id: String) -> void:
	definition = Data.fighter(id)
	tint = Color(definition.color)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	presentation_x = float(PRESENTATION_X.get(id,52.0))
	presentation_scale = 0.62 if id == "red" else PRESENTATION_SCALE
	presentation_baseline = 338.0 if id == "red" else PRESENTATION_TOP+343.0*PRESENTATION_SCALE
	art_clip = Control.new()
	art_clip.position = Vector2(0,ART_TOP)
	art_clip.size = Vector2(size.x,ART_BOTTOM-ART_TOP)
	art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_clip.clip_contents = true
	add_child(art_clip)
	rig = Rig.new()
	art_clip.add_child(rig)
	rig.configure(definition)
	rig.scale = Vector2.ONE * (2.0*presentation_scale)
	rig.position = Vector2(presentation_x+220.0*presentation_scale,presentation_baseline-ART_TOP)
	rig.preview = false
	if bool(definition.get("custom",false)):
		kit_preview = load("res://scripts/custom_kit_preview.gd").new()
		art_clip.add_child(kit_preview)
		kit_preview.position = rig.position
		kit_preview.scale = rig.scale

func _process(delta: float) -> void:
	if not is_instance_valid(rig): return
	clock += delta
	var t: float = fposmod(clock,4.4)
	var progress: float = clampf((t-1.5)/1.3,0,1) if t >= 1.5 and t <= 2.8 else -1
	if Settings.reduced_motion: progress = 0.5
	rig.pose(delta,{"grounded":true,"facing":1,"reduced_motion":Settings.reduced_motion,"attack_progress":progress,"special":true,"attack_windup_ratio":0.27,"attack_active_ratio":0.42})
	if is_instance_valid(kit_preview):
		kit_preview.present(str(definition.kit),progress,rig.front_hand,Settings.reduced_motion)
		if str(definition.kit) in ["bone","ball"]:
			rig.weapon.visible = not (progress>0.28 and progress<0.94)
	# Combat trails are arena-sized. The fighter and weapon retain their real
	# special pose; the page draws an equivalent trail at preview scale below.
	rig.trail = -1.0
	# The rig's arena-sized light pools extend beyond this page. Its packed
	# special frame is already chosen, so suppress only the extra rig glow.
	if rig.has_packed_art():
		rig.current["attack_progress"] = -1.0
		for effect in [rig.packed_art.behind,rig.packed_art.ground,rig.packed_art.debris,rig.packed_art.in_front]:
			effect.visible = false
	_fit_swinging_tool()
	rig.queue_redraw()
	queue_redraw()

func _fit_swinging_tool() -> void:
	var id: String = str(definition.get("id",""))
	if not SWINGING_TOOL_BOUNDS.has(id): return
	if id == "red":
		# Keep the heavy strike near horizontal as it reaches the page floor.
		# The shockwave communicates the downward impact without burying the head.
		rig.weapon.rotation = minf(rig.weapon.rotation,0.05)
	var bounds: Rect2 = SWINGING_TOOL_BOUNDS[id]
	var pivot_y: float = ART_TOP+rig.position.y+rig.front_hand.y*rig.scale.y
	var low := INF
	var high := -INF
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			var point: Vector2 = Vector2(x,y).rotated(rig.weapon.rotation)
			low = minf(low,point.y)
			high = maxf(high,point.y)
	var fit := 1.0
	if low < 0.0: fit = minf(fit,(pivot_y-ART_TOP-8.0)/(-low*rig.scale.y))
	if high > 0.0: fit = minf(fit,(ART_BOTTOM-pivot_y-8.0)/(high*rig.scale.y))
	rig.weapon.scale = Vector2.ONE*clampf(fit,0.35,1.0)
	rig.weapon.queue_redraw()

func _draw() -> void:
	# A quiet ink floor stays below the fighter yet clears the footer at y=350.
	# Keep contact grounding without drawing a bright character-colored rule
	# through the feet on the selection card.
	draw_colored_polygon(PackedVector2Array([Vector2(15,335),Vector2(size.x-18,335),Vector2(size.x-13,346),Vector2(12,346)]),Color("111527"))
	var shadow_center := Vector2(presentation_x+220.0*presentation_scale,342.0)
	var shadow := PackedVector2Array()
	for i in range(18):
		var angle := TAU*float(i)/18.0
		shadow.append(shadow_center+Vector2(cos(angle)*58.0,sin(angle)*3.8))
	draw_colored_polygon(shadow,Color("050914",0.56))
	shadow.append(shadow[0])
	draw_polyline(shadow,Color("050914",0.70),1.2,true)
	# A faint sketch of the special is always visible, so the selected fighter
	# reads as an action poster even between demonstrations. It brightens only
	# during the actual special; reduced motion gets one steady illustrated pose.
	var t: float = fposmod(clock,4.4)
	var striking: bool = t >= 1.95 and t <= 3.1
	var age: float = clampf((t-1.95)/1.15,0.0,1.0) if striking else 0.35
	if Settings.reduced_motion: age = 0.35
	var energy: float = (1.0-age)*0.7 if striking else 0.25
	if Settings.reduced_motion: energy = 0.52
	var col := Color(tint,energy)
	draw_set_transform(Vector2(presentation_x,presentation_baseline-343.0*presentation_scale),0,Vector2.ONE*presentation_scale)
	match str(definition.get("special","")):
		"spin":
			var center := Vector2(220,267)
			for arm in range(3):
				var sweep := PackedVector2Array()
				for j in range(25):
					var angle := age*TAU*1.5+float(arm)*TAU/3.0+float(j)*1.55/24.0
					sweep.append(center+Vector2(cos(angle)*170.0,sin(angle)*58.0))
				draw_polyline(sweep,Color(tint,energy*0.25),18,true)
				draw_polyline(sweep,Color("090d18",energy*0.85),7,true)
				draw_polyline(sweep,Color(tint.lightened(0.38),minf(1.0,energy*1.45)),6.0,true)
				draw_polyline(sweep,Color(tint.lightened(0.82),minf(1.0,energy*1.25)),1.8,true)
		"dash":
			var start := Vector2(191,252)
			var finish := Vector2(524+age*62.0,232-age*11.0)
			draw_line(start,finish,Color(tint,energy*0.26),24,true)
			draw_line(start,finish,Color("090d18",energy*0.85),10,true)
			draw_line(start,finish,col,5,true)
			draw_line(start+Vector2(22,-7),finish+Vector2(11,-7),Color(tint.lightened(0.7),energy*0.9),1.8,true)
		"fragment":
			for i in range(8):
				var at := Vector2(280+age*160+i*11,244+sin(i*1.7)*43)
				draw_colored_polygon(PackedVector2Array([at,at+Vector2(11,-4),at+Vector2(19,6),at+Vector2(7,16)]),col)
		"shockwave":
			for i in range(6):
				var at := Vector2(142+i*35,347)
				draw_line(at,at+Vector2(-9,-sin(age*PI)*60-i*2),col,5,true)
		"signal":
			var tip := Vector2(440+age*36,208)
			draw_line(Vector2(288,210),tip,Color(tint,energy*0.20),21,true)
			draw_line(Vector2(288,210),tip,Color("080c18",energy*0.88),10,true)
			draw_line(Vector2(288,210),tip,col,5,true)
			draw_line(tip,tip+Vector2(-26,-15),col,4,true)
			draw_line(tip,tip+Vector2(-26,15),col,4,true)
			for radius in [15.0,29.0]:
				draw_arc(tip,radius,-0.85,0.85,15,Color(tint,energy*0.72),2,true)
		"swarm":
			for i in range(3):
				var at := Vector2(336+float(i)*52,205+float(i%2)*34)
				var soldier := Color(tint.lightened(0.68),minf(1.0,energy*(1.55-0.15*float(i))))
				draw_circle(at,10,Color(tint,energy*0.14))
				draw_arc(at,10,0,TAU,16,soldier,3,true)
				draw_line(at+Vector2(0,10),at+Vector2(0,39),soldier,3,true)
				draw_line(at+Vector2(-12,47),at+Vector2(0,32),soldier,3,true)
				draw_line(at+Vector2(0,32),at+Vector2(12,47),soldier,3,true)
				draw_line(at+Vector2(-16,20),at+Vector2(15,17),soldier,3,true)
				draw_line(at+Vector2(15,17),at+Vector2(22,10),soldier,2,true)
	draw_set_transform(Vector2.ZERO)
