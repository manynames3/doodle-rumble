extends Node2D
const Car=preload("res://scripts/racer_art.gd")
const INK=Color("263e4d")
var elapsed:=0.0
var style:=0
var paint:=Color("f5a23f")
var car
func _ready():
	car=Car.new()
	car.configure(style,paint)
	car.position=Vector2(235,357)
	car.scale=Vector2.ONE*1.9
	add_child(car)
func _process(delta):
	if not Settings.reduced_motion: elapsed+=delta
	car.heading=-.3+sin(elapsed*2)*.13
	car.position.y=357+sin(elapsed*3)*7
	queue_redraw()
func _draw():
	var at:=Vector2(1049,350)
	var cup:=PackedVector2Array([at+Vector2(-38,-39),at+Vector2(38,-39),at+Vector2(26,8),at+Vector2(7,25),at+Vector2(7,45),at+Vector2(27,45),at+Vector2(32,57),at+Vector2(-32,57),at+Vector2(-27,45),at+Vector2(-7,45),at+Vector2(-7,25),at+Vector2(-26,8)])
	draw_colored_polygon(cup,Color("fbc75b"))
	cup.append(cup[0]);draw_polyline(cup,INK,4,true)
	for dir in [-1,1]: draw_arc(at+Vector2(dir*36,-20),19,-PI/2,PI/2 if dir==1 else -PI*1.5,20,Color("f5aa37"),6,true)
	draw_line(at+Vector2(-25,-30),at+Vector2(-18,4),Color("fff4ae"),6,true)
	for i in range(24):
		var p:=Vector2(205+i*39,160+fposmod(i*47+elapsed*30,398))
		var color:Color=[Color("ffb842"),Color("5bbcd2"),Color("d97daa"),Color("97b862")][i%4]
		draw_line(p,p+Vector2(5*cos(i+elapsed),7),color,3,true)
