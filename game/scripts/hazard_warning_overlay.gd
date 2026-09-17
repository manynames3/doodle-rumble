extends Node2D
## Foreground ink labels sit below the fighters' feet; collision art remains behind them.
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const INK = Color("10111c")
const PAPER = Color("fff8e8")

func _ready() -> void:
	z_as_relative = false
	z_index = 13

func _draw() -> void:
	var hazards = get_parent()
	if hazards == null:
		return
	for mark in hazards.get("marks"):
		var spec: Dictionary = hazards.warning_spec(mark.kind)
		var tell: float = spec.tell
		var active_end: float = tell + spec.active
		var fade := 1.0 if mark.age < active_end else clampf((active_end + 0.28 - mark.age) / 0.28, 0.0, 1.0)
		var progress := clampf(mark.age / tell, 0.0, 1.0)
		var box: Rect2 = hazards.damage_rect(mark)
		var c := Color(spec.color)
		var left := box.position.x - 2.0
		var right := box.end.x + 2.0
		# Opaque ink beats both pale skies and neon floors. The low baseline
		# leaves hollow heads, weapons, and the collision column unobscured.
		var shape := PackedVector2Array([
			Vector2(left - 4, 605), Vector2(right + 3, 605),
			Vector2(right + 5, 614), Vector2(right + 3, 639),
			Vector2(left + 2, 640), Vector2(left - 5, 634),
		])
		draw_colored_polygon(shape, Color(INK, 0.94 * fade))
		var edge := shape.duplicate()
		edge.append(shape[0])
		draw_polyline(edge, Color(INK, fade), 7.0, true)
		draw_polyline(edge, Color(c, fade), 2.8, true)
		for x in [box.position.x, box.end.x]:
			draw_line(Vector2(x, 586), Vector2(x, 606), Color(INK, 0.9 * fade), 6.0, true)
			draw_line(Vector2(x, 587), Vector2(x, 605), Color(c, fade), 2.8, true)
		var label: String = spec.label
		var font_size := 12 if box.size.x < 100 else 13 if box.size.x < 180 and label.length() > 15 else 15 if box.size.x >= 180 else 14
		var baseline := Vector2(box.position.x + 4, 628)
		draw_string_outline(FONT, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 8, font_size, 3, INK)
		draw_string(FONT, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 8, font_size, PAPER if mark.age < tell else c.lightened(0.64))
		# The filling underline is the tell clock. Once active, it stays full.
		draw_line(Vector2(box.position.x + 6, 635), Vector2(box.end.x - 6, 635), Color(c, 0.24 * fade), 3.0, true)
		draw_line(Vector2(box.position.x + 6, 635), Vector2(box.position.x + 6 + (box.size.x - 12) * progress, 635), Color(c, fade), 3.0, true)
