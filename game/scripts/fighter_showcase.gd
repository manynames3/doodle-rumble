extends Control
## Live special demonstration uses the real visual rig, never a damaging fighter.
const Rig = preload("res://scripts/fighter_rig.gd")
var rig
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
	"orange": 52.0, "red": 25.0, "green": -34.0,
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

func configure(id: String) -> void:
	definition = Data.fighter(id)
	tint = Color(definition.color)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	presentation_x = float(PRESENTATION_X.get(id,52.0))
	art_clip = Control.new()
	art_clip.position = Vector2(0,ART_TOP)
	art_clip.size = Vector2(size.x,ART_BOTTOM-ART_TOP)
	art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_clip.clip_contents = true
	add_child(art_clip)
	rig = Rig.new()
	art_clip.add_child(rig)
	rig.configure(definition)
	rig.scale = Vector2.ONE * (2.0*PRESENTATION_SCALE)
	rig.position = Vector2(presentation_x+220.0*PRESENTATION_SCALE,PRESENTATION_TOP+343.0*PRESENTATION_SCALE-ART_TOP)
	rig.preview = false

func _process(delta: float) -> void:
	if not is_instance_valid(rig): return
	clock += delta
	var t: float = fposmod(clock,4.4)
	var progress: float = clampf((t-1.5)/1.3,0,1) if t >= 1.5 and t <= 2.8 else -1
	if Settings.reduced_motion: progress = 0.5
	rig.pose(delta,{"grounded":true,"facing":1,"reduced_motion":Settings.reduced_motion,"attack_progress":progress,"special":true,"attack_windup_ratio":0.27,"attack_active_ratio":0.42})
	# Combat trails are arena-sized. The fighter and weapon retain their real
	# special pose; the page draws an equivalent trail at preview scale below.
	rig.trail = -1.0
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
	var shadow_center := Vector2(presentation_x+220.0*PRESENTATION_SCALE,342.0)
	var shadow := PackedVector2Array()
	for i in range(18):
		var angle := TAU*float(i)/18.0
		shadow.append(shadow_center+Vector2(cos(angle)*58.0,sin(angle)*3.8))
	draw_colored_polygon(shadow,Color("050914",0.56))
	shadow.append(shadow[0])
	draw_polyline(shadow,Color("050914",0.70),1.2,true)
	var t: float = fposmod(clock,4.4)
	if not Settings.reduced_motion and (t < 1.95 or t > 3.1): return
	var age := (t-1.95)/1.15
	if Settings.reduced_motion: age = 0.35
	var col := Color(tint,(1-age)*0.7)
	draw_set_transform(Vector2(presentation_x,PRESENTATION_TOP),0,Vector2.ONE*PRESENTATION_SCALE)
	match str(definition.get("special","")):
		"spin":
			var center := Vector2(220,267)
			for arm in range(3):
				var sweep := PackedVector2Array()
				for j in range(25):
					var angle := age*TAU*1.5+float(arm)*TAU/3.0+float(j)*1.55/24.0
					sweep.append(center+Vector2(cos(angle)*170.0,sin(angle)*58.0))
				draw_polyline(sweep,Color(tint,(1-age)*0.12),18,true)
				draw_polyline(sweep,Color("090d18",(1-age)*0.65),7,true)
				draw_polyline(sweep,col,4.5,true)
				draw_polyline(sweep,Color(tint.lightened(0.75),(1-age)*0.65),1.5,true)
		"dash":
			var start := Vector2(191,252)
			var finish := Vector2(524+age*62.0,232-age*11.0)
			draw_line(start,finish,Color(tint,(1-age)*0.13),24,true)
			draw_line(start,finish,Color("090d18",(1-age)*0.62),10,true)
			draw_line(start,finish,col,5,true)
			draw_line(start+Vector2(22,-7),finish+Vector2(11,-7),Color(tint.lightened(0.7),(1-age)*0.64),1.8,true)
		"fragment":
			for i in range(8):
				var at := Vector2(280+age*160+i*11,244+sin(i*1.7)*43)
				draw_colored_polygon(PackedVector2Array([at,at+Vector2(11,-4),at+Vector2(19,6),at+Vector2(7,16)]),col)
		"shockwave":
			for i in range(6):
				var at := Vector2(142+i*35,347)
				draw_line(at,at+Vector2(-9,-sin(age*PI)*60-i*2),col,5,true)
		"signal":
			draw_line(Vector2(285,210),Vector2(330+age*160,208),col,8,true)
		"swarm":
			for i in range(5):
				var at := Vector2(170+age*135+sin(i*2.0)*70,240+cos(i*2.0)*62)
				draw_circle(at,8,col,false,2,true)
				draw_line(at+Vector2(0,8),at+Vector2(0,28),col,3,true)
				draw_line(at+Vector2(-9,33),at+Vector2(0,22),col,3,true)
				draw_line(at+Vector2(0,22),at+Vector2(9,33),col,3,true)
	draw_set_transform(Vector2.ZERO)
