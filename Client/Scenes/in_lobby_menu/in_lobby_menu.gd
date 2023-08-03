extends Control

var lobby_menu_template = preload("res://Scenes/lobby_menu/lobby_menu.tscn")
var pop_up_template = preload("res://Scenes/pop_up/pop_up.tscn")
var game_scene_template = preload("res://Scenes/game_scene/game_scene.tscn")
var player_character_template = preload("res://Scenes/player_character/player_character.tscn")

func _ready():
	User.client.lobby_messsage_received.connect(_lobby_message_received)
	User.client.other_user_joined_lobby.connect(_other_user_joined_lobby)
	User.client.some_one_left_lobby.connect(_some_one_left_lobby)
	User.initialize_host.connect(_initialize_host)
	User.initialize_peer.connect(_initialize_peer)
	
	
	$"Lobby Name".text = User.current_lobby_name
	
	if User.is_host:
		$"Player List/Players/Player1/Name".text = User.user_name
		$"Player List/Players/Player2/Name".text = "Empty Slot"
	else:
		$"Player List/Players/Player1/Name".text = User.other_user_name
		$"Player List/Players/Player2/Name".text = User.user_name

func _some_one_left_lobby(other_player_name : String):
	
	var container = $Chat/ScrollContainer/VBoxContainer
	
	if not User.is_host:
		User.is_host = true
		User.init_connection()
		var msg_node = $Message_template.duplicate()
		msg_node.show()
		msg_node.text = "SYSTEM: " + " You are Host now!"
		container.add_child(msg_node)
	
	$"Player List/Players/Player1/Name".text = User.user_name
	$"Player List/Players/Player2/Name".text = "Empty Slot"
	
	var msg_node = $Message_template.duplicate()
	msg_node.show()
	msg_node.text = "SYSTEM: " + User.other_user_name + " Left!"
	container.add_child(msg_node)
	User.other_user_name = "Empty Slot"

func _other_user_joined_lobby(username : String):
	var container = $Chat/ScrollContainer/VBoxContainer
	var msg_node = $Message_template.duplicate()	
	msg_node.show()
	msg_node.text = "SYSTEM: " + username + " joined!"
	container.add_child(msg_node)
	
	$"Player List/Players/Player2/Name".text = username
	User.other_user_name = username

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
	if User.is_host:
		if User.other_user_name == "Empty Slot":
			var pop_up = pop_up_template.instantiate()
			pop_up.set_msg("Need 2 players!")
			add_child(pop_up)
		else:
			User.connection.create_offer()
	else:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Only host can start the game!")
		add_child(pop_up)

func _initialize_host():
	var game_scene = game_scene_template.instantiate()
	var player_character = player_character_template.instantiate()
	var player2_character = player_character_template.instantiate()
	game_scene.set_multiplayer_authority(1)
	player_character.set_multiplayer_authority(1)
	player2_character.set_multiplayer_authority(2)
	player_character.global_position = Vector2(-344,41)
	player2_character.global_position = Vector2(347,37)
	player_character.name = "player_character"
	player2_character.name = "player_character2"
	get_parent().add_child(game_scene)
	get_parent().add_child(player_character)
	get_parent().add_child(player2_character)

	
	queue_free()


func _initialize_peer():
	var game_scene = game_scene_template.instantiate()
	var player_character = player_character_template.instantiate()
	var player2_character = player_character_template.instantiate()
	game_scene.set_multiplayer_authority(1)
	player_character.set_multiplayer_authority(1)
	player2_character.set_multiplayer_authority(2)
	player_character.global_position = Vector2(-344,41)
	player2_character.global_position = Vector2(347,37)
	player_character.name = "player_character"
	player2_character.name = "player_character2"
	get_parent().add_child(game_scene)
	get_parent().add_child(player_character)
	get_parent().add_child(player2_character)
	
	queue_free()



