extends Control
## Title footer comedy: Blue and Yellow fight over the star that lives in the golden selection underline.
## Every pose is a pure function of cosmetic time, so there are no tweens, timers or extra nodes to clean up.
## The gag is staged in the label gaps beside the selected underline: Blue sneaks in at the underline's end, skates
## to the second gap beyond it, and Yellow catches the star there. Four shorter gags follow it in rotation.
## Props (pencil, moustaches, snot bubble) and handwritten sound effects are cleared and rebuilt from time every frame.
const INK := Color("070810")
const GOLD := Color("ffb539")
const GOLD_HI := Color("ffe2a0")
const CREAM := Color("fff0d7")
const DUST := Color("d9c28a")
const PENCIL := Color("dcd2bc")
const SWEAT := Color("8fd0ff")
const BLUE := Color("4f9dff")
const YELLOW := Color("ffd52e")
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const PINK := Color("ff8fa3")
const MODE_INTRO := 0
const MODE_LOOP := 1
# Five vignettes of deliberately different lengths (see _act_len): the long heist, then four quick gags.
const ACT_COUNT: int = 5
const LOOP_LEN: float = 47.9
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
# Per-vignette timing, in seconds from the start of that vignette. Each one ends 0.3 s before its _act_len.
const PLUCK_AT: Array = [1.5,1.95,2.4,2.8,3.15,3.5,3.85,4.2,4.55,4.9,5.25]
const PLUCK_BIG: float = 5.95
const PLUCK_LAND: float = 6.55
const PLUCK_TOSS: float = 7.15
const PLUCK_HOME: float = 7.6
const PLUCK_END: float = 8.1
const SNOOZE_END: float = 10.3
const WHACK_POPS: Array = [0.8,2.05,3.3,4.4,5.6,5.7]
const WHACK_END: float = 7.5
const HIC_Y: Array = [4.1,4.65,5.55,7.0,7.45,7.95]
const HIC_B: Array = [5.2,6.0,7.0,7.45,7.95]
const HIC_S: Array = [6.45,7.0,7.45,7.95]
const HICCUP_END: float = 8.9

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
	var bubble: float = 0.0
	var stache: float = 0.0

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
		bubble = 0.0
		stache = 0.0

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
# Extras used by the newer vignettes: the star's gaze, a pencil prop and one handwritten sound effect.
var cur_look: Vector2 = Vector2.ZERO
var cur_stache: bool = false
var cur_pencil: Vector4 = Vector4.ZERO
var cur_word: String = ""
var cur_word_at: Vector2 = Vector2.ZERO
var cur_word_f: float = 0.0
var cur_word_size: int = 22
var cur_word_tilt: float = 0.0
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

func _act_len(act: int) -> float:
	match act:
		0: return 11.9
		1: return 8.4
		2: return 10.6
		3: return 7.8
	return 9.2

func _act_start(act: int) -> float:
	var total: float = 0.0
	for i in range(act): total += _act_len(i)
	return total

func _act_at(x: float) -> int:
	var total: float = 0.0
	for i in range(ACT_COUNT):
		total += _act_len(i)
		if x < total: return i
	return ACT_COUNT - 1

## Each act is empty underline for its first T_ON seconds and its last 0.3 s, so the stage breathes between gags.
func _stage_active() -> bool:
	if mode == MODE_INTRO: return iu >= 0.25
	var act: int = _act_at(u)
	var beat: float = u - _act_start(act)
	return beat >= T_ON and beat < _act_len(act) - 0.3

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
		if u >= LOOP_LEN: u -= LOOP_LEN
		# The stage is empty at every act boundary, so that is when a mirrored layout may swap sides.
		if _act_at(previous) != _act_at(u): dirn = target_dir
	_update_sparks(dt)
	var active: bool = _stage_active() or leaving or react_age < REACT_LEN or _sparks_alive > 0 or _ring_live() or _wash > 0.01
	if active or _drawn_active: queue_redraw()
	_drawn_active = active

## After a focus change the next vignette in the rotation plays, so quick browsing never repeats the same opener.
func _finish_leave() -> void:
	leaving = false
	leave_age = 0.0
	if mode == MODE_LOOP: u = _act_start((_act_at(u) + 1) % ACT_COUNT)
	else: u = 0.0
	mode = MODE_LOOP
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

## Where the star sits when perched on a doodle's head.
func _star_crown(d: Doodle) -> Vector2:
	return _world(d,Vector2(0.0,-44.0))

func _hand_front(d: Doodle) -> Vector2:
	return _world(d,_arm(d,1)[2])

func _head_top(d: Doodle) -> Vector2:
	return _world(d,Vector2(0.0,-28.0)) + Vector2(0.0,-HR * CS - 8.0)

## Pop-in out of the floor after t_in and drop-away before t_out, added on top of whatever lift the pose set.
## Pass a negative t_in for doodles that already rise by themselves (see _hole).
func _bookend(d: Doodle, t: float, t_in: float, t_out: float) -> void:
	if t < t_in + 0.4:
		var f: float = _seg(t,t_in,t_in + 0.4)
		d.lift -= 84.0 * (1.0 - _pop(f))
		d.squash *= 1.0 - 0.12 * sin(PI * _seg(f,0.65,1.0))
	elif t > t_out - 0.35:
		var g: float = _seg(t,t_out - 0.35,t_out)
		d.lift -= 90.0 * _ease_in(g)
		d.squash *= 1.0 - 0.1 * sin(PI * minf(g * 2.0,1.0))

## Whack-a-mole lift: under the floor, springs up at t_up, ducks back down from t_down.
func _hole(t: float, t_up: float, t_down: float) -> float:
	if t < t_up: return -90.0
	if t < t_up + 0.28: return -84.0 * (1.0 - _pop(_seg(t,t_up,t_up + 0.28)))
	if t < t_down: return 0.0
	return -90.0 * _ease_in(_seg(t,t_down,t_down + 0.2))

## Half-sine pulse of the most recent event in times (seconds), lasting dur; 0 when none is running.
func _pulse(t: float, times: Array, dur: float) -> float:
	for s in times:
		var age: float = t - float(s)
		if age >= 0.0 and age < dur: return sin(PI * age / dur)
	return 0.0

func _strum_index(t: float) -> int:
	var idx: int = -1
	for i in range(PLUCK_AT.size()):
		if t >= float(PLUCK_AT[i]): idx = i
	return idx

## One handwritten sound effect at a time; the last call that is still running in a frame wins.
func _say(words: String, at: Vector2, t: float, t0: float, life: float, font_px: int, tilt: float, rise: float) -> void:
	var age: float = t - t0
	if age < 0.0 or age >= life: return
	cur_word = words
	cur_word_at = Vector2(at.x,minf(at.y,636.0) - rise * age / life)
	cur_word_f = _pop(minf(age / 0.12,1.0)) * (1.0 - smoothstep(life - 0.25,life,age))
	cur_word_size = font_px
	cur_word_tilt = tilt

## The star resting in (and riding) the underline: pops in at t_in, sinks back at t_out, hop lifts it off the string.
func _star_rest(t: float, t_in: float, t_out: float, hop: float) -> Vector4:
	if t < t_in or t >= t_out: return Vector4.ZERO
	var z: float = SR * _pop(_seg(t,t_in,t_in + 0.3)) * (1.0 - _ease_io(_seg(t,t_out - 0.3,t_out)))
	var ride: float = _deform(gm_ax,cur_pull)
	cur_star_sq = clampf(ride * 0.03,-0.08,0.3)
	return Vector4(gm_home.x,gm_home.y + ride - hop,z,0.06 * sin(t * 3.0))

## Every per-frame prop and text effect starts cleared, so nothing leaks from one vignette (or the static pose) into the next.
func _clear_props() -> void:
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
	cur_look = Vector2.ZERO
	cur_stache = false
	cur_pencil = Vector4.ZERO
	cur_word = ""
	cur_word_at = Vector2.ZERO
	cur_word_f = 0.0
	cur_word_size = 22
	cur_word_tilt = 0.0

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

# ---------------------------------------------------------------- loop choreography (five vignettes, 47.9 s per cycle)
# 0 The Underline Heist (11.9 s): the original star-stealing story.
# 1 Boing (8.4 s): the underline is a guitar string; Blue's jam session ends with the star landing on Yellow's head.
# 2 Snooze (10.6 s): Blue nods off with a snot bubble, Yellow draws a pencil moustache, and the star gets one too.
# 3 Whack-a-Doodle (7.8 s): a game of peekaboo from the floor in which nobody ever looks the right way.
# 4 Hiccups (9.2 s): a "BOO!" ambush that backfires, then the hiccups are contagious, star included.
# Heist beats: 0.8 Blue peeks, 1.3 tiptoes in, 2.0 winds up, 2.4 pulls the star out of the line, 3.15 smirks, 3.75 hops
# on a board and skates off, 5.05 hits a pebble, 5.4 faceplants while Yellow hurdles him and catches the star, 6.0
# Yellow celebrates far too early, 7.3 Yellow tosses the star up and Blue snatches it, 8.05 Blue whistles innocently,
# 8.45 Yellow's double-take, 8.8 mock offence, 9.35 Blue's sheepish grin, 10.4 Blue punts the star home.

func _loop_pose(t: float) -> void:
	var act: int = _act_at(t)
	var beat: float = t - _act_start(act)
	match act:
		0: _heist_pose(beat)
		1: _pluck_pose(beat)
		2: _snooze_pose(beat)
		3: _whack_pose(beat)
		_: _hiccup_pose(beat)

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

## Events are keyed to each vignette's own clock, so every act's cues are written in the same local seconds as its pose.
## Sparks emitted above the underline row are always loose; non-loose ones are culled while above y = 703.
func _loop_events(prev: float, cur: float) -> void:
	for act in range(ACT_COUNT):
		var start: float = _act_start(act)
		var finish: float = start + _act_len(act)
		if cur <= start or prev >= finish: continue
		var local_prev: float = maxf(prev,start) - start
		var local_cur: float = minf(cur,finish) - start
		match act:
			0: _heist_events(local_prev,local_cur)
			1: _pluck_events(local_prev,local_cur)
			2: _snooze_events(local_prev,local_cur)
			3: _whack_events(local_prev,local_cur)
			_: _hiccup_events(local_prev,local_cur)

# ---------------------------------------------------------------- vignette 1: Boing (8.4 s)

func _pluck_pose(t: float) -> void:
	_geom()
	_blue_pluck(blue,t)
	_yellow_pluck(yellow,t)
	if blue.shown > 0.5: _bookend(blue,t,0.8,PLUCK_END)
	if yellow.shown > 0.5: _bookend(yellow,t,3.3,PLUCK_END)
	cur_pull = _pluck_pull(t)
	cur_gap = GAP_HALF * smoothstep(PLUCK_BIG + 0.02,PLUCK_BIG + 0.12,t) * (1.0 - smoothstep(PLUCK_HOME - 0.1,PLUCK_HOME + 0.02,t))
	cur_ghost = smoothstep(PLUCK_BIG + 0.05,PLUCK_BIG + 0.25,t) * (1.0 - smoothstep(PLUCK_HOME - 0.1,PLUCK_HOME + 0.05,t))
	cur_star = _star_pluck(t)
	var fd: float = gm_d
	var above: Vector2 = Vector2(gm_ax,FLOOR_Y - 92.0)
	_say("plink",above,t,1.5,0.7,22,-0.1,8.0)
	_say("plonk",above,t,2.4,0.7,24,0.08,8.0)
	_say("BOING!",above,t,3.5,0.9,30,-0.06,10.0)
	_say("TWANG!",above + Vector2(fd * 20.0,-6.0),t,PLUCK_BIG,0.95,34,fd * 0.1,10.0)

## The underline is stretched down like a bowstring just before the big strum lets go.
func _pluck_pull(t: float) -> float:
	if t < 5.5 or t >= PLUCK_BIG: return 0.0
	var f: float = _seg(t,5.5,PLUCK_BIG)
	return 8.0 * _ease_io(f) + 0.6 * f * sin(t * 70.0)

## 1 when a strum has just landed, fading to 0 over a quarter second.
func _strum_kick(t: float) -> float:
	var idx: int = _strum_index(t)
	if idx < 0 or t >= 5.5: return 0.0
	return maxf(0.0,1.0 - (t - float(PLUCK_AT[idx])) / 0.26)

func _blue_pluck(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 0.8 or t >= PLUCK_END: return
	d.shown = 1.0
	_stand(d,gm_xb,0.0)
	d.look = Vector2(-fd,0.0)
	var kick: float = _strum_kick(t)
	if t < 1.5:
		# Tuning up: head cocked toward the string, one finger flicking at it.
		d.tilt = -fd * 0.12
		d.lean = -fd * 0.08
		d.arm_f = 0.9 + 0.12 * sin(t * 24.0)
		d.arm_b = 1.35
		d.brow = 0.4
		d.mouth = 4
		d.eye_open = 0.8
		d.look = Vector2(-fd,0.2)
	elif t < 5.5:
		# Jam session: every strum kicks him back a little; eyes squeezed shut in bliss once he gets going.
		d.lean = -fd * (0.1 + 0.2 * kick)
		d.lift = 2.0 * kick
		d.squash = 1.0 - 0.06 * kick
		d.tilt = fd * 0.1 * sin(t * 9.0)
		d.arm_f = 0.6 + 1.2 * kick
		d.arm_b = 1.35
		d.eye_open = -1.0 if t > 2.4 else 0.7
		d.mouth = 2 if t > 2.4 else 4
		d.brow = -0.2
	elif t < PLUCK_BIG:
		# Big wind-up: arm overhead, back arched, the whole string stretching with him.
		var f: float = _seg(t,5.5,PLUCK_BIG)
		var e: float = _ease_io(f)
		d.lean = fd * 0.35 * e + sin(t * 60.0) * 0.015 * f
		d.squash = 1.0 - 0.12 * e
		d.arm_f = lerpf(1.0,2.9,e)
		d.arm_b = 1.5
		d.tilt = fd * 0.1 * e
		d.eye_open = 1.1
		d.brow = 1.0
		d.mouth = 2
	elif t < 6.4:
		# TWANG: the strum swings through and he is thrown the other way.
		var g: float = _seg(t,PLUCK_BIG,6.4)
		var q: float = _ease_out(minf(g * 2.5,1.0))
		d.lean = lerpf(fd * 0.35,-fd * 0.4,q) * (1.0 - 0.5 * g)
		d.lift = 6.0 * sin(PI * minf(g * 2.0,1.0))
		d.squash = 1.0 + 0.1 * sin(PI * minf(g * 2.5,1.0))
		d.arm_f = lerpf(2.9,0.4,q)
		d.arm_b = 1.5
		d.eye_open = -1.0
		d.mouth = 2
		d.brow = -0.2
	elif t < 6.7:
		# Turns to see where the star went.
		var f: float = _seg(t,6.4,6.7)
		_flip(d,-fd,f)
		d.arm_f = lerpf(0.4,1.0,f)
		d.eye_open = 1.2
		d.brow = 0.3
		d.mouth = 1
		d.look = Vector2(fd,-0.3)
	elif t < 7.25:
		# Sheepish: it landed on Yellow's head.
		d.face = fd
		d.arm_mode = 3
		d.arm_b = -0.6
		d.fidget = sin(t * 20.0)
		d.blush = smoothstep(6.7,6.9,t)
		d.mouth = 7
		d.brow = -0.9
		d.tilt = fd * 0.14
		d.look = Vector2(fd * 0.3,0.8)
		d.mark_kind = 4
		d.mark = smoothstep(6.8,6.95,t) * (1.0 - smoothstep(7.05,7.25,t))
	elif t < PLUCK_HOME - 0.05:
		# Turns back just in time to watch the star get headbutted home.
		var f: float = _seg(t,7.25,7.55)
		_flip(d,fd,f)
		d.arm_f = lerpf(0.5,2.6,f)
		d.mouth = 2
		d.brow = -0.2
		d.blush = 1.0 - f
		d.look = Vector2(-fd,-0.5)
	else:
		d.face = -fd
		d.lift = 5.0 * sin(PI * _seg(t,PLUCK_HOME,PLUCK_HOME + 0.25))
		d.arm_f = 2.6 + sin(t * 14.0) * 0.45
		d.mouth = 2
		d.brow = -0.2
		d.look = Vector2(-fd,-0.2)

func _yellow_pluck(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 3.3 or t >= PLUCK_END: return
	d.shown = 1.0
	_stand(d,gm_yc,0.0)
	d.look = Vector2(-fd,0.0)
	var kick: float = _strum_kick(t)
	if t < 3.7:
		d.eye_open = 1.2
		d.mouth = 1
		d.arm_f = 0.6
		d.arm_b = 0.2
		d.brow = 0.2
	elif t < 4.6:
		# Annoyed: fists on hips, scowl, foot tapping, flinching at every plonk.
		d.arm_mode = 1
		d.eye_open = 0.6
		d.brow = 1.0
		d.mouth = 6
		d.tap = absf(sin(t * 10.0))
		d.lean = -fd * 0.06
		d.squash = 1.0 - 0.04 * kick
	elif t < 5.5:
		# Resistance crumbles: nodding along to the beat, a smirk creeping in.
		d.arm_mode = 1
		d.eye_open = 0.8
		d.brow = 0.5
		d.mouth = 5 if t < 5.0 else 4
		d.tilt = fd * 0.1 * sin(t * TAU / 0.35)
		d.lift = 1.5 * kick
		d.tap = absf(sin(t * 10.0))
	elif t < PLUCK_BIG:
		d.eye_open = 1.2
		d.arm_f = 0.8
		d.brow = -0.4
		d.mouth = 1
		d.lean = fd * 0.06 * _seg(t,5.5,PLUCK_BIG)
		d.look = Vector2(-fd,-0.2)
	elif t < PLUCK_LAND:
		# Something is coming straight for her head.
		var g: float = _seg(t,PLUCK_BIG,PLUCK_LAND)
		d.look = Vector2(-fd * (1.0 - g),-g)
		d.eye_open = 1.4
		d.mouth = 9
		d.brow = -0.8
		d.lean = fd * 0.18 * g
		d.arm_f = 1.3
		d.arm_b = -1.3
		d.mark_kind = 1
		d.mark = smoothstep(0.0,0.2,g) * (1.0 - smoothstep(0.8,1.0,g))
	elif t < PLUCK_TOSS:
		# Bonk. The star squashes her, then she balances it like a tightrope walker and her scowl returns.
		var age: float = t - PLUCK_LAND
		d.squash = 1.0 - 0.22 * exp(-age * 9.0) * cos(age * 26.0)
		d.tilt = fd * 0.12 * exp(-age * 2.5) * sin(age * 9.0)
		d.arm_f = 1.3
		d.arm_b = -1.3
		d.eye_open = 1.1
		d.look = Vector2(0.0,-1.0)
		d.brow = lerpf(0.2,1.0,_seg(t,6.8,7.1))
		d.mouth = 1 if t < 6.9 else 6
	elif t < PLUCK_HOME:
		# Headbutt: the star is flicked back to the string.
		var f: float = _seg(t,PLUCK_TOSS,PLUCK_HOME)
		d.lift = 8.0 * sin(PI * minf(f * 1.25,1.0))
		d.tilt = -fd * 0.35 * sin(PI * minf(f * 2.0,1.0))
		d.squash = 1.0 - 0.18 * sin(PI * minf(f * 3.0,1.0))
		d.eye_open = -1.0
		d.mouth = 2
		d.arm_f = 0.5
		d.arm_b = -0.5
	else:
		d.arm_mode = 2
		d.eye_open = 0.7
		d.brow = 0.5
		d.mouth = 4
		d.tilt = -fd * 0.1
		d.look = Vector2(-fd,-0.2)

func _crown_of_yellow(t: float) -> Vector2:
	_py.reset()
	_yellow_pluck(_py,t)
	return _star_crown(_py)

func _star_pluck(t: float) -> Vector4:
	var fd: float = gm_d
	cur_star_mood = 2 if t < 3.5 else 1
	cur_look = Vector2(fd,0.2)
	if t < 1.0 or t >= PLUCK_END: return Vector4.ZERO
	if t >= PLUCK_BIG and t < PLUCK_LAND:
		cur_look = Vector2(fd,-0.5)
		return _arc(gm_home,_crown_of_yellow(PLUCK_LAND),_seg(t,PLUCK_BIG,PLUCK_LAND),70.0,TAU * 2.0 * fd)
	if t >= PLUCK_LAND and t < PLUCK_TOSS:
		var age: float = t - PLUCK_LAND
		var c: Vector2 = _star_crown(yellow)
		cur_star_mood = 2
		cur_look = Vector2(0.0,1.0)
		cur_star_sq = 0.3 * exp(-9.0 * age) * sin(age * 40.0)
		return Vector4(c.x,c.y,SR,0.1 * sin(t * 5.0))
	if t >= PLUCK_TOSS and t < PLUCK_HOME:
		cur_star_mood = 1
		return _arc(_crown_of_yellow(PLUCK_TOSS),gm_home,_seg(t,PLUCK_TOSS,PLUCK_HOME),56.0,TAU * 1.5 * -fd)
	var hop: float = 0.0
	var idx: int = _strum_index(t)
	if idx >= 0 and t < 5.5:
		var a: float = t - float(PLUCK_AT[idx])
		if a < 0.3: hop = (3.5 + 1.5 * float(idx)) * sin(PI * a / 0.3)
	var s: Vector4 = _star_rest(t,1.0,PLUCK_END,hop)
	if t >= PLUCK_HOME:
		var age: float = t - PLUCK_HOME
		cur_star_mood = 0
		cur_star_sq = 0.3 * exp(-9.0 * age) * sin(age * 40.0)
	return s

func _pluck_events(prev: float, cur: float) -> void:
	_geom()
	if _crossed(prev,cur,1.0):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,56.0,true)
	for i in range(PLUCK_AT.size()):
		if _crossed(prev,cur,float(PLUCK_AT[i])):
			_add_ring(gm_ax,2.5 + 0.35 * float(i))
			_burst(gm_home,2,GOLD_HI,38.0 + 3.0 * float(i),true,2)
	if _crossed(prev,cur,3.3):
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,48.0,true)
	if _crossed(prev,cur,PLUCK_BIG):
		_add_ring(gm_ax,9.0)
		_burst(gm_home,10,GOLD,100.0,true)
	if _crossed(prev,cur,PLUCK_LAND):
		_burst(_crown_of_yellow(PLUCK_LAND),6,GOLD_HI,70.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,50.0,true)
	if _crossed(prev,cur,PLUCK_TOSS):
		_burst(_crown_of_yellow(PLUCK_TOSS),4,CREAM,50.0,true,1)
	if _crossed(prev,cur,PLUCK_HOME):
		_add_ring(gm_ax,6.0)
		_burst(gm_home,9,GOLD,90.0,true)
	if _crossed(prev,cur,PLUCK_END):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),3,DUST,48.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,48.0,true)

# ---------------------------------------------------------------- vignette 2: Snooze (10.6 s)

func _snooze_spot() -> float:
	return gm_xb + gm_d * 27.0

func _snooze_pose(t: float) -> void:
	_geom()
	_blue_snooze(blue,t)
	_yellow_snooze(yellow,t)
	if blue.shown > 0.5: _bookend(blue,t,0.8,SNOOZE_END)
	if yellow.shown > 0.5: _bookend(yellow,t,3.9,SNOOZE_END)
	cur_star = _star_snooze(t)
	cur_stache = t >= 7.3
	cur_pencil = _pencil_snooze(t)
	var fd: float = gm_d
	var head: Vector2 = _head_top(blue)
	var starts: Array = [3.5,5.2,6.9]
	var lives: Array = [1.5,1.5,0.95]
	for k in range(3):
		_say("z z Z",head + Vector2(fd * 14.0,0.0),t,float(starts[k]),float(lives[k]),22,-0.12 * fd,18.0)
	_say("scritch scritch",_head_top(yellow) + Vector2(fd * 24.0,-8.0),t,5.55,0.9,18,-0.05 * fd,6.0)
	_say("hee hee",_head_top(yellow),t,7.35,0.75,22,0.08,6.0)
	_say("POP!",head + Vector2(-fd * 20.0,-6.0),t,7.85,0.7,30,fd * 0.1,8.0)
	_say("ha ha!",head,t,9.5,0.7,24,-0.06 * fd,8.0)

## The snot bubble breathes with the snores, then swells beyond reason shortly before it bursts.
func _snooze_bubble(t: float) -> float:
	if t < 3.4 or t >= 7.85: return 0.0
	var b: float = (0.55 + 0.45 * sin(t * 3.9 - 1.2)) * smoothstep(3.4,3.9,t)
	return b + 0.45 * smoothstep(7.0,7.8,t)

func _blue_snooze(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 0.8 or t >= SNOOZE_END: return
	d.shown = 1.0
	_stand(d,gm_xb,0.0)
	d.look = Vector2(-fd,0.0)
	d.stache = _seg(t,5.45,6.65)
	d.bubble = _snooze_bubble(t)
	if t < 1.3:
		d.arm_f = 0.3
	elif t < 2.2:
		# A huge yawn that stretches the whole body.
		var s: float = sin(PI * _seg(t,1.3,2.2))
		d.arm_f = lerpf(0.3,2.9,s)
		d.arm_b = lerpf(-0.3,-2.9,s)
		d.lean = fd * 0.15 * s
		d.squash = 1.0 + 0.08 * s
		d.mouth = 9
		d.eye_open = lerpf(1.0,0.3,s)
		d.brow = -0.4
	elif t < 3.3:
		# Drowsy: lids sag, head bobs, one startled snort on the way down.
		var f: float = _seg(t,2.2,3.3)
		var snort: bool = t > 2.95 and t < 3.1
		d.eye_open = 1.3 if snort else lerpf(0.8,0.35,f)
		d.tilt = -fd * 0.22 * f * absf(sin(t * 3.0))
		d.lean = -fd * 0.1 * f
		d.lift = 2.5 * sin(PI * _seg(t,2.95,3.1))
		d.mouth = 9 if snort else 5
	elif t < 7.85:
		# Fast asleep: slow breathing, head hanging, a twitch when the pencil gets close.
		d.eye_open = 0.0
		d.mouth = 8
		d.tilt = -fd * 0.18
		d.lean = -fd * (0.06 + 0.03 * sin(t * 1.7))
		d.squash = 1.0 + 0.025 * sin(t * 3.4)
		d.arm_f = 0.2
		d.arm_b = -0.2
		if t > 6.1 and t < 6.4:
			var tw: float = sin(PI * _seg(t,6.1,6.4))
			d.lean += -fd * 0.08 * tw
			d.lift = 1.5 * tw
	elif t < 8.2:
		# The bubble bursts and he jolts awake.
		var f: float = _seg(t,7.85,8.2)
		d.lift = 8.0 * sin(PI * minf(f * 1.6,1.0))
		d.squash = 1.0 + 0.1 * sin(PI * minf(f * 2.0,1.0))
		d.arm_f = lerpf(2.2,0.6,f)
		d.arm_b = -1.4
		d.eye_open = 1.4
		d.mouth = 9
		d.brow = -1.0
		d.mark_kind = 1
		d.mark = 1.0 - smoothstep(0.6,1.0,f)
	elif t < 8.7:
		# Feels his upper lip, eyes crossing down to look at it.
		d.arm_mode = 5
		d.eye_open = 1.1
		d.pupil = 0.8
		d.mouth = 1
		d.brow = 0.8
		d.look = Vector2(0.0,1.0)
	elif t < 9.15:
		# Spots the star's moustache too.
		d.arm_mode = 5
		d.eye_open = 1.35
		d.pupil = 0.6
		d.brow = -0.7
		d.mouth = 7
		d.look = Vector2(-fd,0.1)
		d.lean = sin(t * 50.0) * 0.012
	elif t < 9.45:
		# Whips round on Yellow: "!?".
		var f: float = _seg(t,9.15,9.45)
		_flip(d,-fd,f)
		d.arm_f = lerpf(0.5,1.9,f)
		d.arm_b = lerpf(-0.3,1.4,f)
		d.eye_open = 1.4
		d.mouth = 9
		d.brow = -1.0
		d.look = Vector2(fd,0.0)
		d.mark_kind = 3
		d.mark = smoothstep(0.0,0.2,f) * (1.0 - smoothstep(0.8,1.0,f))
	else:
		# Gives in and laughs, moustache and all.
		d.face = fd
		var hop: float = absf(sin((t - 9.45) * PI / 0.3))
		d.lift = 5.0 * hop
		d.squash = 1.0 - 0.08 * pow(1.0 - hop,4.0)
		d.arm_f = 2.2
		d.arm_b = -2.2
		d.eye_open = -1.0
		d.mouth = 2
		d.brow = -0.3
		d.tilt = fd * 0.1 * sin(t * 18.0)
		d.look = Vector2(fd,0.0)

func _yellow_snooze(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 3.9 or t >= SNOOZE_END: return
	d.shown = 1.0
	var x: float = gm_yc
	if t >= 4.3: x = lerpf(gm_yc,_snooze_spot(),_ease_io(_seg(t,4.3,5.15)))
	_stand(d,x,0.0)
	d.look = Vector2(-fd,0.0)
	if t < 4.3:
		d.eye_open = 1.2
		d.brow = 0.7
		d.mouth = 4
		d.arm_f = 0.6
		d.arm_b = 0.2
	elif t < 5.15:
		# Tiptoe with a finger over the lips, one conspicuous glance at the viewer.
		d.walk = (t - 4.3) * 7.0
		d.lift = 1.8 + 1.4 * absf(sin(d.walk))
		d.stride = 0.5
		d.lean = -fd * 0.2
		d.arm_mode = 5
		d.arm_b = -0.9 + sin(d.walk) * 0.35
		d.brow = 0.8
		d.mouth = 4
		d.eye_open = 0.85
		d.look = Vector2.ZERO if (t > 4.55 and t < 4.9) else Vector2(-fd,0.2)
	elif t < 5.4:
		# Produces a pencil from nowhere.
		var f: float = _seg(t,5.15,5.4)
		d.arm_f = lerpf(0.6,2.2,_ease_out(f))
		d.arm_b = -0.4
		d.squash = 1.0 - 0.08 * sin(PI * f)
		d.lean = -fd * 0.1
		d.mouth = 2
		d.brow = 1.0
		d.eye_open = 0.7
		d.look = Vector2(-fd,-0.2)
	elif t < 6.7:
		# Scribbling a moustache; a huge snore freezes her mid-stroke.
		d.arm_f = 2.2 + 0.18 * sin(t * 38.0)
		d.arm_b = -0.4
		d.lean = -fd * 0.12
		d.tilt = -fd * 0.06
		d.mouth = 4
		d.brow = 1.0
		d.eye_open = 0.7
		d.look = Vector2(-fd,-0.2)
		if t > 6.1 and t < 6.45:
			d.arm_f = 2.2
			d.look = Vector2.ZERO
			d.eye_open = 1.2
			d.pupil = 0.8
			d.mouth = 7
			d.brow = -0.6
			d.mark_kind = 4
			d.mark = smoothstep(6.1,6.2,t) * (1.0 - smoothstep(6.35,6.45,t))
	elif t < 6.95:
		# Winds up to throw the pencil at the star.
		var f: float = _seg(t,6.7,6.95)
		d.arm_f = lerpf(2.2,2.9,_ease_io(f))
		d.arm_b = -0.4
		d.squash = lerpf(1.0,0.84,_ease_io(f))
		d.lean = fd * 0.12 * f
		d.mouth = 2
		d.brow = 1.0
		d.look = Vector2(-fd,-0.2)
	elif t < 7.3:
		var f: float = _seg(t,6.95,7.3)
		d.arm_f = lerpf(2.9,1.1,_ease_out(minf(f * 2.0,1.0)))
		d.arm_b = -0.4
		d.lift = 3.0 * sin(PI * f)
		d.lean = lerpf(fd * 0.12,-fd * 0.3,_ease_out(minf(f * 3.0,1.0)))
		d.mouth = 2
		d.brow = 0.6
		d.look = Vector2(-fd,-0.3)
	elif t < 7.85:
		# Silent snickering.
		d.eye_open = -1.0
		d.mouth = 2
		d.arm_mode = 4
		d.squash = 1.0 - 0.07 * absf(sin(t * 24.0))
		d.lift = 1.4 * absf(sin(t * 12.0))
		d.tilt = -fd * 0.08 * sin(t * 18.0)
	elif t < 8.15:
		var f: float = _seg(t,7.85,8.15)
		d.lift = 7.0 * sin(PI * f)
		d.arm_f = 1.9
		d.arm_b = 1.4
		d.eye_open = 1.4
		d.mouth = 9
		d.brow = -0.8
	elif t < 9.1:
		# Conspicuously innocent: whistling at the ceiling.
		d.lift = 0.8 * absf(sin(t * 7.0))
		d.arm_mode = 6
		d.eye_open = 0.8
		d.brow = -0.3
		d.mouth = 8
		d.look = Vector2(0.0,-1.0)
		d.mark_kind = 6
		d.mark = 1.0
	elif t < 9.45:
		# Caught: a sweat drop forms.
		d.arm_mode = 6
		d.eye_open = 1.15
		d.pupil = 0.75
		d.brow = -0.9
		d.mouth = 7
		d.look = Vector2(-fd,0.1)
		d.mark_kind = 4
		d.mark = smoothstep(9.1,9.25,t)
	else:
		# Cracks up first.
		var hop: float = absf(sin((t - 9.45) * PI / 0.3))
		d.lift = 5.0 * hop
		d.squash = 1.0 - 0.1 * pow(1.0 - hop,4.0)
		d.arm_mode = 4
		d.eye_open = -1.0
		d.mouth = 2
		d.lean = -fd * 0.08
		d.tilt = -fd * 0.1 * sin(t * 18.0)

func _probe_yellow_snooze(t: float) -> Doodle:
	_py.reset()
	_yellow_snooze(_py,t)
	return _py

func _probe_blue_snooze(t: float) -> Doodle:
	_pb.reset()
	_blue_snooze(_pb,t)
	return _pb

## The pencil's grip point as Yellow throws it.
func _pencil_grip(t: float) -> Vector2:
	return _hand_front(_probe_yellow_snooze(t))

## x, y = grip point, z = direction the tip points (radians), w = opacity.
func _pencil_snooze(t: float) -> Vector4:
	var fd: float = gm_d
	if t < 5.15 or t >= 7.55: return Vector4.ZERO
	var aim: float = Vector2(-fd,-0.35).angle()
	if t < 6.95:
		var h: Vector2 = _hand_front(yellow)
		return Vector4(h.x,h.y,aim,smoothstep(5.15,5.3,t))
	if t < 7.3:
		var a: Vector4 = _arc(_pencil_grip(6.95),gm_home,_seg(t,6.95,7.3),44.0,TAU * 3.0 * -fd)
		return Vector4(a.x,a.y,aim + a.w,1.0)
	# Bounces off the star and tumbles away.
	var age: float = t - 7.3
	var p: Vector2 = gm_home + Vector2(fd * 30.0 * age,-28.0 * age + 220.0 * age * age)
	return Vector4(p.x,p.y,aim + TAU * 3.0 * -fd + age * 14.0,1.0 - smoothstep(0.1,0.25,age))

func _star_snooze(t: float) -> Vector4:
	var fd: float = gm_d
	cur_look = Vector2(fd,0.1)
	cur_star_mood = 2 if (t < 7.3 or t >= 9.45) else 1
	var hop: float = 0.0
	if t >= 7.3 and t < 7.75: hop = 12.0 * sin(PI * _seg(t,7.3,7.75))
	elif t >= 9.45: hop = 5.0 * absf(sin((t - 9.45) * PI / 0.3))
	var s: Vector4 = _star_rest(t,1.0,SNOOZE_END,hop)
	if t >= 7.3 and t < 8.0:
		var age: float = t - 7.3
		cur_star_sq = 0.35 * exp(-9.0 * age) * sin(age * 38.0)
	return s

func _snooze_events(prev: float, cur: float) -> void:
	_geom()
	if _crossed(prev,cur,1.0):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,56.0,true)
	if _crossed(prev,cur,3.9):
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,48.0,true)
	if _crossed(prev,cur,5.15):
		_burst(_pencil_grip(5.4),3,GOLD_HI,30.0,true,2)
	if _crossed(prev,cur,6.95):
		_burst(_pencil_grip(6.95),3,CREAM,50.0,true,1)
	if _crossed(prev,cur,7.3):
		_add_ring(gm_ax,5.0)
		_burst(gm_home,8,GOLD_HI,80.0,true,2)
	if _crossed(prev,cur,7.85):
		var b: Doodle = _probe_blue_snooze(7.84)
		_burst(_world(b,Vector2(_ef(b) * (3.0 + 0.9 * (1.0 + 5.2 * b.bubble)),-23.6)),6,SWEAT,70.0,true,0)
	if _crossed(prev,cur,9.45):
		_burst(Vector2((gm_xb + gm_yc) * 0.5,FLOOR_Y - 52.0),4,GOLD,50.0,true,2)
	if _crossed(prev,cur,SNOOZE_END):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),3,DUST,48.0,true)
		_burst(Vector2(_snooze_spot(),FLOOR_Y - 2.0),3,DUST,48.0,true)

# ---------------------------------------------------------------- vignette 3: Whack-a-Doodle (7.8 s)
# Pops: Blue 0.8 (home perch), Yellow 2.05 (far gap), Blue 3.3 (midway), Yellow 4.4 (Blue's perch), then both at 5.6 / 5.7.

func _whack_pose(t: float) -> void:
	_geom()
	_blue_whack(blue,t)
	_yellow_whack(yellow,t)
	if blue.shown > 0.5: _bookend(blue,t,-9.0,WHACK_END)
	if yellow.shown > 0.5: _bookend(yellow,t,-9.0,WHACK_END)
	cur_star = _star_whack(t)
	var xm: float = (gm_xb + gm_yc) * 0.5
	_say("peek!",Vector2(gm_xb,640.0),t,1.15,0.7,22,-0.1,6.0)
	_say("boo?",Vector2(gm_yc,640.0),t,2.4,0.65,22,0.1,6.0)
	_say("hello?",Vector2(xm,640.0),t,3.55,0.7,22,-0.08,6.0)
	_say("psst!",Vector2(gm_xb,640.0),t,4.65,0.6,22,0.08,6.0)
	_say("BOO!",Vector2(gm_xb,640.0),t,6.05,0.8,34,-0.06,8.0)
	_say("ahem.",Vector2(gm_ax,630.0),t,6.65,0.75,22,0.05,6.0)

func _blue_whack(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = fd
	if t < 0.8 or t >= WHACK_END: return
	var x: float = gm_xb
	var up: float = 0.8
	var down: float = 1.85
	if t < 2.05:
		pass
	elif t < 3.3:
		return
	elif t < 4.45:
		x = (gm_xb + gm_yc) * 0.5
		up = 3.3
		down = 4.25
	elif t < 5.6:
		return
	else:
		up = 5.6
		down = 99.0
	d.shown = 1.0
	_stand(d,x,0.0)
	d.lift = _hole(t,up,down)
	d.eye_open = 1.2
	d.mouth = 1
	d.brow = 0.2
	d.look = Vector2(fd * clampf(0.7 + 0.4 * sin((t - up) * 6.0),0.0,1.0),0.1)
	if t < 2.05:
		# Pops up looking the wrong way, finds nobody, shrugs.
		if t > 1.4:
			d.arm_mode = 7
			d.mouth = 7
			d.brow = -0.6
			d.mark_kind = 2
			d.mark = smoothstep(1.4,1.55,t) * (1.0 - smoothstep(1.7,1.85,t))
	elif t < 4.45:
		if t > 3.85:
			d.arm_mode = 3
			d.arm_b = -0.6
			d.fidget = sin(t * 20.0)
			d.mouth = 7
			d.mark_kind = 2
			d.mark = smoothstep(3.85,4.0,t) * (1.0 - smoothstep(4.05,4.25,t))
	else:
		# The final pop: Blue spots Yellow's back and works himself up to a scare.
		d.look = Vector2(fd,0.0)
		if t < 6.05:
			var f: float = _seg(t,5.85,6.05)
			d.mouth = 4
			d.brow = 0.8
			d.lean = fd * 0.2 * f
			d.squash = 1.0 - 0.14 * f
		elif t < 6.55:
			var f: float = _seg(t,6.05,6.35)
			d.lift += 14.0 * sin(PI * f)
			d.arm_f = 2.9
			d.arm_b = -2.9
			d.mouth = 9
			d.brow = 1.0
			d.eye_open = 1.4
			d.squash = 1.0 + 0.12 * sin(PI * minf(f * 1.5,1.0))
			# Having scared her, he turns his own back on her.
			_flip(d,fd,_seg(t,6.25,6.55))
		else:
			d.face = -fd
			d.arm_f = 2.6 + sin(t * 14.0) * 0.45
			d.mouth = 2
			d.brow = -0.2
			d.eye_open = 1.0
			d.look = Vector2(-fd,0.0)

func _yellow_whack(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 2.05 or t >= WHACK_END: return
	var x: float = gm_yc
	var up: float = 2.05
	var down: float = 3.1
	if t < 3.3:
		pass
	elif t < 4.4:
		return
	elif t < 5.55:
		x = gm_xb
		up = 4.4
		down = 5.35
	elif t < 5.7:
		return
	else:
		up = 5.7
		down = 99.0
	d.shown = 1.0
	_stand(d,x,0.0)
	d.lift = _hole(t,up,down)
	d.eye_open = 1.2
	d.mouth = 1
	d.look = Vector2(-fd,0.1)
	if t < 3.3:
		# Looks at the hole Blue just left.
		if t > 2.55:
			d.brow = 0.6
			d.mouth = 5
			d.mark_kind = 2
			d.mark = smoothstep(2.55,2.7,t) * (1.0 - smoothstep(2.95,3.1,t))
	elif t < 5.55:
		# Looks at the hole Blue is not in either.
		d.face = fd
		d.look = Vector2(fd,0.1)
		if t > 4.85:
			d.arm_mode = 7
			d.mouth = 7
			d.mark_kind = 2
			d.mark = smoothstep(4.85,5.0,t) * (1.0 - smoothstep(5.1,5.3,t))
	else:
		# Final pop with her back to Blue; his "BOO!" lands a beat late.
		d.face = fd
		d.look = Vector2(fd,0.0)
		if t < 6.15:
			d.arm_mode = 2
			d.eye_open = 0.8
			d.mouth = 5
			d.brow = 0.3
		elif t < 6.7:
			var f: float = _seg(t,6.15,6.7)
			d.lift += 9.0 * sin(PI * minf(f * 2.5,1.0))
			d.arm_f = 1.9
			d.arm_b = 1.4
			d.eye_open = 1.4
			d.mouth = 9
			d.brow = -1.0
			d.mark_kind = 1
			d.mark = smoothstep(0.0,0.15,f) * (1.0 - smoothstep(0.7,1.0,f))
			_flip(d,fd,_seg(t,6.3,6.6))
		else:
			# She turns round just as he turns away. Nobody ever looks the right way.
			d.face = -fd
			d.arm_mode = 1
			d.eye_open = 0.6
			d.mouth = 6
			d.brow = 1.0
			d.look = Vector2(-fd,0.0)
			d.lean = -fd * 0.1
			d.tap = absf(sin(t * 10.0))

func _star_whack(t: float) -> Vector4:
	var fd: float = gm_d
	cur_look = Vector2(fd * (0.5 + 0.5 * sin(t * 2.3)),0.1)
	cur_star_mood = 0
	var hop: float = 5.0 * _pulse(t,WHACK_POPS,0.3)
	if t >= 6.05 and t < 6.45:
		hop += 12.0 * sin(PI * _seg(t,6.05,6.45))
		cur_star_mood = 1
	elif t >= 6.6 and t < 7.1:
		hop += 10.0 * absf(sin((t - 6.6) * PI / 0.25))
		cur_star_mood = 2
		cur_look = Vector2(0.0,0.2)
	return _star_rest(t,1.0,WHACK_END,hop)

func _whack_events(prev: float, cur: float) -> void:
	_geom()
	var xm: float = (gm_xb + gm_yc) * 0.5
	if _crossed(prev,cur,1.0):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,56.0,true)
	var spots: Array = [gm_xb,gm_yc,xm,gm_xb,gm_xb,gm_yc]
	for i in range(WHACK_POPS.size()):
		if _crossed(prev,cur,float(WHACK_POPS[i])):
			_burst(Vector2(float(spots[i]),FLOOR_Y - 2.0),4,DUST,60.0,true)
	for pair in [[1.85,gm_xb],[3.1,gm_yc],[4.25,xm],[5.35,gm_xb]]:
		if _crossed(prev,cur,float(pair[0])):
			_burst(Vector2(float(pair[1]),FLOOR_Y - 2.0),2,DUST,40.0,true)
	if _crossed(prev,cur,6.05):
		_burst(Vector2(gm_xb,FLOOR_Y - 50.0),5,CREAM,70.0,true,1)
	if _crossed(prev,cur,6.2):
		_burst(Vector2(gm_yc,FLOOR_Y - 50.0),4,GOLD_HI,60.0,true,2)
	if _crossed(prev,cur,6.6):
		_add_ring(gm_ax,4.0)
		_burst(gm_home,4,GOLD_HI,50.0,true,2)
	if _crossed(prev,cur,WHACK_END):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),3,DUST,48.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,48.0,true)

# ---------------------------------------------------------------- vignette 4: Hiccups (9.2 s)

## Yellow stops just behind Blue, who faces the star.
func _hiccup_spot() -> float:
	return gm_xb + gm_d * 46.0

func _hiccup_pose(t: float) -> void:
	_geom()
	_blue_hiccup(blue,t)
	_yellow_hiccup(yellow,t)
	if blue.shown > 0.5: _bookend(blue,t,0.8,HICCUP_END)
	if yellow.shown > 0.5: _bookend(yellow,t,1.0,HICCUP_END)
	cur_star = _star_hiccup(t)
	_say("BOO!",_head_top(yellow),t,2.55,0.85,34,-0.05,6.0)
	for s in HIC_Y:
		_say("hic!",_head_top(yellow),t,float(s),0.55,22 if float(s) < 6.9 else 28,sin(float(s) * 5.0) * 0.15,8.0)
	for s in HIC_B:
		_say("hic!",_head_top(blue),t,float(s),0.55,22 if float(s) < 6.9 else 28,sin(float(s) * 5.0) * 0.15,8.0)
	for s in HIC_S:
		_say("hic!",Vector2(gm_ax,gm_home.y - 30.0),t,float(s),0.55,22 if float(s) < 6.9 else 28,sin(float(s) * 5.0) * 0.15,8.0)

func _blue_hiccup(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 0.8 or t >= HICCUP_END: return
	d.shown = 1.0
	_stand(d,gm_xb,0.0)
	d.look = Vector2(-fd,0.0)
	var hic: float = _pulse(t,HIC_B,0.24)
	var cue: float = _pulse(t,HIC_Y,0.24)
	if t < 2.9:
		# Admiring the star, humming, hands behind his back, blissfully unaware of the tiptoeing behind him.
		d.arm_mode = 6
		d.mouth = 8 if fmod(t * 3.0,1.0) > 0.5 else 4
		d.lean = sin(t * 3.0) * 0.04
		d.eye_open = 0.85
	elif t < 3.6:
		# Zero reaction to the BOO. A slow, deadpan turn.
		_flip(d,-fd,_seg(t,2.9,3.5))
		d.arm_mode = 6
		d.eye_open = 0.5
		d.brow = 0.6
		d.mouth = 5
		d.look = Vector2(fd,0.0)
	elif t < 4.1:
		d.face = fd
		d.arm_mode = 7 if t > 3.7 else 0
		d.eye_open = 0.55
		d.brow = 0.5
		d.mouth = 5
		d.look = Vector2(fd,0.0)
	elif t < 5.2:
		# Watches Yellow hiccup, delighted.
		d.face = fd
		d.arm_mode = 2
		d.eye_open = 0.85
		d.brow = 0.4
		d.mouth = 4
		d.squash = 1.0 - 0.04 * cue
		d.lean = sin(t * 14.0) * 0.02
		d.look = Vector2(fd,0.0)
	elif t < 6.5:
		# Contagious: his own hiccups, embarrassed, hand over mouth.
		d.face = fd
		d.arm_mode = 5
		d.eye_open = 1.4 if hic > 0.05 else 1.0
		d.mouth = 9 if hic > 0.05 else 1
		d.lift = 7.0 * hic
		d.squash = 1.0 - 0.1 * hic
		d.blush = smoothstep(5.2,5.5,t) * 0.8
		d.brow = -0.8
		d.look = Vector2(fd * 0.4,0.5)
	elif t < 6.85:
		# Both turn toward the star at the same time.
		_flip(d,fd,_seg(t,6.5,6.8))
		d.arm_mode = 5
		d.blush = 0.8
		d.eye_open = 1.1
		d.mouth = 1
		d.brow = -0.6
		d.look = Vector2(-fd,0.0)
	else:
		# Hiccuping in unison with Yellow and the star, the last one a real launch.
		d.face = -fd
		d.arm_mode = 5
		d.lift = (14.0 if t >= 7.9 else 7.0) * hic
		d.squash = 1.0 - 0.12 * hic
		d.blush = 0.8
		d.eye_open = 1.4 if hic > 0.05 else 1.1
		d.mouth = 9 if hic > 0.05 else 1
		d.brow = -0.6
		d.look = Vector2(-fd,0.0)

func _yellow_hiccup(d: Doodle, t: float) -> void:
	var fd: float = gm_d
	d.face = -fd
	if t < 1.0 or t >= HICCUP_END: return
	d.shown = 1.0
	var x: float = gm_yc
	if t >= 1.4: x = lerpf(gm_yc,_hiccup_spot(),_ease_io(_seg(t,1.4,2.3)))
	_stand(d,x,0.0)
	d.look = Vector2(-fd,0.0)
	var hic: float = _pulse(t,HIC_Y,0.24)
	var cue: float = _pulse(t,HIC_B,0.24)
	if t < 1.4:
		d.eye_open = 1.1
		d.brow = 0.8
		d.mouth = 4
		d.arm_f = 0.6
	elif t < 2.3:
		# Tiptoe up behind Blue with a finger over the lips, one conspicuous glance at the viewer.
		d.walk = (t - 1.4) * 7.0
		d.lift = 1.8 + 1.4 * absf(sin(d.walk))
		d.stride = 0.5
		d.lean = -fd * 0.2
		d.arm_mode = 5
		d.arm_b = -0.9 + sin(d.walk) * 0.35
		d.brow = 0.8
		d.mouth = 4
		d.eye_open = 0.85
		d.look = Vector2.ZERO if (t > 1.75 and t < 2.05) else Vector2(-fd,0.3)
	elif t < 2.55:
		var f: float = _seg(t,2.3,2.55)
		d.squash = lerpf(1.0,0.78,_ease_io(f))
		d.lean = -fd * 0.25 * f
		d.arm_f = lerpf(0.8,1.5,f)
		d.arm_b = -0.9 - 0.4 * f
		d.brow = 1.0
		d.mouth = 2
	elif t < 2.95:
		# BOO!
		var f: float = _seg(t,2.55,2.95)
		d.lift = 22.0 * sin(PI * f)
		d.squash = 1.0 + 0.14 * sin(PI * f)
		d.arm_f = 2.9
		d.arm_b = -2.9
		d.mouth = 9
		d.eye_open = 1.4
		d.brow = 1.0
	elif t < 3.6:
		# Holds the pose waiting for a scream; the scream does not come.
		var f: float = _seg(t,3.2,3.6)
		d.arm_f = lerpf(2.9,1.0,f)
		d.arm_b = lerpf(-2.9,-0.4,f)
		d.mouth = 2 if t < 3.3 else 1
		d.eye_open = 1.2
		d.mark_kind = 4
		d.mark = smoothstep(3.3,3.5,t)
	elif t < 4.1:
		d.lean = fd * 0.05
		d.mouth = 1
		d.eye_open = 1.0
		d.brow = -0.3
		d.arm_f = 0.5
		d.mark_kind = 4
		d.mark = 1.0 - smoothstep(3.6,3.9,t)
	else:
		# The backfire: the held breath turns into hiccups, and they only get worse.
		d.arm_mode = 5 if t > 4.7 else 0
		d.arm_f = 0.6
		d.lift = (10.0 if t >= 7.9 else 7.0) * hic
		d.squash = 1.0 - 0.12 * hic - 0.04 * cue
		d.lean = -fd * 0.05 * hic
		d.blush = smoothstep(4.2,4.8,t) * 0.8
		d.eye_open = 1.4 if hic > 0.05 else 1.0
		d.mouth = 9 if hic > 0.05 else 1
		d.brow = -0.6

func _star_hiccup(t: float) -> Vector4:
	var fd: float = gm_d
	cur_look = Vector2(fd,0.1)
	cur_star_mood = 2
	var beat: float = _pulse(t,HIC_S,0.3)
	var hop: float = (24.0 if t >= 7.9 else 14.0) * beat
	if t >= 2.55 and t < 3.3:
		hop += 9.0 * sin(PI * _seg(t,2.55,2.9))
		cur_star_mood = 1
	elif beat > 0.0:
		cur_star_mood = 1
	var s: Vector4 = _star_rest(t,1.0,HICCUP_END,hop)
	cur_star_sq += 0.25 * beat
	return s

func _hiccup_events(prev: float, cur: float) -> void:
	_geom()
	var xt: float = _hiccup_spot()
	if _crossed(prev,cur,1.0):
		_add_ring(gm_ax,3.0)
		_burst(gm_home,5,GOLD_HI,56.0,true)
		_burst(Vector2(gm_yc,FLOOR_Y - 2.0),3,DUST,48.0,true)
	if _crossed(prev,cur,2.55):
		_add_ring(gm_ax,3.5)
		_burst(Vector2(xt,FLOOR_Y - 62.0),6,CREAM,74.0,true,1)
	for s in HIC_Y:
		if _crossed(prev,cur,float(s)): _burst(Vector2(xt,FLOOR_Y - 48.0),2,GOLD_HI,34.0,true,2)
	for s in HIC_B:
		if _crossed(prev,cur,float(s)): _burst(Vector2(gm_xb,FLOOR_Y - 48.0),2,GOLD_HI,34.0,true,2)
	for s in HIC_S:
		if _crossed(prev,cur,float(s)):
			_add_ring(gm_ax,6.0 if float(s) >= 7.9 else 3.5)
			_burst(gm_home,3,GOLD_HI,44.0,true,2)
	if _crossed(prev,cur,HICCUP_END):
		_burst(Vector2(gm_xb,FLOOR_Y - 2.0),3,DUST,48.0,true)
		_burst(Vector2(xt,FLOOR_Y - 2.0),3,DUST,48.0,true)

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
	_clear_props()
	if _reduced:
		_static_pose()
		return
	blue.reset()
	yellow.reset()
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
		cur_pencil.w *= 1.0 - e
		cur_word_f *= 1.0 - e
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
	_draw_pencil()
	if not _reduced: _draw_sparks()
	else: _draw_static_glints()
	_draw_word()

## The pencil Yellow draws the moustaches with: pink eraser, gold barrel, wood cone, graphite tip.
func _draw_pencil() -> void:
	if cur_pencil.w < 0.03: return
	var a: float = clampf(cur_pencil.w,0.0,1.0)
	var dir: Vector2 = Vector2.from_angle(cur_pencil.z)
	var p: Vector2 = Vector2(cur_pencil.x,cur_pencil.y)
	var tail: Vector2 = p - dir * 9.0
	var neck: Vector2 = p + dir * 6.0
	var tip: Vector2 = p + dir * 12.0
	draw_line(tail,neck,Color(INK,a),6.4,true)
	draw_line(tail,neck,Color(GOLD,a),3.6,true)
	draw_line(neck,tip,Color(INK,a),5.0,true)
	draw_line(neck,tip - dir * 1.5,Color(CREAM,a),2.4,true)
	draw_circle(tail,3.3,Color(INK,a))
	draw_circle(tail,2.1,Color(PINK,a))
	draw_circle(tip,1.5,Color(INK,a))

## Handwritten sound effects: cream lettering with a heavy ink outline, popping in and fading out.
func _draw_word() -> void:
	if cur_word_f < 0.03 or cur_word.is_empty(): return
	var a: float = clampf(cur_word_f,0.0,1.0)
	draw_set_transform(cur_word_at,cur_word_tilt,Vector2.ONE * clampf(cur_word_f,0.0,1.25))
	var origin: Vector2 = Vector2(-100.0,0.0)
	draw_string_outline(FONT,origin,cur_word,HORIZONTAL_ALIGNMENT_CENTER,200.0,cur_word_size,8,Color(INK,a))
	draw_string(FONT,origin,cur_word,HORIZONTAL_ALIGNMENT_CENTER,200.0,cur_word_size,Color(CREAM,a))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

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
		var gaze: Vector2 = cur_look * 0.06
		draw_circle(Vector2(-0.23,0.04) + gaze,er,INK)
		draw_circle(Vector2(0.23,0.04) + gaze,er,INK)
		if worried:
			draw_circle(Vector2(0.0,0.3),0.08,INK)
		elif cur_star_mood == 2:
			draw_polyline(PackedVector2Array([Vector2(-0.18,0.2),Vector2(0.0,0.36),Vector2(0.18,0.2)]),INK,1.5 / r,true)
		else:
			draw_polyline(PackedVector2Array([Vector2(-0.15,0.23),Vector2(0.0,0.32),Vector2(0.15,0.23)]),INK,1.4 / r,true)
		if cur_stache:
			# Pencilled on by Yellow: two curled strokes over the mouth.
			for si in range(2):
				var sgn: float = -1.0 if si == 0 else 1.0
				var curl: PackedVector2Array = PackedVector2Array([Vector2(sgn * 0.03,0.22),Vector2(sgn * 0.14,0.19),Vector2(sgn * 0.28,0.24),Vector2(sgn * 0.37,0.33),Vector2(sgn * 0.43,0.24)])
				draw_polyline(curl,INK,2.8 / r,true)
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
	_draw_face_props(d,hc,1.7 / sc * CS)
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

## The first `frac` of a path, with the last point interpolated: lets a stroke be drawn on progressively.
func _partial_path(pts: PackedVector2Array, frac: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var span: float = clampf(frac,0.0,1.0) * float(pts.size() - 1)
	var whole: int = floori(span)
	for i in range(mini(whole + 1,pts.size())): out.append(pts[i])
	if whole < pts.size() - 1: out.append(pts[whole].lerp(pts[whole + 1],span - float(whole)))
	return out

## Snot bubble radius in body-local units.
func _bubble_r(d: Doodle) -> float:
	return 1.0 + 5.2 * d.bubble

## Props that live on the face: Yellow's pencil moustache (drawn on stroke by stroke) and Blue's snot bubble.
func _draw_face_props(d: Doodle, hc: Vector2, thin: float) -> void:
	var rot: float = d.tilt
	var f: float = _ef(d)
	var mx: float = d.look.x * 1.9 * 0.8
	if d.stache > 0.03:
		for si in range(2):
			var sgn: float = -1.0 if si == 0 else 1.0
			var curl: PackedVector2Array = PackedVector2Array([Vector2(mx + sgn * 0.6,3.9),Vector2(mx + sgn * 2.0,3.3),Vector2(mx + sgn * 3.6,3.7),Vector2(mx + sgn * 5.0,4.7),Vector2(mx + sgn * 5.8,3.6)])
			var stroke: PackedVector2Array = _partial_path(curl,d.stache)
			for k in range(stroke.size()): stroke[k] = hc + stroke[k].rotated(rot)
			draw_polyline(stroke,PENCIL,thin * 2.3,true)
	if d.bubble > 0.03:
		var r: float = _bubble_r(d)
		var nose: Vector2 = hc + Vector2(mx + f * 3.2,3.6).rotated(rot)
		var c: Vector2 = hc + Vector2(mx + f * (3.0 + r * 0.9),4.4).rotated(rot)
		draw_line(nose,c - Vector2(f * r * 0.8,0.0),Color(SWEAT,0.7),thin * 1.2,true)
		draw_circle(c,r,Color(SWEAT,0.28))
		draw_arc(c,r,0.0,TAU,20,Color(CREAM,0.85),thin,true)
		draw_arc(c,r * 0.62,PI * 1.15,PI * 1.55,6,Color(CREAM,0.8),thin * 0.8,true)

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
