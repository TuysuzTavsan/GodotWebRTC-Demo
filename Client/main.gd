extends Node

var pop_up_template = preload("res://Scenes/pop_up/pop_up.tscn")
var intro_template = preload("res://Scenes/intro/intro.tscn")
var main_menu = preload("res://Scenes/main menu/main_menu.tscn")

func _ready():
	var intro = intro_template.instantiate()
	add_child(intro)
	User.reset.connect(connection_reset)

func _process(delta):
	pass

func connection_reset():
	for i in get_children():
		i.queue_free()
	
	
	add_child(main_menu.instantiate())
	
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("Connection lost!", Color(0.79215687513351, 0.26274511218071, 0.56470590829849))
	add_child(pop_up)
