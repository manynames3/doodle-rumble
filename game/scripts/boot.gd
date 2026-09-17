extends Control
## The studio card appears once per launch, before any title-menu controls exist.
const MAIN := "res://scenes/main.tscn"
const LOGO := preload("res://assets/benjam_games.png")
var elapsed := 0.0
var skipped := false
var transitioning := false
var picture: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := ColorRect.new()
	background.color = LOGO.get_image().get_pixel(0,0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	picture = TextureRect.new()
	picture.texture = LOGO
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_top = 20
	picture.offset_bottom = -20
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	picture.modulate.a = 1.0 if Settings.reduced_motion else 0.0
	Sound.set_external_music_active(true)

func _process(delta: float) -> void:
	if transitioning: return
	elapsed += delta
	var fade := minf(elapsed / 0.3, 1.0) * clampf((2.4 - elapsed) / 0.3, 0.0, 1.0)
	picture.modulate.a = 1.0 if Settings.reduced_motion else fade
	if elapsed >= 2.4 or skipped:
		transitioning = true
		Sound.set_external_music_active(false)
		get_tree().change_scene_to_file(MAIN)

func _unhandled_input(event: InputEvent) -> void:
	if elapsed < 0.2: return
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		skipped = true
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	Sound.set_external_music_active(false)
