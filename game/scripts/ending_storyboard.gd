extends Node2D
## Deterministic cinematic source. No gameplay state, saved progress or damage.
const Rig = preload("res://scripts/fighter_rig.gd")
const FONT = preload("res://assets/fonts/Kalam-Bold.ttf")
const LOGO = preload("res://assets/benjam_games.png")
const DURATION = 30.0
const COLORS = [Color("ffab35"),Color("ff454c"),Color("8eff57"),Color("51caff"),Color("d77dff"),Color("ffe062")]
const IDS = ["orange","red","green","blue","purple","yellow"]
const WORLDS = ["glitch","canopy","network","arcade","desktop","desktop"]
const CAPTIONS = [
	"The Save Star was too heavy for one crown.\nDark lord dropped it. Very dramatically.",
	"Orange caught it. Blue built a shelf.\nGreen grew a tree around the shelf.",
	"Red opened the way. Purple sent the map.\nYellow brought light—and emergency snacks.",
	"Dark lord asked for a part in the story.\nAssistant Manager of Purple. Cape included.",
	"Back on the desk, they shared the Save Star.\nEven beige got a turn to shine.",
	"Small kids' art made a big world.\nThe next page is yours to draw."
]
var elapsed = 0.0
var manual = false
var textures: Dictionary = {}
var heroes: Array = []
var lord
var hacker
var chomp

func _ready() -> void:
	for kind in WORLDS: textures[kind] = load("res://assets/arenas/"+kind+"_v2.png")
	for id in IDS:
		var actor = Rig.new()
		add_child(actor)
		actor.configure(get_node("/root/Data").fighter(id))
		heroes.append(actor)
	lord = _actor("dark_lord")
	hacker = _actor("h4ck3r")
	chomp = _actor("pac_man")
	seek(0)

func _actor(id: String):
	var actor = Rig.new()
	add_child(actor)
	actor.configure(get_node("/root/Data").fighter(id))
	return actor

func _process(delta: float) -> void:
	if not manual: seek(minf(elapsed+delta,DURATION))

func seek(at: float) -> void:
	elapsed = clampf(at,0,DURATION)
	var shot = mini(5,int(elapsed/5))
	var t = fposmod(elapsed,5.0)
	for i in range(6):
		var actor = heroes[i]
		actor.visible = (shot != 3 and shot != 5) or (shot == 3 and i == 4)
		actor.modulate = Color.WHITE
		actor.scale = Vector2.ONE * (1.58 if shot == 4 else 1.8)
		actor.position = Vector2(180+i*180,578)
		actor.elapsed = elapsed
		actor.phase = elapsed*3.0+i
		actor.pose(0,{"grounded":true,"victory":shot==4,"facing":1 if i<3 else -1})
		actor.weapon.visible = shot < 4
		if shot == 0:
			actor.position = Vector2(220+i*37,578+i%2*9)
			actor.visible = i == 0
		if shot == 1:
			actor.visible = i in [0,2,3]
			actor.position = Vector2(250 + [0,0,1,2,0,0][i]*360,578)
			actor.pose(0,{"grounded":true,"special":true,"attack_progress":clampf(t/5,0.2,0.72),"facing":1})
		if shot == 2:
			actor.visible = i in [1,4,5]
			actor.position = Vector2(250 + [0,0,0,0,1,2][i]*360,578)
			actor.pose(0,{"grounded":true,"victory":true,"facing":1})
		if shot == 3 and i == 4:
			actor.position = Vector2(700,578)
			actor.scale = Vector2.ONE * 1.9
			actor.weapon.visible = false
			actor.pose(0,{"grounded":true,"victory":true,"facing":1})
		if shot == 4:
			actor.position = Vector2(155+i*194+(18 if i>=3 else 0),578)
	lord.visible = shot in [0,3]
	lord.position = Vector2(917,584) if shot == 0 else Vector2(914,578)
	lord.scale = Vector2.ONE * (lerpf(2.55,0.35,smoothstep(1.0,4.8,t)) if shot == 0 else 1.17)
	lord.modulate.a = 1.0-smoothstep(2.2,4.8,t) if shot == 0 else 1.0
	lord.pose(0,{"grounded":true,"victory":shot==3,"facing":-1})
	lord.weapon.visible = shot == 0
	hacker.visible = shot == 3
	chomp.visible = shot == 3
	hacker.position = Vector2(1090,578)
	chomp.position = Vector2(252+sin(t)*20,578)
	for actor in [hacker,chomp]:
		actor.scale = Vector2.ONE * 1.65
		actor.phase = elapsed*3
		actor.pose(0,{"grounded":true,"victory":true,"facing":-1})
		actor.weapon.visible = false
	queue_redraw()

func _draw() -> void:
	if textures.is_empty(): return
	draw_rect(Rect2(0,0,1280,720),Color("080c17"))
	var shot = mini(5,int(elapsed/5))
	var t = fposmod(elapsed,5)
	if shot == 5:
		draw_rect(Rect2(0,0,1280,720),Color("10171c"))
		draw_texture_rect(LOGO,Rect2(376,40,528,451),false)
		_draw_save_star(Vector2(640,538),38.0,1.0)
		for i in range(6):
			var spark = Vector2(640,538)+Vector2.from_angle(i*TAU/6+elapsed*0.28)*72
			draw_circle(spark,4.5,COLORS[i])
	else:
		var texture: Texture2D = textures[WORLDS[shot]]
		var size = texture.get_size()
		var floor_fraction: float = {"glitch":0.739,"canopy":0.645,"network":0.658,"arcade":0.638,"desktop":0.734}[WORLDS[shot]]
		var edge = size.y*floor_fraction
		draw_texture_rect_region(texture,Rect2(-6+sin(elapsed*.2)*3,0,1292,579),Rect2(0,0,size.x,edge))
		draw_texture_rect_region(texture,Rect2(0,579,1280,141),Rect2(0,edge,size.x,size.y-edge))
		for actor in heroes+[lord,hacker,chomp]:
			if not actor.visible: continue
			draw_set_transform(actor.position,0,Vector2(1,0.16))
			draw_circle(Vector2.ZERO,34,Color("080c17",0.34))
			draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(0,0,1280,600),Color("071023",0.22 if shot==0 else 0.12))
		if shot == 0:
			var p = Vector2(920,300)
			for i in range(6):
				var offset = Vector2.from_angle(i*TAU/6+elapsed*0.6)*lerpf(90,230,t/5)
				draw_circle(p+offset,19,Color(COLORS[i],0.09))
				draw_circle(p+offset,7,COLORS[i])
			_draw_save_star(Vector2(916,413).lerp(Vector2(640,235),smoothstep(0.8,4.8,t)),31.0+8.0*smoothstep(1.0,4.8,t),1.0)
		else:
			for i in range(6):
				var points = PackedVector2Array()
				for k in range(45):
					var x = 100+k*25.0
					var y = 567 - sin(float(k)/44*PI)*(65+i*14)*smoothstep(0,2.0,t)
					points.append(Vector2(x,y))
				draw_polyline(points,Color(COLORS[i],0.15),10,true)
				draw_polyline(points,Color(COLORS[i],0.58),2.0,true)
			for i in range(24):
				var p = Vector2(80+fposmod(i*103.0+elapsed*13,1120),180+fposmod(i*67.0-elapsed*12,370))
				draw_circle(p,1.5+i%2,Color(COLORS[i%6],0.4))
			if shot in [1,2]:
				var start_x = 260.0 if shot == 1 else 310.0
				_draw_save_star(Vector2(lerpf(start_x,970.0,smoothstep(0.2,4.8,t)),270.0+sin(t*2.0)*20.0),34.0,1.0)
			elif shot == 3:
				_draw_save_star(Vector2(612,276+sin(t*1.8)*8),36.0,1.0)
				draw_rect(Rect2(783,228,302,48),Color("10121e",0.83))
				draw_string_outline(FONT,Vector2(796,260),"ASSISTANT MANAGER",HORIZONTAL_ALIGNMENT_CENTER,275,20,4,Color("10121e"))
				draw_string(FONT,Vector2(796,260),"ASSISTANT MANAGER",HORIZONTAL_ALIGNMENT_CENTER,275,20,Color("efcbff"))
			elif shot == 4:
				var paper = PackedVector2Array([Vector2(454,493),Vector2(813,486),Vector2(832,575),Vector2(449,580)])
				draw_colored_polygon(paper,Color("eee0bf"))
				var edge_line = paper.duplicate()
				edge_line.append(paper[0])
				draw_polyline(edge_line,Color("272130"),5.0,true)
				for line in range(3):
					draw_line(Vector2(490,515+line*18),Vector2(760,510+line*18),Color("8b7791",0.45),1.8,true)
				_draw_save_star(Vector2(640,205).lerp(Vector2(640,486),smoothstep(0.5,4.6,t)),34.0+8.0*smoothstep(2.0,4.7,t),1.0)
	# Captions are a separate foreground node so actor silhouettes cannot cover text.

func _draw_save_star(center: Vector2, radius: float, alpha: float) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := -PI/2.0 + i*TAU/10.0
		var reach := radius if i%2 == 0 else radius*0.47
		points.append(center+Vector2.from_angle(angle)*reach)
	draw_circle(center,radius*1.48,Color("ffe783",0.10*alpha))
	draw_colored_polygon(points,Color("ffce59",alpha))
	points.append(points[0])
	draw_polyline(points,Color("181324",alpha),5.0,true)
	draw_polyline(points,Color("fff6bc",0.88*alpha),2.0,true)
	draw_circle(center+Vector2(-radius*0.13,-radius*0.12),radius*0.12,Color("fff8d0",alpha))
