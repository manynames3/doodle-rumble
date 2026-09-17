extends Node2D
## Project onto an existing surface; a jumping actor never carries a floating disc.
var host: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(host): return
	for fighter in [host.first,host.second]:
		if not is_instance_valid(fighter) or not fighter.visible: continue
		var floor_y: float = 600.0
		for body in host.platform_bodies:
			if not is_instance_valid(body): continue
			var collision: CollisionShape2D = body.get_child(0)
			if collision.disabled: continue
			var rect := Rect2(body.position-collision.shape.size/2,collision.shape.size)
			if fighter.position.x >= rect.position.x and fighter.position.x <= rect.end.x and rect.position.y >= fighter.position.y-3:
				floor_y = minf(floor_y,rect.position.y)
		var height: float = maxf(0,floor_y-fighter.position.y)
		var width: float = (36.0 if fighter.health>0 else 60.0)*fighter.body_scale*lerpf(1.0,0.53,minf(height/280.0,1))
		var shade: float = lerpf(0.40,0.10,minf(height/280.0,1))
		draw_set_transform(Vector2(fighter.position.x,floor_y+2),0,Vector2(1,0.15))
		draw_circle(Vector2.ZERO,width+12,Color(0.01,0.015,0.028,shade*0.28))
		draw_circle(Vector2.ZERO,width,Color(0.01,0.015,0.028,shade))
		draw_set_transform(Vector2.ZERO)
		if height < 13.0 and fighter.health > 0 and is_instance_valid(fighter.rig):
			# Separate ink at each sole gives the broad pose a visible point of weight.
			for foot in [fighter.rig.left_foot,fighter.rig.right_foot]:
				var foot_x: float = fighter.position.x+foot.x*fighter.rig.scale.x
				var foot_y: float = floor_y+3.0
				var contact := PackedVector2Array([Vector2(foot_x-12,foot_y),Vector2(foot_x-5,foot_y+1.5),Vector2(foot_x+6,foot_y-0.8),Vector2(foot_x+14,foot_y)])
				draw_polyline(contact,Color(0.01,0.015,0.028,0.52),2.3,true)
				draw_line(Vector2(foot_x-8,foot_y+3),Vector2(foot_x+9,foot_y+2),Color(fighter.rig.accent,0.18),1.1,true)
