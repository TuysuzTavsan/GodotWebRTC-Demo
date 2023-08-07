extends Control

var lobby_menu_template = preload("res://Scenes/lobby_menu/lobby_menu.tscn")
var pop_up_template = preload("res://Scenes/pop_up/pop_up.tscn")
var game_scene_template = preload("res://Scenes/game_scene/game_scene.tscn")
var player_character_template = preload("res://Scenes/player_character/player_character.tscn")
@onready var host_template = $Host_template
@onready var player_template = $Player_template
@onready var player_list_container = $"Player List/Players/ScrollContainer/VBoxContainer"

func _ready():
	User.client.host_name_received.connect(_host_name_received)
	User.client.lobby_messsage_received.connect(_lobby_message_received)
	User.client.other_user_joined_lobby.connect(_other_user_joined_lobby)
	User.client.some_one_left_lobby.connect(_some_one_left_lobby)
	User.client.server_changed_host.connect(_server_changed_host)
	User.delete_in_lobby_menu.connect(_delete_in_lobby_menu)
	User.init_connection()
	
	$"Lobby Name".text = User.current_lobby_name
	init_player_list()
	User.init_connection()

func _delete_in_lobby_menu():
	queue_free()

func _server_changed_host():
	init_player_list()

func init_player_list():
	for child in player_list_container.get_children():
		child.free()
	
	for peer_name in User.peers.values():
		if peer_name == User.host_name:
			var new_host_template = host_template.duplicate()
			new_host_template.get_node("Name").text = peer_name
			new_host_template.show()
			player_list_container.add_child(new_host_template)
		else:
			var new_player_template = player_template.duplicate()
			new_player_template.get_node("Name").text = peer_name
			new_player_template.show()
			player_list_container.add_child(new_player_template)
	
	
	var new_player_template  = host_template.duplicate() if User.is_host else player_template.duplicate()
	new_player_template.get_node("Name").text = User.user_name
	new_player_template.show()
	player_list_container.add_child(new_player_template)


func _host_name_received(hostname : String):
	User.init_connection()
	init_player_list()

func _some_one_left_lobby(other_player_name : String):
	
	var container = $Chat/ScrollContainer/VBoxContainer
	
	if not User.is_host and User.peers.size() == 0:
		User.is_host = true
		var msg_node = $Message_template.duplicate()
		msg_node.show()
		msg_node.text = "SYSTEM: " + " You are Host now!"
		container.add_child(msg_node)
	
	init_player_list()
	User.init_connection()

func _other_user_joined_lobby(username : String):
	var container = $Chat/ScrollContainer/VBoxContainer
	var msg_node = $Message_template.duplicate()	
	msg_node.show()
	msg_node.text = "SYSTEM: " + username + " joined!"
	container.add_child(msg_node)
	
	init_player_list()
	User.init_connection()

func _lobby_message_received(message : String, _user_name : String):
	var container = $Chat/ScrollContainer/VBoxContainer
	var msg_node = $Message_template.duplicate()
	msg_node.show()
	msg_node.text = _user_name + ": " + message
	container.add_child(msg_node)

func _on_return_pressed():
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   Returning Lobby Menu...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.is_host = false
	User.host_name = ""
	User.peers.clear()
	User.connection_list.clear()
	User.client.send_left_info(User.current_lobby_name)
	await get_tree().create_timer(1).timeout
	User.client.request_lobby_list()
	get_parent().add_child(lobby_menu_template.instantiate())
	pop_up.queue_free()
	queue_free()

func _on_message_text_submitted(_new_text):
	_on_submit_msg_pressed()

func _on_submit_msg_pressed():
	var msg_text = $Chat/Submit/Message.text
	if not msg_text == "":
		User.client.send_chat_msg($Chat/Submit/Message.text, User.user_name)
		$Chat/Submit/Message.text = ""

func _on_start_pressed():
	if User.peers.size() == 0:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Need 2 players!")
		add_child(pop_up)
	elif not User.is_host:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Only host can start the game!")
		add_child(pop_up)
	else:
		User.client.send_game_starting()



