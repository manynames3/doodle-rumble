extends Control
## A live child-owned portrait; nothing in the card can deal damage.
const Rig = preload("res://scripts/fighter_rig.gd")
var rig
var selected := false
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true

func configure(record: Dictionary, active: bool = false) -> void:
	selected = active
	rig = Rig.new()
	add_child(rig)
	rig.configure(Data.custom_definition(record))
	rig.position = Vector2(103,116)
	rig.scale = Vector2.ONE*0.55
	rig.pose(0,{"grounded":true,"facing":1,"reduced_motion":Settings.reduced_motion})
	queue_redraw()

func _process(delta: float) -> void:
	if rig == null: return
	var parent := get_parent() as BaseButton
	var active := selected or (parent != null and (parent.has_focus() or parent.is_hovered()))
	if not active or Settings.reduced_motion: return
	elapsed += delta
	# The larger celebration is shown in Try It/results; keep tools inside cards.
	rig.pose(delta,{"grounded":true,"facing":1,"reduced_motion":false,"velocity":Vector2(80,0) if fmod(elapsed,5.0)>3.2 else Vector2.ZERO})

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("172331"))
	for i in range(6):
		draw_line(Vector2(9,16+i*19),Vector2(size.x-9,16+i*19),Color("91abb4",0.08),1)
	draw_line(Vector2(24,0),Vector2(24,size.y),Color("e58b91",0.16),1)
	draw_rect(Rect2(1,1,size.x-2,size.y-2),Color("ffe5a3") if selected else Color("4b6a74"),false,2)
