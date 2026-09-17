extends Node2D
## Presentation only. No particle or animation can deal damage.
const HandFont = preload("res://assets/fonts/Kalam-Bold.ttf")
const INK = Color("070914")
const WHITE_HOT = Color("fffdf2")
var particles: Array = []
var words: Array = []
var marks: Array = []
var reduced_motion = false
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func burst(at: Vector2, color: Color, big: bool = false) -> void:
	marks.append({"type":"bloom","p":at,"c":color,"life":0.24,"max":0.24,"direction":1,"big":big})
	for i in range((5 if reduced_motion else 22) if big else (3 if reduced_motion else 12)):
		var angle = rng.randf_range(-PI,0)
		var speed = rng.randf_range(60,240) * (1.4 if big else 1.0)
		particles.append({"kind":"spark","p":at,"v":Vector2(cos(angle),sin(angle))*speed,"life":0.7,"max":0.7,"c":color,"size":rng.randf_range(3,8),"spin":rng.randf()*TAU})

func word(at: Vector2, message: String, color: Color) -> void:
	words.append({"p":at,"text":message,"c":color,"life":0.65})

func damage_number(at: Vector2, amount: int, color: Color, direction: int) -> void:
	var nearby = words.filter(func(w): return w.get("damage",false) and w.p.distance_to(at)<80).size()
	words.append({"p":Vector2(clampf(at.x-18+direction*nearby*27,30,1200),clampf(at.y-nearby*25,122,550)),"text":"−%d" % amount,"c":color.lightened(0.65),"life":0.95,"damage":true})

func celebrate() -> void:
	var palette = [Color("ffad21"),Color("3ed9ff"),Color("8dff3b"),Color("ff3c4e")]
	if Settings.celebration_style == "rainbow": palette.append_array([Color("d675ff"),Color("ffe84a")])
	if Settings.celebration_style == "sparkle": palette = [Color("ffcc3c"),Color("fff3ba"),Color("ff9d25")]
	for i in range(11):
		burst(Vector2(140+i*100,260),palette[i%palette.size()],true)

func dust(at: Vector2) -> void:
	for i in range(3 if reduced_motion else 8):
		particles.append({"kind":"spark","p":at+Vector2(rng.randf_range(-22,22),-3),"v":Vector2(rng.randf_range(-75,75),rng.randf_range(-65,-20)),"life":0.4,"max":0.4,"c":Color("7485a6"),"size":rng.randf_range(3,7),"spin":0})

func impact(at: Vector2, color: Color, direction: int, big: bool) -> void:
	# Contact reads in three beats: a brief pale cut, a handful of ink chips,
	# then the slower debris. Avoid stacking a generic spark burst on every hit.
	marks.append({"type":"bloom","p":at,"c":color,"life":0.16,"max":0.16,"direction":direction,"big":big})
	marks.append({"type":"impact","p":at,"c":color,"life":0.22,"max":0.22,"direction":direction,"big":big,"seed":rng.randi()})
	for i in range(2 if reduced_motion else (5 if big else 3)):
		particles.append({"kind":"streak","p":at,"v":Vector2(direction*rng.randf_range(180,410),rng.randf_range(-220,105)),"life":0.34,"max":0.34,"c":color.lightened(0.58),"size":rng.randf_range(3.0,5.2),"spin":0.0})
	var rock_count: int = 2 if reduced_motion else (5 if big else 3)
	for i in range(rock_count):
		var rock_color: Color = color.darkened(0.46+float(i%2)*0.12)
		particles.append({"kind":"rock","p":at+Vector2(rng.randf_range(-8,8),rng.randf_range(-4,5)),"v":Vector2(direction*rng.randf_range(72,245),rng.randf_range(-245,-82)),"life":0.52,"max":0.52,"c":rock_color,"size":rng.randf_range(4.8,9.5),"spin":rng.randf_range(-4.0,4.0)})

func guard(at: Vector2, color: Color, facing: int, reflected: bool) -> void:
	marks.append({"type":"guard","p":at,"c":color,"life":0.23,"max":0.23,"direction":facing,"big":reflected})
	for i in range(2 if reduced_motion else (5 if reflected else 3)):
		var outward := Vector2(facing*rng.randf_range(80,210),rng.randf_range(-160,45))
		particles.append({"kind":"rock","p":at,"v":outward,"life":0.35,"max":0.35,"c":color.darkened(0.33),"size":rng.randf_range(3.5,6.5),"spin":rng.randf_range(-3.0,3.0)})

func crack(at: Vector2, color: Color) -> void:
	marks.append({"type":"crack","p":at,"c":color,"life":0.75,"max":0.75,"direction":1,"big":true})
	for i in range(2 if reduced_motion else 6):
		particles.append({"kind":"rock","p":at+Vector2(rng.randf_range(-24,24),-4),"v":Vector2(rng.randf_range(-230,230),rng.randf_range(-315,-125)),"life":0.65,"max":0.65,"c":color.darkened(0.58),"size":rng.randf_range(6.0,12.0),"spin":rng.randf_range(-5.0,5.0)})

func dash_trail(at: Vector2, color: Color, direction: int) -> void:
	marks.append({"type":"dash","p":at,"c":color,"life":0.32,"max":0.32,"direction":direction,"big":false})

func _process(delta: float) -> void:
	for p in particles:
		p.life -= delta
		p.p += p.v * delta
		p.v.y += 430 * delta
	for w in words:
		w.life -= delta
		if not reduced_motion: w.p.y -= 34 * delta
	for mark in marks: mark.life -= delta
	marks = marks.filter(func(mark): return mark.life > 0)
	particles = particles.filter(func(p): return p.life > 0)
	words = words.filter(func(w): return w.life > 0)
	queue_redraw()

func _draw() -> void:
	for mark in marks:
		var c = Color(mark.c,minf(1,mark.life*5))
		if mark.type == "crack":
			var crack_heat: float = clampf(mark.life/0.75,0.0,1.0)
			var ground_bloom := PackedVector2Array([mark.p+Vector2(-145,2),mark.p+Vector2(-83,-18),mark.p+Vector2(0,-27),mark.p+Vector2(92,-15),mark.p+Vector2(151,2),mark.p+Vector2(74,10),mark.p+Vector2(-76,9)])
			draw_colored_polygon(ground_bloom,Color(mark.c,0.075*crack_heat))
			for direction in [-1,1]:
				var path = PackedVector2Array([mark.p,mark.p+Vector2(25*direction,-7),mark.p+Vector2(42*direction,-1),mark.p+Vector2(66*direction,-8),mark.p+Vector2(96*direction,-1),mark.p+Vector2(133*direction,-4)])
				draw_polyline(path,Color(c,0.055*c.a),28,true)
				draw_polyline(path,Color(c,0.13*c.a),13,true)
				draw_polyline(path,Color(INK,c.a),6,true)
				draw_polyline(path,c,3,true)
				draw_polyline(path,Color(c.lightened(0.65),c.a),1,true)
				# Ink-edged chips rise from the crack, following its existing lifetime.
				for i in range(3):
					var lift: float = 0.0 if reduced_motion else sin((0.75-mark.life)*PI/0.75)*20.0
					var chip = mark.p+Vector2(direction*(27+i*27),-10-i*7-lift)
					var shard := PackedVector2Array([chip+Vector2(-5,-1),chip+Vector2(-1,-6),chip+Vector2(7,-3),chip+Vector2(4,5),chip+Vector2(-4,4)])
					draw_colored_polygon(shard,Color(c.darkened(0.65),c.a))
					shard.append(shard[0])
					draw_polyline(shard,Color(0.02,0.025,0.05,c.a),2.0,true)
					draw_line(shard[0],shard[1],Color(c.lightened(0.40),c.a),1.2,true)
		elif mark.type == "dash" and not reduced_motion:
			for i in range(4):
				var from = mark.p+Vector2(-mark.direction*(30+i*18),-32-i*19)
				var tip = from+Vector2(mark.direction*(205+i*20),0)
				draw_line(from,tip,Color(c,0.045*c.a),25,true)
				draw_line(from,tip,Color(c,0.11*c.a),11,true)
				draw_line(from,tip,Color(INK,0.78*c.a),4.5,true)
				draw_line(from,tip,c,2,true)
				draw_line(tip-Vector2(mark.direction*28,0),tip,Color(c.lightened(0.65),c.a),1.3,true)
				if i%2 == 0:
					var bolt := PackedVector2Array([from+Vector2(13,3),from+Vector2(29,-2),from+Vector2(38,3),from+Vector2(50,-4),from+Vector2(65,-3)])
					draw_polyline(bolt,Color(c.lightened(0.65),c.a),1.4,true)
		elif mark.type == "guard":
			var guard_t: float = clampf(mark.life/float(mark.max),0.0,1.0)
			var face: float = float(mark.direction)
			var shield_points := PackedVector2Array([mark.p+Vector2(-8*face,-65),mark.p+Vector2(20*face,-77),mark.p+Vector2(37*face,-52),mark.p+Vector2(33*face,-11),mark.p+Vector2(7*face,10)])
			draw_polyline(shield_points,Color(mark.c,0.10*guard_t),19,true)
			draw_polyline(shield_points,Color(INK,0.90*guard_t),7,true)
			draw_polyline(shield_points,Color(Color(mark.c).lightened(0.62),guard_t),3,true)
			for i in range(3 if bool(mark.big) else 2):
				var from: Vector2 = mark.p+Vector2(face*(34+i*9),-50+i*23)
				var tip: Vector2 = from+Vector2(face*(48+i*13),-11+i*7)
				var slash := PackedVector2Array([from+Vector2(0,-3),tip,from+Vector2(face*12,5)])
				draw_colored_polygon(slash,Color(Color(mark.c).lightened(0.58),guard_t*(0.90-float(i)*0.15)))
				draw_polyline(slash,Color(INK,0.8*guard_t),1.5,true)
		elif mark.type == "bloom":
			var bloom_t: float = clampf(mark.life/float(mark.max),0.0,1.0)
			var bloom_radius: float = lerpf(67.0 if bool(mark.big) else 43.0,18.0,bloom_t)
			draw_circle(mark.p,bloom_radius,Color(mark.c,0.035*bloom_t))
			draw_circle(mark.p,bloom_radius*0.63,Color(mark.c,0.075*bloom_t))
			draw_arc(mark.p,bloom_radius*0.78,0.13,TAU-0.31,28,Color(Color(mark.c).lightened(0.42),0.30*bloom_t),2.0,true)
		elif mark.type == "impact":
			var impact_t: float = clampf(mark.life/float(mark.max),0.0,1.0)
			var impact_size: float = 1.28 if bool(mark.big) else 1.0
			var ray_count: int = 5 if reduced_motion else 8
			for i in range(ray_count):
				var angle: float = TAU*float(i)/float(ray_count)+sin(float(i)*7.13)*0.08
				var v := Vector2.from_angle(angle)
				var forward: float = maxf(0.18,v.x*float(mark.direction))
				var ray_length: float = (48.0+float(i%3)*23.0)*impact_size*(0.55+forward*0.45)
				var ray_end: Vector2 = mark.p+v*ray_length
				var root: Vector2 = mark.p+v*10.0
				var side: Vector2 = v.orthogonal()*(5.0+float(i%2)*2.0)
				var tapered := PackedVector2Array([root+side,ray_end,root-side])
				draw_colored_polygon(tapered,Color(INK,0.86*impact_t))
				draw_polyline(PackedVector2Array([root+side*0.30,ray_end-v*5.0]),Color(Color(mark.c).lightened(0.55),impact_t),1.8,true)
			# The near-white contact frame lives for only the first fraction of the mark.
			if mark.life > float(mark.max)-0.075:
				var white_shape := PackedVector2Array()
				for i in range(12):
					var angle: float = TAU*float(i)/12.0
					var radius: float = (18.0+float(i%2)*13.0)*impact_size
					white_shape.append(mark.p+Vector2.from_angle(angle)*radius)
				draw_colored_polygon(white_shape,Color(WHITE_HOT,0.88))
				white_shape.append(white_shape[0])
				draw_polyline(white_shape,Color(INK,0.94),3.5,true)
				draw_circle(mark.p,8.5*impact_size,WHITE_HOT)
			draw_arc(mark.p,17.0*impact_size,0.1,TAU-0.4,22,Color(Color(mark.c).lightened(0.62),0.82*impact_t),2.2,true)
	for p in particles:
		var opacity: float = minf(1,p.life*3)
		draw_set_transform(p.p,p.spin if reduced_motion else p.spin + p.life*5)
		if str(p.get("kind","spark")) == "rock":
			var rock := PackedVector2Array([Vector2(-p.size*0.88,-p.size*0.20),Vector2(-p.size*0.25,-p.size*0.76),Vector2(p.size*0.72,-p.size*0.44),Vector2(p.size,p.size*0.22),Vector2(p.size*0.14,p.size*0.73),Vector2(-p.size*0.78,p.size*0.45)])
			draw_circle(Vector2.ZERO,p.size*1.45,Color(p.c,opacity*0.08))
			draw_colored_polygon(rock,Color(p.c,opacity))
			rock.append(rock[0])
			draw_polyline(rock,Color(INK,opacity),2.4,true)
			draw_line(rock[1],rock[3],Color(Color(p.c).lightened(0.62),opacity),1.2,true)
		elif str(p.get("kind","spark")) == "streak":
			var tail: float = maxf(12.0,p.v.length()*0.075)
			var backwards: Vector2 = -p.v.normalized()*tail
			draw_line(backwards,Vector2.ZERO,Color(p.c,opacity*0.12),p.size*3.0,true)
			draw_line(backwards,Vector2.ZERO,Color(INK,opacity*0.78),p.size+2.0,true)
			draw_line(backwards*0.82,Vector2.ZERO,Color(Color(p.c).lightened(0.64),opacity),maxf(1.0,p.size*0.45),true)
		else:
			# Narrow asymmetric shards feel like hot sparks instead of paper confetti.
			var shard := PackedVector2Array([Vector2(-p.size,0),Vector2(p.size*0.35,-p.size*0.32),Vector2(p.size,0),Vector2(0,p.size*0.28)])
			draw_line(Vector2(-p.size,0),Vector2(p.size,0),Color(p.c,opacity*0.14),p.size*1.5,true)
			draw_colored_polygon(shard,Color(p.c,opacity))
			if p.size > 5.0:
				shard.append(shard[0])
				draw_polyline(shard,Color(INK,opacity*0.7),1.0,true)
			draw_line(Vector2(-p.size*0.4,0),Vector2(p.size*0.5,0),Color(Color(p.c).lightened(0.62),opacity),1.0,true)
	draw_set_transform(Vector2.ZERO)
	for w in words:
		draw_string_outline(HandFont,w.p,w.text,HORIZONTAL_ALIGNMENT_CENTER,-1,34 if w.get("damage",false) else 29,7,Color(INK,minf(1,w.life*4)))
		draw_string(HandFont,w.p,w.text,HORIZONTAL_ALIGNMENT_CENTER,-1,34 if w.get("damage",false) else 29,Color(w.c,minf(1,w.life*4)))
