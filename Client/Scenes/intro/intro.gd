extends Control

var main_menu = preload("res://Scenes/main menu/main_menu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Video.play()
	
	$Video.finished.connect(end)

func _input(event):
	if (event is InputEventKey and event.is_pressed()) or (event is InputEventMouseButton and event.pressed):
		$Video.stop()
		get_parent().add_child(main_menu.instantiate())
		queue_free()

func end():
	get_parent().add_child(main_menu.instantiate())
	queue_free()
