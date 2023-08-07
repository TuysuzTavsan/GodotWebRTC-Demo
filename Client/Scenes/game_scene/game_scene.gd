extends Node

var pop_up_template = preload("res://Scenes/pop_up/pop_up.tscn")
var start_time : float = 5.0
var pop_up

func _ready():
	pop_up = pop_up_template.instantiate()
	pop_up.name = "pop_up"
	pop_up.set_msg("5")
	pop_up.is_button_visible(false)
	add_child(pop_up)


func _process(delta):
	var second_left : float = start_time - delta
	start_time -= delta
	pop_up.set_msg(str(floor(second_left)))
	
	if start_time <= 0:
		set_process(false)
		get_node("pop_up").queue_free()

func _on_button_pressed():
	User.reset_connection()
	
	for child in get_children():
		child.queue_free()

