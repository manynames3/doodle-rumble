extends SceneTree
## Verify every packed silhouette settles inside the arena at either result spawn.
const IDS = ["orange","red","green","blue","purple","yellow","pac_man","h4ck3r","dark_lord"]
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	root.hide()
	call_deferred("run")

func run() -> void:
	if not "--isolated-qa" in OS.get_cmdline_user_args():
		quit(1)
		return
	await process_frame
	var Fighter = load("res://scripts/fighter.gd")
	for id in IDS:
		for slot in [1,2]:
			var fighter = Fighter.new()
			root.add_child(fighter)
			fighter.setup(id,slot)
			fighter.position = Vector2(250 if slot == 1 else 1000,599)
			fighter.facing = 1 if slot == 1 else -1
			fighter.result_defeated = true
			fighter.update_art(0.0)
			fighter.update_art(0.72)
			var body: Sprite2D = fighter.rig.packed_art.body
			var image: Image = body.texture.get_image()
			var transform: Transform2D = body.get_global_transform()
			var min_x: float = INF
			var max_x: float = -INF
			var max_y: float = -INF
			for y in range(0,image.get_height(),4):
				for x in range(0,image.get_width(),4):
					if image.get_pixel(x,y).a < 0.08: continue
					var point: Vector2 = transform * Vector2(x,y)
					min_x = minf(min_x,point.x)
					max_x = maxf(max_x,point.x)
					max_y = maxf(max_y,point.y)
			var okay: bool = min_x >= 0.0 and max_x <= 1280.0 and max_y >= 560.0 and max_y <= 620.0
			checks += 1
			if not okay: failures += 1
			print("RESULT_GEOMETRY %s side=%d x=%.1f..%.1f foot=%.1f pass=%s" % [id,slot,min_x,max_x,max_y,str(okay)])
			fighter.queue_free()
			await process_frame
	print("RESULT_GEOMETRY_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
