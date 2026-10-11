extends Control
## Title footer comedy: Blue and Yellow fight over the star that lives in the golden selection underline.
## Every pose is a pure function of cosmetic time, so there are no tweens, timers or extra nodes to clean up.
## The gag is staged in the label gaps beside the selected underline: Blue sneaks in at the underline's end, skates
## to the second gap beyond it, and Yellow catches the star there.
const INK := Color("070810")
const GOLD := Color("ffb539")
const GOLD_HI := Color("ffe2a0")
const CREAM := Color("fff0d7")
const DUST := Color("d9c28a")
const PENCIL := Color("dcd2bc")
const SWEAT := Color("8fd0ff")
const BLUE := Color("4f9dff")
const YELLOW := Color("ffd52e")
const MODE_INTRO := 0
const MODE_LOOP := 1
const ACT_LEN: float = 11.9
const ACT_COUNT: int = 3
const LOOP_LEN: float = ACT_LEN * float(ACT_COUNT)
const INTRO_LEN: float = 2.6
const LOOP_REST: float = 0.55
const T_ON: float = 0.8
const T_OFF: float = 11.6
const LEAVE_LEN: float = 0.3
const REACT_LEN: float = 0.9
const MAX_DT: float = 0.05
const FLOOR_Y: float = 714.0
const CS: float = 1.45
const SR: float = 11.0
const HR: float = 11.0
const LINE_PX: float = 3.3
const BOARD_LIFT: float = 8.4
const GAP_HALF: float = 9.0
const RING_SLOTS: int = 3
const RING_LIFE: float = 1.2
const MAX_SPARKS: int = 28

class Doodle extends RefCounted:
	var tint: Color = Color.WHITE
	var phase_seed: float = 0.0
	var ring: PackedVector2Array = PackedVector2Array()
	var echo: PackedVector2Array = PackedVector2Array()
	var head_pts: PackedVector2Array = PackedVector2Array()
	var echo_pts: PackedVector2Array = PackedVector2Array()
	var shown: float = 0.0
	var pos: Vector2 = Vector2(0.0,714.0)
	var lift: float = 0.0
	var face: float = 1.0
	var turn: float = 0.0
	var lean: float = 0.0
	var squash: float = 1.0
	var walk: float = 0.0
	var stride: float = 0.0
	var kick: float = 0.0
	var tap: float = 0.0
	var arm_f: float = 0.3
	var arm_b: float = -0.3
	var arm_mode: int = 0
	var fidget: float = 0.0
	var look: Vector2 = Vector2.ZERO
	var eye_open: float = 1.0
	var pupil: float = 1.0
	var brow: float = 0.0
	var mouth: int = 0
	var blush: float = 0.0
	var tilt: float = 0.0
	var board: int = 0
	var board_tilt: float = 0.0
	var board_drop: float = 0.0
	var mark_kind: int = 0
	var mark: float = 0.0
	var speed: float = 0.0

	func setup(color: Color, seed_value: float) -> void:
		tint = color
		phase_seed = seed_value
		ring.resize(40)
		head_pts.resize(40)
		echo.resize(20)
		echo_pts.resize(20)
		var a0: float = -2.1 + seed_value * 0.37
		for i in range(40):
			var prog: float = float(i) / 39.0
			var angle: float = a0 + TAU * 1.05 * prog
			var r: float = 1.0 + sin(angle * 3.0 + seed_value) * 0.045 + cos(angle * 7.0 + seed_value * 0.7) * 0.028 + 0.055 * smoothstep(0.86,1.0,prog)
			ring[i] = Vector2(cos(angle),sin(angle)) * r
		for i in range(20):
			var angle: float = a0 + 2.4 + 4.2 * float(i) / 19.0
			var r: float = 1.09 + sin(angle * 5.0 + seed_value) * 0.03
			echo[i] = Vector2(cos(angle),sin(angle)) * r

	func reset() -> void:
		shown = 0.0
		pos = Vector2(0.0,714.0)
		lift = 0.0
		face = 1.0
		turn = 0.0
		lean = 0.0
		squash = 1.0
		walk = 0.0
		stride = 0.0
		kick = 0.0
		tap = 0.0
		arm_f = 0.3
		arm_b = -0.3
		arm_mode = 0
		fidget = 0.0
		look = Vector2.ZERO
		eye_open = 1.0
		pupil = 1.0
		brow = 0.0
		mouth = 0
		blush = 0.0
		tilt = 0.0
		board = 0
		board_tilt = 0.0
		board_drop = 0.0
		mark_kind = 0
		mark = 0.0
		speed = 0.0

var focus_btn: Button = null
var ul_a: Vector2 = Vector2(103.0,704.0)
var ul_b: Vector2 = Vector2(200.0,702.0)
var ul_c: Vector2 = Vector2(263.0,704.0)
var plain_line: PackedVector2Array = PackedVector2Array()
var caret: PackedVector2Array = PackedVector2Array()
var bounds: PackedFloat32Array = PackedFloat32Array()
var target_ax: float = 239.0
var target_dir: float = 1.0
var target_b2: float = 504.0
var ax: float = 239.0
var _had_focus: bool = false
var _reduced: bool = false
var _drawn_active: bool = false
var _clock: float = 0.0
var _wash: float = 0.0
var mode: int = MODE_INTRO
var iu: float = 0.0
var u: float = 0.0
var dirn: float = 1.0
var leaving: bool = false
var leave_age: float = 0.0
var react_age: float = 9.0
var ring_age: PackedFloat32Array = PackedFloat32Array()
var ring_x: PackedFloat32Array = PackedFloat32Array()
var ring_amp: PackedFloat32Array = PackedFloat32Array()
var spark_pos: PackedVector2Array = PackedVector2Array()
var spark_vel: PackedVector2Array = PackedVector2Array()
var spark_life: PackedFloat32Array = PackedFloat32Array()
var spark_max: PackedFloat32Array = PackedFloat32Array()
var spark_kind: PackedInt32Array = PackedInt32Array()
var spark_col: PackedColorArray = PackedColorArray()
var spark_free: PackedByteArray = PackedByteArray()
var _spark_head: int = 0
var _sparks_alive: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _star_pts: PackedVector2Array = PackedVector2Array()
var _star_closed: PackedVector2Array = PackedVector2Array()
var _unit_circle: PackedVector2Array = PackedVector2Array()
var _eye_unit: PackedVector2Array = PackedVector2Array()
var _eye_pts: PackedVector2Array = PackedVector2Array()
var _run_pts: PackedVector2Array = PackedVector2Array()
var _limbs: Array[PackedVector2Array] = [PackedVector2Array(),PackedVector2Array(),PackedVector2Array(),PackedVector2Array(),PackedVector2Array()]
var blue: Doodle = Doodle.new()
var yellow: Doodle = Doodle.new()
var _pb: Doodle = Doodle.new()
var _py: Doodle = Doodle.new()
var cur_gap: float = 0.0
var cur_pull: float = 0.0
var cur_star: Vector4 = Vector4.ZERO
var cur_star_sq: float = 0.0
var cur_star_mood: int = 0
var cur_star_back: bool = false
var cur_ghost: float = 0.0
var cur_board: Vector4 = Vector4.ZERO
var cur_pebble: float = 0.0
var cur_trail: bool = false
# Stage geometry, refreshed from the (smoothed) anchor each frame and frozen while the doodles drop away.
var gm_d: float = 1.0
var gm_ax: float = 239.0
var gm_base: float = 704.0
var gm_home: Vector2 = Vector2(239.0,695.0)
var gm_b2: float = 504.0
var gm_xb: float = 273.0
var gm_xt: float = 452.0
var gm_xl: float = 474.0
var gm_xs: float = 500.0
var gm_yc: float = 534.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280,720)
	clip_contents = true
	_rng.seed = 7
	blue.setup(BLUE,1.3)
	yellow.setup(YELLOW,4.1)
	_pb.setup(BLUE,1.3)
	_py.setup(YELLOW,4.1)
	ring_age.resize(RING_SLOTS)
	ring_x.resize(RING_SLOTS)
	ring_amp.resize(RING_SLOTS)
	for i in range(RING_SLOTS): ring_age[i] = 9.0
	spark_pos.resize(MAX_SPARKS)
	spark_vel.resize(MAX_SPARKS)
	spark_life.resize(MAX_SPARKS)
	spark_max.resize(MAX_SPARKS)
	spark_kind.resize(MAX_SPARKS)
	spark_col.resize(MAX_SPARKS)
	spark_free.resize(MAX_SPARKS)
	var outer: Array[float] = [1.0,0.92,1.07,0.95,1.04]
	for i in range(10):
		var angle: float = -PI * 0.5 + TAU * float(i) / 10.0
		var radius: float = outer[i >> 1] if i % 2 == 0 else 0.47
		_star_pts.append(Vector2(cos(angle),sin(angle)) * radius)
	_star_closed = _star_pts.duplicate()
	_star_closed.append(_star_pts[0])
	for i in range(24):
		var angle: float = TAU * float(i) / 24.0
		_unit_circle.append(Vector2(cos(angle),sin(angle)))
	_eye_unit.resize(10)
	_eye_pts.resize(10)
	for i in range(10):
		var angle: float = TAU * float(i) / 10.0
		_eye_unit[i] = Vector2(cos(angle),sin(angle))
	plain_line = PackedVector2Array([ul_a,ul_b,ul_c])
	_reduced = Settings.reduced_motion

# ---------------------------------------------------------------- focus

func _collect_bounds() -> void:
	bounds.clear()
	var par: Node = get_parent()
	if par == null: return
	for child in par.get_children():
		if child is Button:
			var btn: Button = child
			for edge in [btn.position.x,btn.position.x + btn.size.x]:
				if not bounds.has(edge): bounds.append(edge)
	bounds.sort()

## The second label gap beyond the underline end: that is where Yellow catches and celebrates.
func _second_gap(end_x: float, dir_s: float) -> float:
	var passed: int = 0
	if dir_s > 0.0:
		for i in range(bounds.size()):
			if bounds[i] > end_x + 1.0:
				passed += 1
				if passed == 2: return bounds[i]
	else:
		for i in range(bounds.size() - 1,-1,-1):
			if bounds[i] < end_x - 1.0:
				passed += 1
				if passed == 2: return bounds[i]
	return clampf(end_x + dir_s * 230.0,110.0,1170.0)

func set_focus(b: Button) -> void:
	focus_btn = b
	if bounds.is_empty(): _collect_bounds()
	var p: Vector2 = b.position
	var w: float = b.size.x
	ul_a = p + Vector2(25,42)
	ul_b = p + Vector2(w * 0.47,40)
	ul_c = p + Vector2(w - 21,42)
	plain_line = PackedVector2Array([ul_a,ul_b,ul_c])
	caret = PackedVector2Array([p + Vector2(6,18),p + Vector2(13,24),p + Vector2(5,29)])
	target_dir = 1.0 if (ul_a.x + ul_c.x) * 0.5 < 640.0 else -1.0
	var end_x: float = ul_c.x if target_dir > 0.0 else ul_a.x
	target_ax = end_x - target_dir * 24.0
	target_b2 = _second_gap(end_x,target_dir)
	if not _had_focus:
		_had_focus = true
		ax = target_ax
		dirn = target_dir
	elif _reduced:
		ax = target_ax
		dirn = target_dir
	else:
		_on_focus_moved()
	queue_redraw()

func clear_focus(b: Button) -> void:
	if b != focus_btn: return
	focus_btn = null
	queue_redraw()

func _on_focus_moved() -> void:
	_add_ring(target_ax,3.5)
	_burst(Vector2(ul_a.x,ul_a.y + 2.0),3,GOLD,55.0,false)
	_burst(Vector2(ul_c.x,ul_c.y + 2.0),3,GOLD,55.0,false)
	if _stage_active():
		if not leaving:
			leaving = true
			leave_age = 0.0
	else:
		dirn = target_dir
		react_age = 0.0

func _set_reduced(value: bool) -> void:
	_reduced = value
	leaving = false
	react_age = 9.0
	_sparks_alive = 0
	for i in range(MAX_SPARKS): spark_life[i] = 0.0
	for i in range(RING_SLOTS): ring_age[i] = 9.0
	ax = target_ax
	dirn = target_dir
	_wash = 1.0 if value else 0.0
	if not value:
		mode = MODE_LOOP
		u = 0.0
	queue_redraw()

# ---------------------------------------------------------------- clock

func _stage_active() -> bool:
	if mode == MODE_INTRO: return iu >= 0.25
	return u >= T_ON and u < T_OFF

func _stage_time() -> float:
	return iu if mode == MODE_INTRO else u

func _process(delta: float) -> void:
	if Settings.reduced_motion != _reduced:
		_set_reduced(Settings.reduced_motion)
	if _reduced or not is_visible_in_tree(): return
	var dt: float = minf(delta,MAX_DT)
	_clock += dt
	ax = lerpf(ax,target_ax,1.0 - exp(-14.0 * dt))
	for i in range(RING_SLOTS):
		if ring_age[i] < 9.0: ring_age[i] += dt
	if react_age < REACT_LEN:
		react_age += dt
		if _stage_active(): react_age = REACT_LEN
	var wash_goal: float = 1.0 if (_stage_active() and not leaving) else 0.0
	_wash = move_toward(_wash,wash_goal,dt * 4.0)
	if leaving:
		leave_age += dt
		if leave_age >= LEAVE_LEN: _finish_leave()
	elif mode == MODE_INTRO:
		var previous_intro: float = iu
		iu += dt
		_intro_events(previous_intro,iu)
		if iu >= INTRO_LEN:
			mode = MODE_LOOP
			u = LOOP_REST
			dirn = target_dir
	else:
		var previous: float = u
		u += dt
		_loop_events(previous,u)
		if u >= LOOP_LEN:
			u -= LOOP_LEN
			dirn = target_dir
	_update_sparks(dt)
	var active: bool = _stage_active() or leaving or react_age < REACT_LEN or _sparks_alive > 0 or _ring_live() or _wash > 0.01
	if active or _drawn_active: queue_redraw()
	_drawn_active = active

func _finish_leave() -> void:
	leaving = false
	leave_age = 0.0
	mode = MODE_LOOP
	u = 0.0
	dirn = target_dir

func _ring_live() -> bool:
	for i in range(RING_SLOTS):
		if ring_age[i] < RING_LIFE: return true
	return false

func _add_ring(x: float, amp: float) -> void:
	var slot: int = 0
	for i in range(RING_SLOTS):
		if ring_age[i] > ring_age[slot]: slot = i
	ring_age[slot] = 0.0
	ring_x[slot] = x
	ring_amp[slot] = amp

# ---------------------------------------------------------------- small math

func _seg(t: float, a: float, b: float) -> float:
	return clampf((t - a) / (b - a),0.0,1.0)

func _ease_out(f: float) -> float:
	return 1.0 - pow(1.0 - f,3.0)

func _ease_in(f: float) -> float:
	return f * f

func _ease_io(f: float) -> float:
	return f * f * (3.0 - 2.0 * f)

func _pop(f: float) -> float:
	var c1: float = 1.70158
	return 1.0 + (c1 + 1.0) * pow(f - 1.0,3.0) + c1 * pow(f - 1.0,2.0)

func _crossed(prev: float, cur: float, at: float) -> bool:
	return prev < at and cur >= at

func _ul_base(x: float) -> float:
	if x < ul_b.x:
		return lerpf(ul_a.y,ul_b.y,clampf((x - ul_a.x) / maxf(1.0,ul_b.x - ul_a.x),0.0,1.0))
	return lerpf(ul_b.y,ul_c.y,clampf((x - ul_b.x) / maxf(1.0,ul_c.x - ul_b.x),0.0,1.0))

func _stand(d: Doodle, x: float, lift_px: float) -> void:
	d.pos = Vector2(x,FLOOR_Y)
	d.lift = lift_px

## Whip-turn from facing from_f to the opposite side; f runs 0..1.
func _flip(d: Doodle, from_f: float, f: float) -> void:
	if f >= 1.0:
		d.face = -from_f
		d.turn = 0.0
	else:
		d.face = from_f
		d.turn = PI * _ease_io(f)

func _ef(d: Doodle) -> float:
	return d.face * (1.0 if cos(d.turn) >= 0.0 else -1.0)

func _wide(d: Doodle) -> float:
	return maxf(absf(cos(d.turn)),0.12) * (1.0 + (1.0 - d.squash) * 0.5)

## Body-local drawing point to canvas point; matches the transform used by _draw_doodle.
func _world(d: Doodle, p: Vector2) -> Vector2:
	var sc: float = CS * d.shown
	return Vector2(d.pos.x,d.pos.y - d.lift) + Vector2(p.x * sc * _wide(d),p.y * sc * d.squash).rotated(d.lean)

func _hand_mid(d: Doodle) -> Vector2:
	var a: PackedVector2Array = _arm(d,0)
	var b: PackedVector2Array = _arm(d,1)
	return _world(d,(a[2] + b[2]) * 0.5)

func _star_over(d: Doodle) -> Vector2:
	return _hand_mid(d) + Vector2(0.0,-SR * 0.75)

func _star_hug(d: Doodle) -> Vector2:
	return _world(d,Vector2(_ef(d) * 9.0,-14.5))

func _star_behind(d: Doodle) -> Vector2:
	return _world(d,Vector2(-_ef(d) * 12.5,-14.0))

func _geom() -> void:
	if leaving: return
	gm_d = dirn
	gm_ax = ax
	gm_base = _ul_base(ax)
	gm_home = Vector2(ax,gm_base - SR * 0.8)
	gm_b2 = target_b2
	gm_xb = ax + dirn * 34.0
	gm_xt = gm_b2 - dirn * 52.0
	gm_xl = gm_b2 - dirn * 30.0
	# Give each reaction its own label gap so the larger faces stay readable.
	# Blue retreats to his original perch to intercept Yellow's celebratory toss.
	gm_xs = gm_xb
	gm_yc = gm_b2

func _probe_blue(t: float) -> Doodle:
	_pb.reset()
	_blue_loop(_pb,t)
	return _pb

func _probe_yellow(t: float) -> Doodle:
	_py.reset()
	_yellow_loop(_py,t)
	return _py

# ---------------------------------------------------------------- loop choreography (three 11.9s vignettes before the cycle repeats)
# 0.8 Blue peeks, 1.3 tiptoes in, 2.0 winds up, 2.4 pulls the star out of the line, 3.15 smirks, 3.75 hops on a board
# and skates off, 5.05 hits a pebble, 5.4 faceplants while Yellow hurdles him and catches the star, 6.0 Yellow
# celebrates far too early, 7.3 Yellow tosses the star up and Blue snatches it, 8.05 Blue whistles innocently,
# 8.45 Yellow's double-take, 8.8 mock offence, 9.35 Blue's sheepish grin, 10.4 Blue punts the star home.

func _loop_pose(t: float) -> void:
	var act: int = clampi(int(floor(t / ACT_LEN)),0,ACT_COUNT - 1)
	var beat: float = t - float(act) * ACT_LEN
	match act:
		0: _heist_pose(beat)
		1: _zoomies_pose(beat)
		_: _dance_pose(beat)

func _heist_pose(t: float) -> void:
	_geom()
	_blue_loop(blue,t)
	_yellow_loop(yellow,t)
	cur_gap = _gap_loop(t)
	cur_pull = _pull_loop(t)
	cur_star = _star_loop(t)
	cur_ghost = smoothstep(2.75,2.95,t) * (1.0 - smoothstep(10.9,11.05,t))
	cur_board = _board_loop(t)
	cur_pebble = smoothstep(3.7,3.95,t) * (1.0 - smoothstep(6.1,6.5,t))
	cur_trail = _ball(t).z > 0.5

func _zoomies_star(t: float) -> Vector4:
	var home: Vector2 = gm_home
	var head: Vector2 = _world(blue,Vector2(0.0,-42.0))
	var spin: float = 0.0
	var p: Vector2 = home
	cur_star_mood = 0
	if t < 0.65:
		return Vector4.ZERO
	if t < 1.1:
		p = home + Vector2(0.0,-31.0 * _ease_out(_seg(t,0.65,1.1)))
		spin = -0.18 * _seg(t,0.65,1.1)
	elif t < 1.7:
		p = home.lerp(Vector2(gm_xb,FLOOR_Y - 53.0),_ease_io(_seg(t,1.1,1.7)))
		spin = -0.18 + TAU * _seg(t,1.1,1.7)
	elif t < 5.9:
		var f: float = _seg(t,1.7,5.9)
		var angle: float = TAU * 1.15 * f
		var center_x: float = (gm_xb + gm_yc) * 0.5
		var radius_x: float = (gm_yc - gm_xb) * 0.46
		p = Vector2(center_x + cos(angle) * radius_x,FLOOR_Y - 37.0 + sin(angle * 2.0) * 11.0)
		spin = angle * 1.8
		cur_star_mood = 2
	elif t < 6.35:
		var f: float = _seg(t,5.9,6.35)
		var angle: float = TAU * 1.15
		var center_x: float = (gm_xb + gm_yc) * 0.5
		var radius_x: float = (gm_yc - gm_xb) * 0.46
		var orbit_end: Vector2 = Vector2(center_x + cos(angle) * radius_x,FLOOR_Y - 37.0 + sin(angle * 2.0) * 11.0)
		p = orbit_end.lerp(head + Vector2(0.0,-3.0),_ease_out(f))
		spin = TAU * 2.3 * (1.0 - f)
		cur_star_mood = 1
	elif t < 9.8:
		var wobble: float = sin((t - 6.35) * 8.0)
		p = head + Vector2(wobble * 2.5,-3.0 + absf(wobble) * 2.0)
		spin = wobble * 0.08
		cur_star_mood = 2
	else:
		var f: float = _seg(t,9.8,10.65)
		p = head.lerp(home,_ease_out(f))
		if t > 10.65: p = home
		spin = TAU * 1.4 * (1.0 - f)
		cur_star_mood = 2
	return Vector4(p.x,p.y,SR,spin)

func _zoomies_pose(t: float) -> void:
	_geom()
	cur_gap = 0.0
	cur_pull = 0.0
	cur_ghost = 0.0
	cur_board = Vector4.ZERO
	cur_pebble = 0.0
	cur_trail = false
	_blue_zoomies(blue,t)
	_yellow_zoomies(yellow,t)
	cur_star = _zoomies_star(t)

func _blue_zoomies(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 0.55 or t >= 11.6: return
	d.shown = 1.0
	d.look = Vector2(-fd,-0.7)
	if t < 1.5:
		var f: float = _seg(t,0.55,1.5)
		_stand(d,gm_xb,-54.0 * (1.0 - _pop(f)))
		d.arm_f = 1.9
		d.arm_b = -1.4
		d.eye_open = 1.15
		d.mouth = 1
		d.brow = 0.6
	elif t < 5.9:
		var f: float = _seg(t,1.5,5.9)
		var angle: float = TAU * 1.15 * f
		var target_x: float = gm_xb + fd * 7.0 * sin(angle + 0.75)
		d.walk = angle * 2.1
		d.stride = 1.1
		_stand(d,target_x,3.0 + 2.5 * absf(sin(d.walk)))
		d.lean = fd * 0.23 * sin(angle)
		d.arm_f = 1.3 + 0.6 * sin(d.walk)
		d.arm_b = -0.5 + 0.6 * sin(d.walk + PI)
		d.speed = 0.7
		d.mouth = 2
		d.brow = 0.7
		d.look = Vector2(-fd * cos(angle),-0.8)
	elif t < 6.35:
		var f: float = _seg(t,5.9,6.35)
		_stand(d,gm_xb + fd * 5.0 * _ease_out(f),15.0 * sin(PI * f))
		d.squash = 1.0 + 0.12 * sin(PI * f)
		d.arm_f = 2.7
		d.arm_b = 2.4
		d.eye_open = 1.3
		d.mouth = 9
		d.mark_kind = 3
		d.mark = 1.0 - smoothstep(0.75,1.0,f)
		d.look = Vector2(-fd,-1.0)
	elif t < 7.75:
		var f: float = _seg(t,6.35,7.75)
		_stand(d,gm_xb + fd * 5.0,0.0)
		d.lean = 0.045 * sin(t * 22.0)
		d.arm_f = 1.4
		d.arm_b = 0.9
		d.eye_open = 1.25
		d.brow = -0.9
		d.mouth = 9
		d.mark_kind = 1
		d.mark = 1.0 - smoothstep(7.3,7.75,t)
		d.look = Vector2(0.0,-1.0)
	elif t < 9.8:
		var f: float = _seg(t,7.75,9.8)
		_stand(d,gm_xb + fd * 5.0,2.0 * absf(sin(t * 5.0)))
		d.arm_f = 2.4 + 0.35 * sin(t * 7.0)
		d.arm_b = -0.5
		d.eye_open = 0.8
		d.brow = 0.25
		d.mouth = 4
		d.blush = smoothstep(7.9,8.2,t)
		d.look = Vector2(0.0,-0.8)
	else:
		var f: float = _seg(t,9.8,11.6)
		var home_x: float = gm_xb
		_stand(d,lerpf(gm_xb + fd * 5.0,home_x,_ease_io(f)),2.0 * sin(PI * f))
		d.arm_f = 2.0 + 0.35 * sin(t * 11.0)
		d.mouth = 2
		d.brow = 0.2
		d.look = Vector2(-fd,-0.25)

func _yellow_zoomies(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = fd
	if t < 0.7 or t >= 11.6: return
	d.shown = 1.0
	d.look = Vector2(-fd,-0.7)
	if t < 1.5:
		var f: float = _seg(t,0.7,1.5)
		_stand(d,gm_yc,-60.0 * (1.0 - _pop(f)))
		d.arm_f = 1.6
		d.arm_b = -1.8
		d.eye_open = 1.1
		d.mouth = 1
		d.brow = 0.4
	elif t < 5.9:
		var f: float = _seg(t,1.5,5.9)
		var angle: float = TAU * 1.15 * f
		var target_x: float = gm_yc - fd * 7.0 * sin(angle - 0.75)
		d.walk = angle * 2.1 + PI
		d.stride = 1.0
		_stand(d,target_x,3.0 + 2.5 * absf(sin(d.walk)))
		d.lean = -fd * 0.2 * sin(angle)
		d.arm_f = 1.1 + 0.6 * sin(d.walk)
		d.arm_b = -0.7 + 0.6 * sin(d.walk + PI)
		d.speed = 0.65
		d.mouth = 2
		d.brow = 0.6
		d.look = Vector2(fd * cos(angle),-0.8)
	elif t < 6.35:
		var f: float = _seg(t,5.9,6.35)
		_stand(d,gm_yc - fd * 5.0,13.0 * sin(PI * f))
		d.squash = 1.0 + 0.1 * sin(PI * f)
		d.arm_f = 2.8
		d.arm_b = 2.5
		d.eye_open = 1.3
		d.mouth = 9
		d.mark_kind = 2
		d.mark = 1.0 - smoothstep(0.75,1.0,f)
		d.look = Vector2(-fd,-1.0)
	elif t < 7.75:
		var f: float = _seg(t,6.35,7.75)
		_stand(d,gm_yc - fd * 5.0,0.0)
		d.arm_mode = 5
		d.eye_open = 1.1
		d.brow = 0.8
		d.mouth = 4
		d.look = Vector2(-fd,-0.8)
		d.mark_kind = 2
		d.mark = smoothstep(6.45,6.6,t) * (1.0 - smoothstep(7.4,7.75,t))
	elif t < 9.8:
		var f: float = _seg(t,7.75,9.8)
		_stand(d,gm_yc - fd * 5.0,1.5 * absf(sin(t * 5.0)))
		d.arm_f = 2.7
		d.arm_b = -2.7
		d.eye_open = -1.0
		d.brow = -0.3
		d.mouth = 2
		d.mark_kind = 7
		d.mark = 1.0 - smoothstep(9.4,9.8,t)
	else:
		var f: float = _seg(t,9.8,11.6)
		_stand(d,lerpf(gm_yc - fd * 5.0,gm_yc,_ease_io(f)),1.5 * sin(PI * f))
		d.arm_f = 2.3 + 0.35 * sin(t * 10.0)
		d.mouth = 2
		d.brow = -0.2
		d.look = Vector2(-fd,-0.2)

func _dance_star(t: float) -> Vector4:
	var home: Vector2 = gm_home
	var center: Vector2 = Vector2(gm_ax,FLOOR_Y - 32.0)
	var p: Vector2 = home
	var spin: float = 0.0
	cur_star_mood = 0
	if t < 0.75: return Vector4.ZERO
	if t < 1.4:
		p = home + Vector2(0.0,-24.0 * _ease_out(_seg(t,0.75,1.4)))
	elif t < 5.0:
		var f: float = _seg(t,1.4,5.0)
		var angle: float = TAU * 1.3 * f
		p = Vector2(center.x + cos(angle) * 24.0,center.y + sin(angle * 1.5) * 9.0)
		spin = angle * 1.5
		cur_star_mood = 2
	elif t < 7.15:
		var f: float = _seg(t,5.0,7.15)
		var high: Vector2 = center + Vector2(0.0,-22.0)
		p = high.lerp(home,_ease_in(f))
		spin = TAU * 2.0 * f
		cur_star_mood = 1
	else:
		p = home + Vector2(0.0,-4.0 * absf(sin((t - 7.15) * 7.0)))
		cur_star_mood = 2 if t < 10.2 else 0
	return Vector4(p.x,p.y,SR,spin)

func _dance_pose(t: float) -> void:
	_geom()
	cur_gap = 0.0
	cur_pull = 0.0
	cur_ghost = 0.0
	cur_board = Vector4.ZERO
	cur_pebble = 0.0
	cur_trail = false
	_dance_blue(blue,t)
	_dance_yellow(yellow,t)
	cur_star = _dance_star(t)

func _dance_blue(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 0.45 or t >= 11.6: return
	d.shown = 1.0
	if t < 1.4:
		var f: float = _seg(t,0.45,1.4)
		_stand(d,gm_xb,-48.0 * (1.0 - _pop(f)))
		d.arm_f = 1.6
		d.mouth = 4
		d.look = Vector2(-fd,-0.8)
	elif t < 5.0:
		var f: float = _seg(t,1.4,5.0)
		d.walk = f * PI * 8.0
		d.stride = 0.65
		_stand(d,gm_xb + fd * 13.0 * sin(d.walk),4.0 * absf(sin(d.walk)))
		d.tilt = fd * 0.08 * sin(d.walk)
		d.arm_mode = 8 if int(f * 4.0) % 2 == 0 else 5
		d.arm_f = 2.8
		d.mouth = 2
		d.brow = 0.4
		d.look = Vector2(-fd,0.0)
		if f > 0.72:
			d.arm_f = 0.8
			d.eye_open = 0.8
	elif t < 6.55:
		var f: float = _seg(t,5.0,6.55)
		_stand(d,gm_xb + fd * 8.0 * sin(f * TAU),12.0 * absf(sin(f * PI * 2.0)))
		d.squash = 1.0 + 0.12 * sin(PI * f)
		d.arm_f = 2.6
		d.arm_b = 2.3
		d.mouth = 9
		d.eye_open = 1.3
		d.look = Vector2(-fd,-0.5)
	elif t < 7.2:
		var f: float = _seg(t,6.55,7.2)
		_stand(d,gm_xb + fd * 9.0,0.0)
		d.lean = fd * (0.72 + 0.04 * sin(t * 26.0))
		d.mark_kind = 5
		d.mark = 1.0 - smoothstep(6.9,7.2,t)
		d.eye_open = 0.5
		d.look = Vector2(0.0,0.0)
		d.mouth = 7
	elif t < 9.6:
		var f: float = _seg(t,7.2,9.6)
		_stand(d,gm_xb + fd * 9.0,0.0)
		d.lean = fd * 0.2 * (1.0 - f)
		d.arm_mode = 7
		d.eye_open = 0.8
		d.mouth = 6
		d.blush = 0.45 * (1.0 - f)
		d.look = Vector2(-fd,-0.5)
	else:
		var f: float = _seg(t,9.6,11.6)
		_stand(d,lerpf(gm_xb + fd * 9.0,gm_xb,_ease_io(f)),2.0 * sin(PI * f))
		d.arm_f = 2.4 + 0.35 * sin(t * 12.0)
		d.mouth = 2
		d.brow = 0.1
		d.look = Vector2(-fd,0.0)

func _dance_yellow(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = fd
	if t < 0.65 or t >= 11.6: return
	d.shown = 1.0
	if t < 1.4:
		var f: float = _seg(t,0.65,1.4)
		_stand(d,gm_yc,-52.0 * (1.0 - _pop(f)))
		d.arm_f = 1.8
		d.mouth = 4
		d.look = Vector2(fd,-0.8)
	elif t < 5.0:
		var f: float = _seg(t,1.4,5.0)
		d.walk = f * PI * 8.0 - PI * 0.5
		d.stride = 0.65
		_stand(d,gm_yc - fd * 13.0 * sin(d.walk),4.0 * absf(sin(d.walk)))
		d.tilt = -fd * 0.08 * sin(d.walk)
		d.arm_mode = 8 if int((f + 0.2) * 4.0) % 2 == 0 else 5
		d.arm_b = 2.8
		d.mouth = 2
		d.brow = -0.2
		d.look = Vector2(fd,0.0)
		if f < 0.25:
			d.arm_b = 0.5
			d.eye_open = 1.1
	elif t < 6.55:
		var f: float = _seg(t,5.0,6.55)
		_stand(d,gm_yc - fd * 8.0 * sin(f * TAU + 0.4),10.0 * absf(sin(f * PI * 2.0 + 0.4)))
		d.squash = 1.0 + 0.1 * sin(PI * f)
		d.arm_f = 2.5
		d.arm_b = 2.2
		d.mouth = 9
		d.eye_open = 1.3
		d.look = Vector2(fd,-0.5)
	elif t < 7.2:
		var f: float = _seg(t,6.55,7.2)
		_stand(d,gm_yc - fd * 9.0,0.0)
		d.lean = -fd * (0.72 + 0.04 * sin(t * 27.0))
		d.mark_kind = 2
		d.mark = 1.0 - smoothstep(6.9,7.2,t)
		d.eye_open = 0.5
		d.look = Vector2(0.0,0.0)
		d.mouth = 7
	elif t < 9.6:
		var f: float = _seg(t,7.2,9.6)
		_stand(d,gm_yc - fd * 9.0,0.0)
		d.lean = -fd * 0.2 * (1.0 - f)
		d.arm_mode = 7
		d.eye_open = 0.9
		d.mouth = 4
		d.look = Vector2(-fd,0.0)
	else:
		var f: float = _seg(t,9.6,11.6)
		_stand(d,lerpf(gm_yc - fd * 9.0,gm_yc,_ease_io(f)),2.0 * sin(PI * f))
		d.arm_f = 2.4 + 0.35 * sin(t * 12.0 + 0.7)
		d.mouth = 2
		d.brow = -0.2
		d.look = Vector2(fd,0.0)

func _gap_loop(t: float) -> float:
	if t < 2.7 or t >= 11.2: return 0.0
	return GAP_HALF * smoothstep(2.74,2.84,t) * (1.0 - smoothstep(10.95,11.07,t))

func _pull_loop(t: float) -> float:
	if t < 2.4 or t >= 2.78: return 0.0
	var p: float = 4.5 * _ease_io(_seg(t,2.4,2.72))
	if t > 2.72: p += 0.5 * sin(t * 70.0)
	return p

func _blue_loop(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < T_ON or t >= T_OFF: return
	d.shown = 1.0
	d.look = Vector2(-fd,0.0)
	var xb: float = gm_xb
	if t < 1.3:
		# Peek: rise from under the floor, check the outer side for Yellow, then back to the prize.
		var f: float = _seg(t,0.8,1.3)
		_stand(d,xb + fd * 16.0,-84.0 * (1.0 - _pop(f)))
		d.squash = 1.0 - 0.12 * sin(PI * _seg(f,0.65,1.0))
		d.look = Vector2(fd if (t > 1.02 and t < 1.2) else -fd,0.0)
		d.arm_f = 2.4
		d.arm_b = -2.0
		d.brow = 0.7
		d.mouth = 4
	elif t < 2.0:
		# Tiptoe with a finger over the lips, one conspicuous glance at the viewer.
		var f: float = _seg(t,1.3,2.0)
		d.walk = (t - 1.3) * 7.0
		_stand(d,lerpf(xb + fd * 16.0,xb,_ease_io(f)),1.8 + 1.4 * absf(sin(d.walk)))
		d.stride = 0.5
		d.lean = -fd * 0.2
		d.arm_mode = 5
		d.arm_b = -0.9 + sin(d.walk) * 0.35
		d.brow = 0.8
		d.mouth = 4
		d.eye_open = 0.85
		d.look = Vector2.ZERO if (t > 1.35 and t < 1.7) else Vector2(-fd,0.35)
	elif t < 2.4:
		# Anticipation: crouch, lean in, hands wind up, grin.
		var f: float = _seg(t,2.0,2.4)
		var e: float = _ease_io(minf(f * 2.0,1.0))
		_stand(d,xb,0.0)
		d.squash = lerpf(1.0,0.8,e)
		d.lean = -fd * 0.28 * e + sin(t * 60.0) * 0.012 * f
		d.arm_f = lerpf(0.8,1.5,_ease_io(f))
		d.arm_b = -0.9 - 0.4 * f
		d.brow = 1.0
		d.mouth = 2
		d.look = Vector2(-fd,0.3)
	elif t < 2.75:
		# The pull: one big yank outward, body stretching away from the line.
		var f: float = _seg(t,2.4,2.75)
		var e: float = _ease_io(f)
		_stand(d,xb + fd * 12.0 * e,0.0)
		d.squash = lerpf(0.8,1.14,_ease_io(_seg(f,0.3,1.0)))
		d.lean = lerpf(-fd * 0.28,fd * 0.55,e)
		d.arm_mode = 4 if f > 0.45 else 0
		d.arm_f = lerpf(1.5,1.0,f)
		d.arm_b = -1.3
		d.brow = 1.0
		d.mouth = 3
		d.eye_open = 0.2
		d.look = Vector2(-fd,0.3)
	elif t < 3.15:
		# Recoil: it pops loose, Blue wobbles backward, a "!" jumps up, then the grin returns.
		var f: float = _seg(t,2.75,3.15)
		_stand(d,xb + fd * (12.0 + 10.0 * _ease_out(f)),3.0 * sin(PI * minf(f * 1.6,1.0)))
		d.lean = fd * 0.55 * cos(f * 8.0) * (1.0 - f)
		d.squash = 1.0 + 0.1 * cos(f * 14.0) * (1.0 - f)
		d.arm_mode = 4
		d.look = Vector2(-fd,0.5)
		var shock: bool = f < 0.35
		d.mouth = 9 if shock else 2
		d.eye_open = 1.4 if shock else 1.0
		d.brow = -0.8 if shock else 0.6
		d.mark_kind = 1
		d.mark = 1.0 - smoothstep(0.55,0.95,f)
	elif t < 3.75:
		# Smug "heh heh" bounce, then a quick turn toward the outer side.
		var f: float = _seg(t,3.15,3.75)
		_stand(d,xb + fd * 22.0,1.4 * absf(sin(t * 17.0)))
		d.arm_mode = 4
		d.squash = 1.0 - 0.025 * sin(t * 34.0)
		d.eye_open = 0.7
		d.brow = 0.8
		d.mouth = 4
		d.lean = -fd * 0.05
		d.look = Vector2.ZERO if f < 0.5 else Vector2(fd,0.0)
		_flip(d,-fd,_seg(f,0.5,0.85))
	elif t < 4.05:
		# Skate anticipation: the board drops in, Blue crouches and leans back like a drawn bow.
		var f: float = _seg(t,3.75,4.05)
		d.face = fd
		_stand(d,xb + fd * 22.0,BOARD_LIFT * _ease_out(_seg(f,0.3,0.7)))
		d.board = 1
		d.board_drop = (1.0 - _ease_out(minf(f * 3.0,1.0))) * 16.0
		d.squash = lerpf(1.0,0.84,_ease_io(f))
		d.lean = -fd * 0.5 * _ease_io(f)
		d.arm_mode = 4
		d.brow = 0.6
		d.mouth = 2
		d.look = Vector2(fd,0.0)
	elif t < 5.05:
		# Skate: launch stretch, then accelerate straight at a pebble nobody has noticed yet.
		var f: float = _seg(t,4.05,5.05)
		d.face = fd
		_stand(d,lerpf(xb + fd * 22.0,gm_xt,pow(f,1.7)),BOARD_LIFT + 0.6 * sin(t * 30.0))
		d.board = 1
		d.speed = smoothstep(0.0,0.5,f)
		d.lean = fd * lerpf(0.6,0.3,smoothstep(0.0,0.3,f))
		d.squash = 1.0 + 0.14 * (1.0 - smoothstep(0.0,0.2,f))
		d.board_tilt = 0.05 * sin(t * 22.0)
		d.arm_mode = 4
		d.brow = 0.4
		d.mouth = 2
		d.look = Vector2(fd,0.2)
		if f > 0.86:
			d.mouth = 9
			d.eye_open = 1.4
			d.brow = -0.8
	elif t < 5.4:
		# The board stops dead; Blue is pitched forward and the star leaves his arms.
		var f: float = _seg(t,5.05,5.4)
		d.face = fd
		_stand(d,lerpf(gm_xt,gm_xl,_ease_out(f)),BOARD_LIFT * (1.0 - f) + 22.0 * sin(PI * f))
		d.lean = fd * lerpf(0.2,1.25,_ease_io(f))
		d.arm_f = lerpf(1.2,2.5,f)
		d.arm_b = lerpf(0.5,2.3,f)
		d.mouth = 9
		d.eye_open = 1.4
		d.brow = -1.0
		d.look = Vector2(fd,0.0)
	elif t < 6.2:
		# Faceplant: dizzy eyes and a doodled spiral, while Yellow celebrates over him.
		d.face = fd
		var age: float = t - 5.4
		_stand(d,gm_xl,0.0)
		d.lean = fd * (1.2 + 0.06 * cos(age * 22.0) * exp(-age * 6.0))
		d.squash = 0.93
		d.arm_f = 2.2 + 0.3 * sin(t * 3.0)
		d.arm_b = 1.9
		d.mouth = 7
		d.brow = -0.6
		d.look = Vector2(cos(t * 7.0) * 0.8,sin(t * 7.0) * 0.8)
		d.mark_kind = 5
		d.mark = smoothstep(5.5,5.65,t) * (1.0 - smoothstep(6.05,6.2,t))
	elif t < 6.65:
		# Peel up off the floor, spot Yellow's victory dance.
		var f: float = _seg(t,6.2,6.65)
		d.face = fd
		_stand(d,gm_xl,0.0)
		d.lean = fd * 1.2 * (1.0 - _ease_io(f)) + sin(f * 12.0) * 0.04 * (1.0 - f)
		d.squash = 1.0 - 0.1 * sin(PI * f)
		d.arm_f = lerpf(2.2,0.8,f)
		d.arm_b = lerpf(1.9,-0.4,f)
		d.mouth = 6 if f < 0.7 else 4
		d.brow = lerpf(-0.4,0.8,smoothstep(0.6,0.9,f))
		d.look = Vector2(fd,-0.5)
	elif t < 7.25:
		# Sneak: tiptoe up behind the preening Yellow, finger to lips, glance at the viewer.
		var f: float = _seg(t,6.65,7.25)
		d.face = fd
		d.walk = (t - 6.65) * 7.0
		_stand(d,lerpf(gm_xl,gm_xs,_ease_io(f)),1.8 + 1.4 * absf(sin(d.walk)))
		d.stride = 0.5
		d.lean = fd * 0.2
		d.arm_mode = 5
		d.arm_b = -0.9 + sin(d.walk) * 0.35
		d.brow = 0.8
		d.mouth = 4
		d.eye_open = 0.85
		d.look = Vector2(fd,-0.5) if f < 0.55 else Vector2.ZERO
	elif t < 7.42:
		var f: float = _seg(t,7.25,7.42)
		d.face = fd
		_stand(d,gm_xs,0.0)
		d.squash = lerpf(1.0,0.78,_ease_io(f))
		d.lean = fd * 0.2
		d.arm_f = lerpf(0.5,1.2,f)
		d.arm_b = lerpf(-0.5,0.6,f)
		d.brow = 1.0
		d.mouth = 2
		d.look = Vector2(fd,-0.8)
	elif t < 7.86:
		# Leap: arms up, snatch the tossed star at the top of the jump.
		var f: float = _seg(t,7.42,7.86)
		d.face = fd
		_stand(d,gm_xs + fd * 3.0 * sin(PI * f),17.0 * sin(PI * f))
		d.squash = 1.0 + 0.12 * sin(PI * f)
		d.arm_f = 2.9
		d.arm_b = 2.6
		d.brow = 0.9
		d.mouth = 2
		d.look = Vector2(fd,-0.9)
	elif t < 8.05:
		# Landing, hands tuck the star behind his back.
		var f: float = _seg(t,7.86,8.05)
		d.face = fd
		_stand(d,gm_xs,0.0)
		d.squash = 1.0 - 0.14 * sin(PI * f)
		d.arm_mode = 6 if t > 7.95 else 0
		d.arm_f = lerpf(2.9,1.0,f)
		d.arm_b = lerpf(2.6,0.4,f)
		d.mouth = 4
		d.brow = 0.5
		d.look = Vector2(fd,0.0)
	elif t < 8.85:
		# Conspicuously innocent: eyes on the sky, whistling, heels bobbing, the star plainly visible behind him.
		d.face = fd
		_stand(d,gm_xs,0.8 * absf(sin(t * 7.0)))
		d.arm_mode = 6
		d.lean = 0.04 * sin(t * 6.0)
		d.eye_open = 0.8
		d.brow = -0.3
		d.mouth = 8
		d.look = Vector2(fd * 0.3,-1.0)
		d.mark_kind = 6
		d.mark = 1.0
	elif t < 9.35:
		# Caught: eyes slide to Yellow, a sweat drop forms.
		d.face = fd
		_stand(d,gm_xs,0.0)
		d.arm_mode = 6
		d.squash = 1.0 - 0.03 * sin(t * 50.0)
		d.eye_open = 1.15
		d.pupil = 0.75
		d.brow = -0.9
		d.mouth = 7
		d.look = Vector2(fd,0.2)
		d.mark_kind = 4
		d.mark = smoothstep(8.9,9.05,t)
	elif t < 9.95:
		# Sheepish: blushing grin, scratching his head, shy glance down and aside.
		d.face = fd
		_stand(d,gm_xs,0.0)
		d.arm_mode = 3
		d.arm_b = -0.6
		d.fidget = sin(t * 20.0)
		d.blush = smoothstep(9.35,9.5,t)
		d.brow = -0.9
		d.mouth = 7
		d.tilt = fd * 0.14
		d.look = Vector2(fd * 0.3,0.9) if t < 9.75 else Vector2(fd,0.1)
		d.lean = 0.03
		d.mark_kind = 4
		d.mark = 1.0 - smoothstep(9.5,9.7,t)
	elif t < 10.2:
		# Shrug, then offer the star back with both hands.
		var f: float = _seg(t,9.95,10.2)
		d.face = fd
		_stand(d,gm_xs,1.5 * sin(PI * f))
		d.arm_mode = 7 if f < 0.45 else 4
		d.blush = 1.0
		d.brow = -0.8
		d.mouth = 7
		d.tilt = fd * 0.1 * (1.0 - f)
		d.look = Vector2(fd,0.3)
	elif t < 10.42:
		# Turn to the underline and wind up a kick.
		var f: float = _seg(t,10.2,10.42)
		_flip(d,fd,_seg(f,0.0,0.6))
		_stand(d,gm_xs,0.0)
		d.squash = lerpf(1.0,0.88,_ease_io(f))
		d.lean = fd * 0.28 * _ease_io(f)
		d.kick = -0.8 * _ease_io(f)
		d.arm_f = 0.9
		d.arm_b = -0.9
		d.blush = 1.0 - f
		d.brow = 0.5
		d.mouth = 2
		d.look = Vector2(-fd,-0.2)
	elif t < 10.75:
		# Punt: the star flies home along an arc, Blue follows through with a hop.
		var f: float = _seg(t,10.42,10.75)
		d.face = -fd
		_stand(d,gm_xs,3.0 * sin(PI * f))
		d.kick = lerpf(1.0,0.0,_ease_io(_seg(f,0.2,1.0)))
		d.lean = lerpf(fd * 0.28,-fd * 0.3,_ease_out(minf(f * 2.0,1.0))) * (1.0 - f * 0.6)
		d.arm_f = 1.6
		d.arm_b = -1.4
		d.mouth = 2
		d.brow = 0.2
		d.look = Vector2(-fd,-0.5)
	elif t < 11.25:
		# Wave to the viewer; a little hop when the star lands.
		d.face = -fd
		_stand(d,gm_xs,5.0 * sin(PI * _seg(t,11.05,11.3)))
		d.arm_f = 2.6 + sin(t * 14.0) * 0.45
		d.arm_b = -0.4
		d.mouth = 2
		d.brow = -0.2
		d.look = Vector2.ZERO
	else:
		var f: float = _seg(t,11.25,11.6)
		d.face = -fd
		_stand(d,gm_xs,-90.0 * _ease_in(f))
		d.squash = 1.0 - 0.1 * sin(PI * minf(f * 2.0,1.0))
		d.arm_f = 2.2
		d.mouth = 2

func _yellow_x(t: float) -> float:
	var fd: float = gm_d
	var xj: float = gm_b2 - fd * 84.0
	if t < 4.95: return gm_xb
	if t < 5.4: return lerpf(gm_xb,xj,pow(_seg(t,4.95,5.4),1.3))
	if t < 5.85: return lerpf(xj,gm_yc,_seg(t,5.4,5.85))
	return gm_yc

func _yellow_loop(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = fd
	if t < 4.25 or t >= T_OFF: return
	d.shown = 1.0
	d.look = Vector2(-fd,0.0)
	_stand(d,_yellow_x(t),0.0)
	if t < 4.6:
		# Spring up out of the floor where Blue just was, staring at the star-shaped hole in the underline.
		var f: float = _seg(t,4.25,4.6)
		d.face = -fd
		d.lift = -84.0 * (1.0 - _pop(f))
		d.squash = 1.0 - 0.12 * sin(PI * _seg(f,0.6,1.0))
		d.look = Vector2(-fd,0.3)
		d.eye_open = 1.2
		d.arm_f = 0.6
		d.arm_b = 0.2
	elif t < 4.95:
		# Double-take: "?" at the gap, then eyes whip outward to the skating thief and a "!" pops up.
		var f: float = _seg(t,4.6,4.95)
		d.face = -fd if t < 4.9 else fd
		d.eye_open = 1.35
		d.arm_f = lerpf(0.6,1.9,smoothstep(0.4,0.7,f))
		d.arm_b = lerpf(0.2,1.5,smoothstep(0.4,0.7,f))
		if f < 0.4:
			d.mouth = 1
			d.look = Vector2(-fd,0.3)
			d.mark_kind = 2
			d.mark = smoothstep(0.0,0.15,f)
		else:
			d.mouth = 9
			d.look = Vector2(fd,0.0)
			d.brow = -0.8
			d.lift = 5.0 * sin(PI * _seg(f,0.4,0.8))
			d.mark_kind = 1
			d.mark = 1.0 - smoothstep(0.85,1.0,f)
	elif t < 5.4:
		# Chase: low, fast and furious, speed lines streaming behind.
		d.walk = t * 34.0
		d.stride = 1.4
		d.lift = 1.5 * absf(sin(d.walk))
		d.lean = fd * 0.45
		d.arm_f = 0.9 * sin(d.walk) + 0.3
		d.arm_b = -0.3 + 0.9 * sin(d.walk + PI)
		d.speed = 1.0
		d.mouth = 2
		d.brow = 1.0
		d.look = Vector2(fd,0.0)
	elif t < 5.85:
		# Hurdle Blue, snatch the star at the top of the jump.
		var f: float = _seg(t,5.4,5.85)
		d.lift = 34.0 * sin(PI * f)
		d.walk = 0.8 + f * 1.0
		d.stride = 1.5 * (1.0 - smoothstep(0.55,0.9,f))
		d.lean = lerpf(fd * 0.5,-fd * 0.1,f)
		d.arm_f = lerpf(1.2,2.9,smoothstep(0.1,0.5,f))
		d.arm_b = -lerpf(0.4,2.9,smoothstep(0.1,0.5,f))
		d.mouth = 2
		d.brow = 0.6
		d.look = Vector2(fd,-0.6)
		d.speed = 1.0 - f
		if f > 0.9: d.squash = 1.0 - 0.15 * sin(PI * _seg(f,0.9,1.0))
	elif t < 6.0:
		var f: float = _seg(t,5.85,6.0)
		d.squash = 1.0 - 0.2 * sin(PI * f)
		d.arm_f = 2.9
		d.arm_b = -2.9
		d.mouth = 2
		d.look = Vector2(fd,-0.6)
		d.eye_open = lerpf(1.0,-1.0,_seg(f,0.5,1.0))
	elif t < 7.1:
		# TOO EARLY: two proud hops, eyes shut in a beaming arch, chin up, a sunburst doodled behind the head.
		var hop: float = absf(sin((t - 6.0) * PI / 0.45))
		d.lift = 12.0 * hop
		d.squash = 1.0 - 0.12 * pow(1.0 - hop,6.0)
		d.arm_f = 2.9
		d.arm_b = -2.9
		d.eye_open = -1.0
		d.mouth = 2
		d.brow = -0.4
		d.tilt = -fd * 0.14
		d.lean = -fd * 0.08
		d.mark_kind = 7
		d.mark = (0.55 + 0.45 * hop) * (1.0 - smoothstep(6.95,7.1,t))
	elif t < 7.3:
		# Lowers the star and winds up to toss it.
		var f: float = _seg(t,7.1,7.3)
		d.squash = lerpf(1.0,0.82,_ease_io(f))
		d.arm_mode = 4 if f > 0.4 else 0
		d.arm_f = lerpf(2.9,1.2,f)
		d.arm_b = -lerpf(2.9,0.4,f)
		d.eye_open = -1.0
		d.mouth = 0
		d.tilt = -fd * 0.1
	elif t < 7.7:
		# Toss and pirouette with eyes still shut, arms wide: "ta-da".
		var f: float = _seg(t,7.3,7.7)
		d.lift = 9.0 * sin(PI * _seg(f,0.0,0.8))
		d.turn = TAU * _ease_io(_seg(f,0.15,0.95))
		d.arm_mode = 8
		d.squash = 1.0 + 0.1 * sin(PI * minf(f * 2.0,1.0))
		d.eye_open = -1.0
		d.mouth = 2
		d.brow = -0.4
	elif t < 8.05:
		# Hands clap together around nothing; a satisfied smile.
		var f: float = _seg(t,7.7,7.86)
		d.arm_mode = 4
		d.squash = 1.0 - 0.1 * sin(PI * minf(f,1.0))
		d.eye_open = -1.0
		d.mouth = 0
		d.tilt = -fd * 0.1
		d.lean = -fd * 0.06
	elif t < 8.45:
		# Freeze: eyes pop open, stare down at the empty hands.
		var f: float = _seg(t,8.05,8.45)
		d.arm_mode = 4 if f < 0.4 else 0
		d.arm_f = lerpf(1.0,1.45,_seg(f,0.4,1.0))
		d.arm_b = lerpf(0.7,1.1,_seg(f,0.4,1.0))
		d.lift = 3.0 * sin(PI * minf(f * 5.0,1.0))
		d.eye_open = 1.35
		d.pupil = 0.55
		d.brow = -1.0
		d.mouth = 1
		d.look = Vector2(0.0,1.0)
		d.lean = sin(t * 55.0) * 0.012
		d.mark_kind = 2
		d.mark = smoothstep(0.55,0.8,f)
	elif t < 8.8:
		# Whips around to Blue: jolt, "!?", mouth wide open.
		var f: float = _seg(t,8.45,8.8)
		_flip(d,fd,_seg(f,0.0,0.45))
		d.lift = 6.0 * sin(PI * minf(f * 2.5,1.0))
		d.squash = 1.0 + 0.12 * sin(PI * minf(f * 2.5,1.0))
		d.arm_f = 1.9
		d.arm_b = 1.4
		d.eye_open = 1.4
		d.pupil = 0.6
		d.brow = -1.0
		d.mouth = 9
		d.look = Vector2(-fd,0.0)
		d.lean = sin(t * 55.0) * 0.012
		d.mark_kind = 3
		d.mark = 1.0 - smoothstep(0.7,1.0,f)
	elif t < 10.2:
		# Mock offence: fists on hips, half-lidded stare, pout, foot tapping.
		d.face = -fd
		d.arm_mode = 1
		d.eye_open = 0.6
		d.brow = 1.0
		d.mouth = 6
		d.look = Vector2(-fd,0.0)
		d.lean = -fd * 0.1
		d.tilt = -fd * 0.08
		d.tap = absf(sin(t * 10.0)) if t > 9.0 else 0.0
	elif t < 11.05:
		# Arms crossed, chin up, eyes follow the punted star.
		var f: float = _seg(t,10.2,10.4)
		d.face = -fd
		d.arm_mode = 2
		d.eye_open = lerpf(0.6,0.85,f)
		d.brow = lerpf(1.0,0.5,f)
		d.mouth = 5
		d.look = Vector2(-fd,0.0) if t < 10.45 else Vector2(-fd,-0.6)
		d.tilt = -fd * 0.12
		d.lean = fd * 0.06
		d.tap = absf(sin(t * 10.0)) if t < 10.8 else 0.0
	elif t < 11.25:
		var f: float = _seg(t,11.05,11.25)
		d.face = -fd
		_stand(d,gm_yc,0.0)
		d.lift = 4.0 * sin(PI * f)
		d.arm_f = 1.0 + 0.6 * sin(f * PI)
		d.arm_b = 0.5
		d.mouth = 0
		d.brow = -0.3
		d.look = Vector2(-fd,-0.2)
	else:
		var f: float = _seg(t,11.25,11.6)
		d.face = -fd
		d.lift = -90.0 * _ease_in(f)
		d.squash = 1.0 - 0.1 * sin(PI * minf(f * 2.0,1.0))
		d.arm_f = 0.9
		d.mouth = 0
		d.look = Vector2.ZERO

func _arc(p0: Vector2, p1: Vector2, f: float, h: float, spin: float) -> Vector4:
	return Vector4(lerpf(p0.x,p1.x,f),lerpf(p0.y,p1.y,f) - h * 4.0 * f * (1.0 - f),SR,spin * f)

## The three airborne star flights; the endpoints are read from the doodles' poses so catches line up exactly.
func _ball(t: float) -> Vector4:
	var fd: float = gm_d
	if t >= 5.05 and t < 5.62:
		return _arc(_star_hug(_probe_blue(5.05)),_star_over(_probe_yellow(5.62)),_seg(t,5.05,5.62),26.0,TAU * 2.0 * fd)
	if t >= 7.3 and t < 7.66:
		return _arc(_star_hug(_probe_yellow(7.3)),_star_over(_probe_blue(7.66)),_seg(t,7.3,7.66),26.0,TAU * 1.5 * -fd)
	if t >= 10.4 and t < 11.05:
		return _arc(Vector2(gm_xs - fd * 14.0,FLOOR_Y - SR * 0.85),gm_home,_seg(t,10.4,11.05),48.0,TAU * 2.0 * -fd)
	return Vector4.ZERO

func _star_loop(t: float) -> Vector4:
	cur_star_sq = 0.0
	cur_star_mood = 0
	cur_star_back = false
	if t < 1.0 or t >= T_OFF: return Vector4.ZERO
	var home: Vector2 = gm_home
	if t < 1.3:
		return Vector4(home.x,home.y,SR * _pop(_seg(t,1.0,1.3)),0.0)
	if t < 2.4:
		return Vector4(home.x,home.y,SR * (1.0 + 0.04 * sin(t * 5.0)),0.06 * sin(t * 3.0))
	if t < 2.75:
		var e: float = _ease_io(_seg(t,2.4,2.75))
		var p: Vector2 = home.lerp(_star_hug(blue),e)
		cur_star_sq = 0.5 * sin(PI * e)
		cur_star_mood = 1
		return Vector4(p.x,p.y,SR,0.3 * sin(t * 50.0) * (1.0 - e))
	if t < 5.05:
		var p: Vector2 = _star_hug(blue)
		cur_star_mood = 1 if t < 3.6 else 2
		return Vector4(p.x,p.y,SR,0.12 * sin(t * 14.0))
	var ball: Vector4 = _ball(t)
	if ball.z > 0.5:
		cur_star_mood = 1 if t < 6.0 else 0
		return ball
	if t < 7.1:
		var p: Vector2 = _star_over(yellow)
		cur_star_mood = 2
		return Vector4(p.x,p.y,SR,0.1 * sin(t * 6.0))
	if t < 7.3:
		var p: Vector2 = _star_over(yellow).lerp(_star_hug(yellow),_ease_io(_seg(t,7.1,7.3)))
		cur_star_mood = 2
		return Vector4(p.x,p.y,SR,0.0)
	if t < 7.86:
		var p: Vector2 = _star_over(blue)
		cur_star_mood = 1
		return Vector4(p.x,p.y,SR,0.0)
	if t < 8.05:
		var p: Vector2 = _star_over(blue).lerp(_star_behind(blue),_ease_io(_seg(t,7.86,8.05)))
		cur_star_back = t > 7.9
		cur_star_mood = 1
		return Vector4(p.x,p.y,SR,0.0)
	if t < 9.95:
		var p: Vector2 = _star_behind(blue)
		cur_star_back = true
		cur_star_mood = 1
		return Vector4(p.x + sin(t * 3.0) * 1.2,p.y,SR,0.1 * sin(t * 4.0))
	if t < 10.1:
		var p: Vector2 = _star_behind(blue).lerp(_star_hug(blue),_ease_io(_seg(t,9.95,10.1)))
		cur_star_back = t < 10.0
		cur_star_mood = 1
		return Vector4(p.x,p.y,SR,0.0)
	if t < 10.2:
		var p: Vector2 = _star_hug(blue)
		cur_star_mood = 1
		return Vector4(p.x,p.y,SR,0.0)
	if t < 10.4:
		var f: float = _seg(t,10.2,10.4)
		var floor_pt: Vector2 = Vector2(gm_xs - gm_d * 14.0,FLOOR_Y - SR * 0.85)
		var p: Vector2 = _star_hug(blue).lerp(floor_pt,_ease_in(f))
		cur_star_mood = 1
		return Vector4(p.x,p.y,SR,0.0)
	if t < 11.35:
		# Landed in the line again: a squashy bounce and a settle.
		var age: float = t - 11.05
		cur_star_sq = 0.3 * exp(-9.0 * age) * sin(age * 40.0)
		return Vector4(home.x,home.y,SR,0.0)
	var sink: float = 1.0 - _ease_io(_seg(t,11.35,T_OFF))
	return Vector4(home.x,home.y,SR * sink,0.0)

func _board_loop(t: float) -> Vector4:
	if t < 5.05 or t >= 6.5: return Vector4.ZERO
	var fd: float = gm_d
	var f: float = _seg(t,5.05,5.7)
	var air: float = 4.0 * f * (1.0 - f)
	var x: float = gm_xt - fd * 12.0 * _ease_out(f)
	var y: float = FLOOR_Y - 4.2 * CS - 30.0 * air
	var alpha: float = 1.0 - smoothstep(6.1,6.5,t)
	return Vector4(x,y,-fd * PI * _ease_out(f),alpha)

func _loop_events(prev: float, cur: float) -> void:
	for act in range(ACT_COUNT):
		var start: float = float(act) * ACT_LEN
		var finish: float = start + ACT_LEN
		if cur <= start or prev >= finish: continue
		var local_prev: float = maxf(prev,start) - start
		var local_cur: float = minf(cur,finish) - start
		match act:
			0: _heist_events(local_prev,local_cur)
			1: _zoomies_events(local_prev,local_cur)
			_: _dance_events(local_prev,local_cur)

func _zoomies_events(prev: float, cur: float) -> void:
	_geom()
	if _crossed(prev,cur,0.65):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,56.0,false)
	if _crossed(prev,cur,1.7):
		_burst(Vector2(gm_xb,FLOOR_Y - 54.0),3,GOLD,54.0,false,2)
	if _crossed(prev,cur,3.8):
		var center: Vector2 = Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 55.0)
		_burst(center,3,GOLD_HI,45.0,false,2)
	if _crossed(prev,cur,5.9):
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 2.0),4,DUST,62.0,true)
	if _crossed(prev,cur,6.35):
		_add_ring(gm_ax,5.0)
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 48.0),5,GOLD_HI,74.0,true,2)
	if _crossed(prev,cur,7.75):
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 50.0),3,CREAM,44.0,false,1)
	if _crossed(prev,cur,9.8):
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 50.0),4,GOLD,54.0,false,2)
	if _crossed(prev,cur,10.65):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,52.0,false)
	if _crossed(prev,cur,T_OFF):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),3,DUST,48.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,48.0,true)

func _dance_events(prev: float, cur: float) -> void:
	_geom()
	if _crossed(prev,cur,0.75):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,4,GOLD_HI,52.0,false)
	if _crossed(prev,cur,1.4):
		_burst(Vector2(gm_ax,FLOOR_Y - 2.0),3,DUST,42.0,true)
	if _crossed(prev,cur,5.0):
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 54.0),4,GOLD_HI,56.0,false,2)
	if _crossed(prev,cur,6.55):
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 2.0),6,DUST,76.0,true)
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 41.0),3,CREAM,54.0,true,1)
	if _crossed(prev,cur,7.15):
		_add_ring(gm_ax,4.0)
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 54.0),5,GOLD,62.0,false,2)
	if _crossed(prev,cur,9.6):
		_burst(gm_home,4,GOLD_HI,48.0,false)
	if _crossed(prev,cur,11.15):
		_add_ring(gm_ax,3.5)
		_burst(gm_home,5,GOLD,48.0,false)
	if _crossed(prev,cur,T_OFF):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),3,DUST,45.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,45.0,true)

func _heist_events(prev: float, cur: float) -> void:
	_geom()
	var fd: float = gm_d
	if _crossed(prev,cur,1.0):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,60.0,false)
	if _crossed(prev,cur,1.1):
		_burst(Vector2(gm_xb + fd * 16.0,FLOOR_Y - 2.0),3,DUST,50.0,true)
	if _crossed(prev,cur,2.75):
		_add_ring(gm_ax,7.0)
		_burst(gm_home,10,GOLD,95.0,false)
	if _crossed(prev,cur,4.08):
		_burst(Vector2(gm_xb + fd * 20.0,FLOOR_Y - 2.0),4,DUST,60.0,true)
	if _crossed(prev,cur,5.05):
		_burst(Vector2(gm_xt + fd * 14.0,FLOOR_Y - 4.0),6,DUST,90.0,true)
		_burst(Vector2(gm_xt + fd * 14.0,FLOOR_Y - 6.0),4,GOLD_HI,110.0,true,2)
	if _crossed(prev,cur,5.4):
		_burst(Vector2(gm_xl,FLOOR_Y - 2.0),5,DUST,70.0,true)
	if _crossed(prev,cur,5.85):
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),5,DUST,70.0,true)
	for at in [6.2,6.62,7.0]:
		if _crossed(prev,cur,at):
			var p: Vector2 = _star_over(_probe_yellow(at))
			_burst(p + Vector2(_rng.randf_range(-18.0,18.0),_rng.randf_range(-6.0,10.0)),1,GOLD_HI,24.0,true,2)
	if _crossed(prev,cur,7.66):
		_burst(_star_over(_probe_blue(7.66)),6,GOLD_HI,80.0,true)
	if _crossed(prev,cur,8.45):
		_burst(Vector2(gm_yc,FLOOR_Y - 40.0),4,CREAM,90.0,true,1)
	if _crossed(prev,cur,11.05):
		_add_ring(gm_ax,6.0)
		_burst(gm_home,9,GOLD,90.0,false)
	if _crossed(prev,cur,11.4):
		_add_ring(gm_ax,3.5)
		_burst(Vector2(gm_ax,gm_base),5,GOLD_HI,60.0,false)
	if _crossed(prev,cur,T_OFF):
		_burst(Vector2(gm_xs,FLOOR_Y - 2.0),4,DUST,50.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),4,DUST,50.0,true)

# ---------------------------------------------------------------- first-appearance hello (2.6s)

func _intro_pose(t: float) -> void:
	_geom()
	_greet(blue,t,0.25,gm_d,gm_xb)
	_greet(yellow,t,0.5,-gm_d,gm_yc)

func _greet(d: Doodle, t: float, t0: float, facing: float, x: float) -> void:
	d.face = facing
	if t < t0 or t >= INTRO_LEN: return
	d.shown = 1.0
	var f: float = _seg(t,t0,t0 + 0.4)
	_stand(d,x,-84.0 * (1.0 - _pop(f)))
	d.squash = 1.0 - 0.12 * sin(PI * _seg(f,0.65,1.0))
	d.mouth = 2
	d.brow = -0.3
	d.look = Vector2.ZERO
	if t > t0 + 0.4 and t < 1.8:
		d.arm_f = 2.6 + sin((t - t0) * 14.0) * 0.45
		d.tilt = 0.1 * sin((t - t0) * 9.0) * (-facing)
	if t > t0 + 0.8 and t < t0 + 1.1:
		var hf: float = _seg(t,t0 + 0.8,t0 + 1.1)
		d.lift = 6.0 * sin(PI * hf)
		d.squash = 1.0 - 0.1 * sin(PI * minf(hf * 3.0,1.0))
		d.arm_b = -2.6
	if t >= 1.8 and t < 2.05:
		d.look = Vector2(-facing,0.0)
		d.arm_f = 0.5
		d.mouth = 0
	if t >= 2.05:
		var g: float = _seg(t,2.05,INTRO_LEN)
		d.lift = -88.0 * _ease_in(g)
		d.squash = 1.0 - 0.1 * sin(PI * minf(g * 2.0,1.0))
		d.arm_f = 2.2
		d.look = Vector2(-facing,0.0)

func _intro_events(prev: float, cur: float) -> void:
	_geom()
	if _crossed(prev,cur,0.35):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),4,DUST,60.0,true)
		_add_ring(gm_ax,4.0)
	if _crossed(prev,cur,0.6):
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),4,DUST,60.0,true)
	if _crossed(prev,cur,1.6):
		_burst(Vector2(gm_xb,FLOOR_Y - 46.0),2,GOLD_HI,40.0,true,2)
		_burst(Vector2(gm_yc,FLOOR_Y - 46.0),2,GOLD_HI,40.0,true,2)

# ---------------------------------------------------------------- react (rest) and static

func _react_pose() -> void:
	var t: float = react_age
	var base: float = _ul_base(ax)
	var home: Vector2 = Vector2(ax,base - SR * 0.8 * 0.7)
	cur_gap = GAP_HALF * smoothstep(0.0,0.08,t) * (1.0 - smoothstep(0.7,0.82,t))
	var r: float = SR * 0.7
	cur_star_mood = 0
	if t < 0.1:
		cur_star = Vector4(home.x,home.y,r * smoothstep(0.0,0.1,t),0.0)
	elif t < 0.72:
		var f: float = _seg(t,0.1,0.72)
		var hop: float = absf(sin(f * TAU)) * 14.0 * (1.0 - f)
		cur_star = Vector4(home.x,home.y - hop,r,f * 6.0)
	elif t < 0.84:
		cur_star = Vector4(home.x,home.y,r * (1.0 - _ease_io(_seg(t,0.72,0.84))),0.0)

## Reduced motion: the punchline held still. Blue's star shows plainly behind his back, Yellow glares, and a
## dotted pencil star marks the empty spot in the unbroken underline.
func _static_pose() -> void:
	_geom()
	blue.reset()
	yellow.reset()
	var fd: float = gm_d
	blue.face = fd
	blue.shown = 1.0
	_stand(blue,gm_xs,0.0)
	blue.arm_mode = 6
	blue.eye_open = 1.1
	blue.pupil = 0.8
	blue.brow = -0.9
	blue.mouth = 7
	blue.blush = 1.0
	blue.tilt = fd * 0.1
	blue.look = Vector2(fd,0.3)
	blue.mark_kind = 4
	blue.mark = 1.0
	yellow.face = -fd
	yellow.shown = 1.0
	_stand(yellow,gm_yc,0.0)
	yellow.arm_mode = 1
	yellow.eye_open = 0.6
	yellow.brow = 1.0
	yellow.mouth = 6
	yellow.look = Vector2(-fd,0.0)
	yellow.lean = -fd * 0.1
	yellow.tilt = -fd * 0.08
	var p: Vector2 = _star_behind(blue)
	cur_star = Vector4(p.x,p.y,SR,0.1)
	cur_star_sq = 0.0
	cur_star_mood = 1
	cur_star_back = true
	cur_ghost = 1.0
	cur_board = Vector4.ZERO
	cur_pebble = 0.0
	cur_gap = 0.0
	cur_pull = 0.0
	cur_trail = false

func _compose() -> void:
	if _reduced:
		_static_pose()
		return
	blue.reset()
	yellow.reset()
	cur_gap = 0.0
	cur_pull = 0.0
	cur_star = Vector4.ZERO
	cur_star_sq = 0.0
	cur_star_mood = 0
	cur_star_back = false
	cur_ghost = 0.0
	cur_board = Vector4.ZERO
	cur_pebble = 0.0
	cur_trail = false
	if mode == MODE_INTRO:
		_intro_pose(iu)
	else:
		_loop_pose(u)
	if react_age < REACT_LEN and not _stage_active():
		_react_pose()
	if leaving:
		var e: float = _ease_io(clampf(leave_age / LEAVE_LEN,0.0,1.0))
		blue.lift -= 90.0 * e
		yellow.lift -= 90.0 * e
		cur_star.z *= 1.0 - e
		cur_gap = 0.0
		cur_pull *= 1.0 - e
		cur_ghost *= 1.0 - e
		cur_board.w *= 1.0 - e
		cur_pebble *= 1.0 - e
		cur_trail = false

# ---------------------------------------------------------------- sparks

func _burst(at: Vector2, count: int, col: Color, speed: float, loose: bool, kind: int = -1) -> void:
	for n in range(count):
		var i: int = _spark_head
		_spark_head = (_spark_head + 1) % MAX_SPARKS
		var angle: float = _rng.randf_range(0.0,TAU)
		var spd: float = _rng.randf_range(0.4,1.0) * speed
		var vy: float = sin(angle) * spd * 0.8 if loose else absf(sin(angle)) * spd * 0.35
		spark_pos[i] = at
		spark_vel[i] = Vector2(cos(angle) * spd,vy)
		spark_life[i] = _rng.randf_range(0.35,0.7)
		spark_max[i] = spark_life[i]
		spark_kind[i] = kind if kind >= 0 else n % 3
		spark_col[i] = col
		spark_free[i] = 1 if loose else 0

func _update_sparks(dt: float) -> void:
	_sparks_alive = 0
	for i in range(MAX_SPARKS):
		if spark_life[i] <= 0.0: continue
		spark_life[i] -= dt
		var v: Vector2 = spark_vel[i]
		v *= 1.0 - minf(4.0 * dt,0.9)
		v.y += (140.0 if spark_free[i] == 1 else 60.0) * dt
		spark_vel[i] = v
		var p: Vector2 = spark_pos[i] + v * dt
		spark_pos[i] = p
		if p.y > FLOOR_Y + 2.0 or (spark_free[i] == 0 and p.y < 703.0): spark_life[i] = 0.0
		if spark_life[i] > 0.0: _sparks_alive += 1

func _draw_sparks() -> void:
	for i in range(MAX_SPARKS):
		if spark_life[i] <= 0.0: continue
		var ratio: float = clampf(spark_life[i] / maxf(0.01,spark_max[i]),0.0,1.0)
		var col: Color = Color(spark_col[i],ratio)
		var p: Vector2 = spark_pos[i]
		var kind: int = spark_kind[i]
		if kind == 0:
			draw_circle(p,0.8 + 1.7 * ratio,col)
		elif kind == 1:
			draw_line(p,p - spark_vel[i] * 0.05,col,2.0,true)
		else:
			draw_set_transform(p,spark_life[i] * 6.0,Vector2.ONE * (1.2 + 3.4 * ratio))
			draw_colored_polygon(_star_pts,col)
			draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

# ---------------------------------------------------------------- drawing

func _deform(x: float, pull: float) -> float:
	var d: float = pull * exp(-pow((x - ax) / 42.0,2.0))
	for i in range(RING_SLOTS):
		var age: float = ring_age[i]
		if age >= RING_LIFE: continue
		var dist: float = absf(x - ring_x[i])
		var local_t: float = age - dist / 360.0
		if local_t <= 0.0: continue
		d += ring_amp[i] * exp(-local_t * 5.5) * cos(local_t * 34.0) * exp(-dist / 190.0)
	return clampf(d,-2.5,12.0)

func _line_run(xa: float, xb: float, pull: float) -> void:
	if xb <= xa + 0.5: return
	_run_pts.clear()
	var n: int = maxi(2,ceili((xb - xa) / 8.0) + 1)
	for i in range(n):
		var x: float = lerpf(xa,xb,float(i) / float(n - 1))
		_run_pts.append(Vector2(x,_ul_base(x) + _deform(x,pull)))
	draw_polyline(_run_pts,GOLD,3.0,true)

func _draw_underline() -> void:
	var deformed: bool = cur_gap > 0.05 or absf(cur_pull) > 0.05 or _ring_live()
	if not deformed or _reduced:
		draw_polyline(plain_line,GOLD,3.0,true)
		return
	if cur_gap > 0.05:
		_line_run(ul_a.x,minf(ax - cur_gap,ul_c.x),cur_pull)
		_line_run(maxf(ax + cur_gap,ul_a.x),ul_c.x,cur_pull)
		for si in range(2):
			var ex: float = ax - cur_gap if si == 0 else ax + cur_gap
			if ex > ul_a.x and ex < ul_c.x:
				draw_circle(Vector2(ex,_ul_base(ex) + _deform(ex,cur_pull)),1.6,GOLD)
	else:
		_line_run(ul_a.x,ul_c.x,cur_pull)
	# A bright glint rides the wave out along the line.
	for i in range(RING_SLOTS):
		if ring_amp[i] < 4.0 or ring_age[i] > 0.55: continue
		var front: float = ring_age[i] * 360.0
		var a: float = 1.0 - ring_age[i] / 0.55
		for si in range(2):
			var gx: float = ring_x[i] - front if si == 0 else ring_x[i] + front
			if gx < ul_a.x or gx > ul_c.x: continue
			var gy: float = _ul_base(gx) + _deform(gx,cur_pull)
			draw_line(Vector2(gx - 5.0,gy),Vector2(gx + 5.0,gy),Color(GOLD_HI,a),2.6,true)

## A restrained graphite wash and a pencilled floor line behind the staging area keep faces readable on the poster.
func _draw_stage_wash() -> void:
	if _wash < 0.02: return
	var lo: float = minf(gm_ax,gm_yc)
	var hi: float = maxf(gm_ax,gm_yc)
	var cx: float = (lo + hi) * 0.5
	var hw: float = (hi - lo) * 0.5 + 80.0
	for i in range(5):
		var s: float = 1.0 - float(i) * 0.17
		draw_set_transform(Vector2(cx,FLOOR_Y - 8.0),0.0,Vector2(hw * s,56.0 * s))
		draw_colored_polygon(_unit_circle,Color(0.015,0.016,0.035,0.085 * _wash))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	var xa: float = lo - 34.0
	var xb: float = hi + 34.0
	var floor_a: PackedVector2Array = PackedVector2Array()
	for i in range(7):
		var x: float = lerpf(xa,xb,float(i) / 6.0)
		floor_a.append(Vector2(x,FLOOR_Y + 1.8 + sin(float(i) * 1.7 + 0.6) * 0.6))
	draw_polyline(floor_a,Color(PENCIL,0.32 * _wash),1.5,true)
	draw_line(Vector2(xa + 22.0,FLOOR_Y + 3.6),Vector2(xb - 40.0,FLOOR_Y + 3.3),Color(PENCIL,0.16 * _wash),1.2,true)

func _draw_ghost() -> void:
	if cur_ghost < 0.02: return
	for i in range(10):
		var a: Vector2 = gm_home + _star_pts[i] * SR
		var b: Vector2 = gm_home + _star_pts[(i + 1) % 10] * SR
		draw_line(a,a.lerp(b,0.55),Color(PENCIL,0.6 * cur_ghost),1.6,true)

func _draw_pebble() -> void:
	if cur_pebble < 0.02: return
	var c: Vector2 = Vector2(gm_xt + gm_d * 14.0,FLOOR_Y - 2.0)
	var rock: PackedVector2Array = PackedVector2Array([c + Vector2(-7.0,2.0),c + Vector2(-5.0,-4.0),c + Vector2(0.0,-6.5),c + Vector2(5.5,-3.5),c + Vector2(7.5,2.0)])
	draw_colored_polygon(rock,Color(0.2,0.19,0.24,cur_pebble))
	var outline: PackedVector2Array = rock.duplicate()
	outline.append(rock[0])
	draw_polyline(outline,Color(PENCIL,0.85 * cur_pebble),1.8,true)
	draw_line(c + Vector2(-2.0,-2.0),c + Vector2(2.5,-3.5),Color(PENCIL,0.6 * cur_pebble),1.2,true)

func _draw() -> void:
	_compose()
	_draw_stage_wash()
	if focus_btn != null:
		_draw_underline()
		draw_polyline(caret,GOLD,3.0,true)
	_draw_ghost()
	_draw_pebble()
	_draw_loose_board()
	if cur_trail:
		var prev: Vector4 = cur_star
		var t0: float = _stage_time()
		for k in range(1,6):
			var s2: Vector4 = _ball(t0 - 0.03 * float(k))
			if s2.z < 0.5: break
			var fade: float = 1.0 - float(k) / 6.0
			draw_line(Vector2(prev.x,prev.y),Vector2(s2.x,s2.y),Color(GOLD,0.55 * fade),maxf(1.0,s2.z * 0.55 * fade),true)
			prev = s2
	if cur_star_back: _draw_star(cur_star)
	_draw_doodle(blue)
	_draw_doodle(yellow)
	if not cur_star_back: _draw_star(cur_star)
	_draw_marks(blue)
	_draw_marks(yellow)
	if not _reduced: _draw_sparks()
	else: _draw_static_glints()

func _draw_static_glints() -> void:
	if cur_ghost > 0.5: return
	var p: Vector2 = Vector2(cur_star.x,cur_star.y)
	var r: float = cur_star.z
	for i in range(4):
		var angle: float = -PI * 0.5 + (float(i) - 1.5) * 0.9
		var dir: Vector2 = Vector2(cos(angle),sin(angle))
		draw_line(p + dir * (r + 4.0),p + dir * (r + 9.0),Color(GOLD_HI,0.85),2.0,true)

func _draw_star(c: Vector4) -> void:
	var r: float = c.z
	if r < 0.5: return
	var sq: float = cur_star_sq
	draw_set_transform(Vector2(c.x,c.y),c.w,Vector2(r * (1.0 + sq),r * (1.0 - sq * 0.5)))
	draw_circle(Vector2.ZERO,1.55,Color(GOLD,0.18))
	draw_colored_polygon(_star_pts,GOLD)
	draw_polyline(_star_closed,INK,clampf(1.8 + r * 0.14,2.4,3.8) / r,true)
	draw_circle(Vector2(-0.18,-0.2),0.16,Color(GOLD_HI,0.9))
	if r >= 7.0:
		var worried: bool = cur_star_mood == 1
		var er: float = 0.15 if worried else 0.12
		draw_circle(Vector2(-0.23,0.04),er,INK)
		draw_circle(Vector2(0.23,0.04),er,INK)
		if worried:
			draw_circle(Vector2(0.0,0.3),0.08,INK)
		elif cur_star_mood == 2:
			draw_polyline(PackedVector2Array([Vector2(-0.18,0.2),Vector2(0.0,0.36),Vector2(0.18,0.2)]),INK,1.5 / r,true)
		else:
			draw_polyline(PackedVector2Array([Vector2(-0.15,0.23),Vector2(0.0,0.32),Vector2(0.15,0.23)]),INK,1.4 / r,true)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

## One skateboard shape around the local origin: deck on top, two wheels below.
func _board_shape(w: float, wi: float, rot: float) -> void:
	var p0: Vector2 = Vector2(-10.0,0.0).rotated(rot)
	var p1: Vector2 = Vector2(10.0,0.0).rotated(rot)
	draw_line(p0,p1,INK,wi * 1.5,true)
	draw_line(p0,p1,GOLD,w * 1.2,true)
	for si in range(2):
		var wheel: Vector2 = Vector2(-6.0 if si == 0 else 6.0,2.6).rotated(rot)
		draw_circle(wheel,2.2,INK)
		draw_circle(wheel,1.2,CREAM)

func _draw_loose_board() -> void:
	if cur_board.w < 0.03: return
	var w: float = LINE_PX / CS
	draw_set_transform(Vector2(cur_board.x,cur_board.y),cur_board.z,Vector2(CS,CS))
	_board_shape(w,w + 2.0 / CS,0.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

## Hand-inked arm points (shoulder, elbow, hand) in body-local units for the active arm mode.
func _arm(d: Doodle, ai: int) -> PackedVector2Array:
	var f: float = _ef(d)
	var sh: Vector2 = Vector2(0.0,-17.0)
	var front: bool = ai == 1
	var s: float = f if front else -f
	match d.arm_mode:
		1:
			return PackedVector2Array([sh,sh + Vector2(s * 8.0,4.5),Vector2(s * 3.2,-9.6)])
		2:
			if front: return PackedVector2Array([sh,Vector2(f * 5.6,-12.5),Vector2(-f * 4.0,-16.0)])
			return PackedVector2Array([sh,Vector2(-f * 5.0,-12.0),Vector2(f * 4.2,-14.6)])
		3:
			if front: return PackedVector2Array([sh,Vector2(f * 9.5,-26.0),Vector2(f * 4.5 + d.fidget * 1.4,-38.5)])
		4:
			if front: return PackedVector2Array([sh,Vector2(f * 4.5,-10.5),Vector2(f * 10.0,-13.5)])
			return PackedVector2Array([sh,Vector2(f * 2.8,-11.0),Vector2(f * 7.0,-16.5)])
		5:
			if front: return PackedVector2Array([sh,Vector2(f * 7.0,-14.0),Vector2(f * 2.6,-23.0)])
		6:
			if front: return PackedVector2Array([sh,Vector2(-f * 3.0,-12.5),Vector2(-f * 7.5,-11.0)])
			return PackedVector2Array([sh,Vector2(-f * 3.4,-13.0),Vector2(-f * 8.0,-13.2)])
		7:
			return PackedVector2Array([sh,sh + Vector2(s * 7.5,2.0),Vector2(s * 10.0,-21.5)])
		8:
			return PackedVector2Array([sh,Vector2(s * 7.0,-22.0),Vector2(s * 11.0,-30.0)])
	var angle: float = d.arm_f if front else d.arm_b
	var dir: Vector2 = Vector2(f * sin(angle),cos(angle))
	var elbow: Vector2 = sh + dir * 5.5 + Vector2(-dir.y,dir.x) * 1.6 * f
	return PackedVector2Array([sh,elbow,sh + dir * 10.5])

func _draw_doodle(d: Doodle) -> void:
	var sc: float = CS * d.shown
	if sc < 0.06: return
	var f: float = _ef(d)
	var col: Color = d.tint
	var w: float = LINE_PX / sc
	var wi: float = (LINE_PX + 2.4) / sc
	var sy: float = sc * maxf(d.squash,0.2)
	draw_set_transform(Vector2(d.pos.x,d.pos.y - d.lift),d.lean,Vector2(sc * _wide(d),sy))
	if d.speed > 0.05:
		for i in range(3):
			var ly: float = -8.0 - float(i) * 9.0
			draw_line(Vector2(-f * (11.0 + float(i) * 3.0),ly),Vector2(-f * (26.0 + float(i) * 8.0 * d.speed),ly),Color(col,0.65 * d.speed),w * 0.7,true)
	if d.board == 1:
		draw_set_transform(Vector2(d.pos.x,d.pos.y - d.lift) + Vector2(0.0,-d.board_drop * sc).rotated(d.lean),d.lean,Vector2(sc,sc))
		_board_shape(w,wi,d.board_tilt)
		draw_set_transform(Vector2(d.pos.x,d.pos.y - d.lift),d.lean,Vector2(sc * _wide(d),sy))
	var hip: Vector2 = Vector2(0.0,-9.0)
	var st: float = clampf(d.stride,0.0,1.6)
	var stance: float = 5.2 if d.board == 1 else 3.5
	var front_leg: int = 1 if f > 0.0 else 0
	var feet: PackedVector2Array = PackedVector2Array([Vector2.ZERO,Vector2.ZERO])
	for i in range(2):
		var ph: float = d.walk + float(i) * PI
		var base_x: float = -stance if i == 0 else stance
		var foot: Vector2 = Vector2(base_x * (1.0 - minf(st,1.0)) + sin(ph) * 6.5 * st * f,-maxf(0.0,cos(ph)) * 4.0 * minf(st,1.4))
		var knee_push: float = 1.0 + 1.4 * st
		if i == front_leg:
			if absf(d.kick) > 0.01:
				foot = Vector2(f * (3.5 + d.kick * 10.0),-absf(d.kick) * 4.5)
				knee_push += 1.5 * absf(d.kick)
			foot.y -= d.tap * 3.0
		feet[i] = foot
		var knee: Vector2 = (hip + foot) * 0.5 + Vector2(f * knee_push,0.0)
		_limbs[i] = PackedVector2Array([hip,knee,foot])
	var sh: Vector2 = Vector2(0.0,-17.0)
	_limbs[2] = PackedVector2Array([hip,(hip + sh) * 0.5 + Vector2(f * 0.5,0.0),sh])
	_limbs[3] = _arm(d,0)
	_limbs[4] = _arm(d,1)
	for i in range(4): draw_polyline(_limbs[i],INK,wi,true)
	for i in range(4): draw_polyline(_limbs[i],col,w,true)
	for i in range(2):
		var toe: Vector2 = feet[i] + Vector2(f * 3.2,0.0)
		draw_line(feet[i],toe,INK,wi,true)
		draw_line(feet[i],toe,col,w,true)
	var hc: Vector2 = Vector2(0.0,-28.0)
	for i in range(40):
		d.head_pts[i] = hc + (d.ring[i] * HR).rotated(d.tilt)
	draw_polyline(d.head_pts,Color(col,0.2),w * 2.8,true)
	draw_circle(hc,HR * 0.95,Color(0.02,0.025,0.06,0.94))
	draw_polyline(d.head_pts,INK,(LINE_PX * 1.15 + 2.4) / sc,true)
	draw_polyline(d.head_pts,col,LINE_PX * 1.15 / sc,true)
	for i in range(20):
		d.echo_pts[i] = hc + (d.echo[i] * HR).rotated(d.tilt)
	draw_polyline(d.echo_pts,Color(col,0.4),1.3 / sc,true)
	_draw_face(d,hc,sc)
	var front_arm: PackedVector2Array = _limbs[4]
	draw_polyline(front_arm,INK,wi,true)
	draw_polyline(front_arm,col,w,true)
	if d.arm_mode == 5:
		var tip: Vector2 = front_arm[2]
		draw_line(tip,tip + Vector2(0.0,-4.6),INK,wi,true)
		draw_line(tip,tip + Vector2(0.0,-4.6),col,w,true)
	for ai in range(2):
		var limb: PackedVector2Array = _limbs[3 + ai]
		draw_circle(limb[2],w * 0.95,col)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_face(d: Doodle, hc: Vector2, sc: float) -> void:
	var f: float = _ef(d)
	var thin: float = 1.7 / sc * CS
	var shift: float = d.look.x * 1.9
	var open: float = d.eye_open
	var blink: bool = open > 0.8 and fmod(_clock + d.phase_seed * 1.7,3.4) < 0.13
	var rot: float = d.tilt
	var ey: float = -1.5 + d.look.y * 0.6
	var er: float = 2.7
	for si in range(2):
		var ex: float = (-4.3 if si == 0 else 4.3) + shift
		var eye: Vector2 = hc + Vector2(ex,ey).rotated(rot)
		if open <= -0.5:
			# Beaming closed eye: a small arch.
			var arch: PackedVector2Array = PackedVector2Array()
			for k in range(5):
				var a: float = PI + PI * float(k) / 4.0
				arch.append(hc + Vector2(ex + cos(a) * er,ey + 1.0 + sin(a) * er * 0.9).rotated(rot))
			draw_polyline(arch,CREAM,thin,true)
		elif blink or open < 0.35:
			draw_line(hc + Vector2(ex - er,ey).rotated(rot),hc + Vector2(ex + er,ey).rotated(rot),CREAM,thin,true)
		else:
			var oy: float = er * clampf(open,0.0,1.4)
			for k in range(10):
				_eye_pts[k] = hc + Vector2(ex + _eye_unit[k].x * er,ey + _eye_unit[k].y * oy).rotated(rot)
			draw_colored_polygon(_eye_pts,CREAM)
			var po: Vector2 = Vector2(clampf(d.look.x,-1.0,1.0) * 1.2,clampf(d.look.y,-1.0,1.0) * 1.0 * minf(open,1.0))
			draw_circle(hc + Vector2(ex + po.x,ey + po.y).rotated(rot),1.35 * d.pupil,INK)
		if open > -0.5:
			# Colored ink eyebrow; the inner end drops when scheming, lifts when worried.
			var lid: float = 0.55 if open < 0.7 else 0.0
			var by: float = ey - er * minf(maxf(open,0.4),1.4) - 2.0 - lid
			var outer_x: float = ex + (-2.4 if si == 0 else 2.4)
			var inner_x: float = ex + (2.2 if si == 0 else -2.2)
			var inner_y: float = by + d.brow * 2.2
			var outer_y: float = by - d.brow * 0.5
			draw_line(hc + Vector2(outer_x,outer_y).rotated(rot),hc + Vector2(inner_x,inner_y).rotated(rot),d.tint,thin * 1.1,true)
	if d.blush > 0.03:
		var ba: Color = Color(d.tint,0.85 * d.blush)
		for si in range(2):
			var cx: float = (-7.2 if si == 0 else 7.2) + shift * 0.6
			for k in range(3):
				var o: Vector2 = Vector2(cx + float(k) * (1.1 if si == 1 else -1.1),2.8 + float(k) * 0.3 - 0.4)
				draw_line(hc + o.rotated(rot),hc + (o + Vector2(0.9,1.9)).rotated(rot),ba,thin * 0.8,true)
	var mx: float = shift * 0.8
	var my: float = 0.0
	var pts: PackedVector2Array = PackedVector2Array()
	match d.mouth:
		1:
			draw_arc(hc + Vector2(mx,5.4).rotated(rot),2.1,0.0,TAU,12,CREAM,thin,true)
		2:
			for p: Vector2 in [Vector2(-3.8,4.0),Vector2(3.8,4.0),Vector2(2.5,7.4),Vector2(0.0,8.3),Vector2(-2.5,7.4)]:
				pts.append(hc + (Vector2(mx,my) + p).rotated(rot))
			draw_colored_polygon(pts,CREAM)
		3:
			for p: Vector2 in [Vector2(-3.2,5.2),Vector2(-1.1,6.6),Vector2(1.1,4.0),Vector2(3.2,5.4)]:
				pts.append(hc + (Vector2(mx,my) + p).rotated(rot))
			draw_polyline(pts,CREAM,thin,true)
		4:
			for p: Vector2 in [Vector2(-3.0,5.8),Vector2(0.5,6.4),Vector2(2.6,5.4),Vector2(4.0,3.6)]:
				pts.append(hc + (Vector2(mx,my) + p).rotated(rot))
			draw_polyline(pts,CREAM,thin,true)
		5:
			draw_line(hc + (Vector2(mx,my) + Vector2(-3.2,5.6)).rotated(rot),hc + (Vector2(mx,my) + Vector2(3.2,5.6)).rotated(rot),CREAM,thin,true)
		6:
			for p: Vector2 in [Vector2(-3.4,7.2),Vector2(-1.4,5.2),Vector2(1.4,5.2),Vector2(3.4,7.2)]:
				pts.append(hc + (Vector2(mx,my) + p).rotated(rot))
			draw_polyline(pts,CREAM,thin,true)
		7:
			for p: Vector2 in [Vector2(-3.8,5.4),Vector2(-1.9,6.8),Vector2(0.0,5.2),Vector2(1.9,6.8),Vector2(3.8,4.6)]:
				pts.append(hc + (Vector2(mx,my) + p).rotated(rot))
			draw_polyline(pts,CREAM,thin,true)
		8:
			draw_circle(hc + (Vector2(mx,my) + Vector2(f * 0.8,6.0)).rotated(rot),1.5,CREAM)
		9:
			var mc: Vector2 = hc + (Vector2(mx,my) + Vector2(0.0,6.4)).rotated(rot)
			draw_circle(mc,3.0,CREAM)
			draw_circle(mc,1.9,Color(0.05,0.03,0.06))
		_:
			for p: Vector2 in [Vector2(-3.4,4.6),Vector2(0.0,6.8),Vector2(3.4,4.6)]:
				pts.append(hc + (Vector2(mx,my) + p).rotated(rot))
			draw_polyline(pts,CREAM,thin,true)

# ---------------------------------------------------------------- reaction marks (hand-inked, canvas space)

func _glyph(p: Vector2, bang: bool, a: float) -> void:
	var ink: Color = Color(INK,a)
	var cream: Color = Color(1.0,0.96,0.78,a)
	if bang:
		draw_line(p + Vector2(0.0,-15.0),p + Vector2(0.0,-5.0),ink,6.2,true)
		draw_line(p + Vector2(0.0,-15.0),p + Vector2(0.0,-5.0),cream,3.4,true)
		draw_circle(p + Vector2(0.0,0.0),3.6,ink)
		draw_circle(p + Vector2(0.0,0.0),2.2,cream)
	else:
		var q: PackedVector2Array = PackedVector2Array([Vector2(-4.5,-12.0),Vector2(-3.0,-16.0),Vector2(1.0,-17.5),Vector2(5.0,-14.5),Vector2(4.5,-10.5),Vector2(0.0,-7.5),Vector2(0.0,-5.0)])
		for i in range(q.size()): q[i] += p
		draw_polyline(q,ink,6.2,true)
		draw_polyline(q,cream,3.4,true)
		draw_circle(p,3.6,ink)
		draw_circle(p,2.2,cream)

func _draw_marks(d: Doodle) -> void:
	if d.mark < 0.03 or d.shown < 0.5: return
	var a: float = d.mark
	var f: float = _ef(d)
	var hw: Vector2 = _world(d,Vector2(0.0,-28.0))
	var hr: float = HR * CS
	var top: Vector2 = hw + Vector2(0.0,-hr - 7.0)
	var ink: Color = Color(INK,a)
	var cream: Color = Color(1.0,0.96,0.78,a)
	match d.mark_kind:
		1:
			_glyph(top,true,a)
		2:
			_glyph(top,false,a)
		3:
			_glyph(top + Vector2(-9.0,0.0),true,a)
			_glyph(top + Vector2(8.0,0.0),false,a)
		4:
			var c: Vector2 = hw + Vector2(-f * hr * 0.95,-hr * 0.6 + sin(_clock * 6.0) * 1.2)
			var drop: PackedVector2Array = PackedVector2Array([c + Vector2(0.0,-7.0),c + Vector2(3.6,0.0),c + Vector2(2.2,4.0),c + Vector2(-2.2,4.0),c + Vector2(-3.6,0.0)])
			draw_colored_polygon(drop,Color(SWEAT,a))
			var drop_line: PackedVector2Array = drop.duplicate()
			drop_line.append(drop[0])
			draw_polyline(drop_line,ink,1.8,true)
		5:
			var sp: PackedVector2Array = PackedVector2Array()
			for k in range(26):
				var ang: float = float(k) * 0.55 - _clock * 5.0
				var rad: float = 1.5 + float(k) * 0.32
				sp.append(top + Vector2(cos(ang) * rad,sin(ang) * rad * 0.7 - 4.0))
			draw_polyline(sp,ink,4.6,true)
			draw_polyline(sp,cream,2.2,true)
		6:
			var bob: float = sin(_clock * 7.0) * 2.5
			var n: Vector2 = hw + Vector2(f * (hr + 9.0),-hr * 0.2 - 4.0 + bob)
			draw_line(n + Vector2(3.0,0.0),n + Vector2(3.0,-12.0),ink,5.2,true)
			draw_line(n + Vector2(3.0,-12.0),n + Vector2(9.0,-8.0),ink,5.2,true)
			draw_circle(n,4.4,ink)
			draw_line(n + Vector2(3.0,0.0),n + Vector2(3.0,-12.0),cream,2.4,true)
			draw_line(n + Vector2(3.0,-12.0),n + Vector2(9.0,-8.0),cream,2.4,true)
			draw_circle(n,3.0,cream)
		7:
			var pulse: float = 1.0 + 0.12 * sin(_clock * 18.0)
			for k in range(7):
				var ang: float = -PI * 0.92 + PI * 0.84 * float(k) / 6.0
				var dir: Vector2 = Vector2(cos(ang),sin(ang))
				var r0: float = hr + 7.0
				var r1: float = hr + (15.0 if k % 2 == 0 else 11.0) * pulse
				draw_line(hw + dir * r0,hw + dir * r1,ink,5.4,true)
				draw_line(hw + dir * r0,hw + dir * r1,Color(GOLD_HI,a),2.6,true)
