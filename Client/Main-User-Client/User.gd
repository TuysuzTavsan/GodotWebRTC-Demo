extends Node

var client : Client
var user_name : String = ""
var host_name : String = ""
var current_lobby_name : String = ""
var current_lobby_list : String = ""
var is_host : bool = false
var ID = -1
var peers : Dictionary
var game_scene_template = preload("res://Scenes/game_scene/game_scene.tscn")
var player_character_template = preload("res://Scenes/player_character/player_character.tscn")

var connection_list : Dictionary = {}
var rtc_peer : WebRTCMultiplayerPeer

signal reset
signal delete_in_lobby_menu

func after_main_menu_init():
	client.offer_received.connect(_offer_received)
	client.answer_received.connect(_answer_received)
	client.ice_received.connect(_ice_received)
	client.reset_connection.connect(reset_connection)
	client.game_start_received.connect(_game_start_received)

func init_connection():
	rtc_peer = WebRTCMultiplayerPeer.new()
	rtc_peer.create_mesh(ID)
	
	connection_list.clear()
	
	for peer_id in peers.keys():
		var connection = WebRTCPeerConnection.new()
		connection.initialize({"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"]}]})
		connection.session_description_created.connect(session_created.bind(connection))
		connection.ice_candidate_created.connect(ice_created.bind(connection))
		connection_list[peer_id] = connection
		rtc_peer.add_peer(connection, peer_id)
	
	for peer_id in peers.keys():
		print("PEER LIST: Name: %s with ID# %d" %[peers.get(peer_id), peer_id])
	
	rtc_peer.peer_connected.connect(_peer_connected)
	rtc_peer.peer_disconnected.connect(_peer_disconnected)
	get_tree().get_multiplayer().multiplayer_peer = rtc_peer


func session_created(type: String, sdp: String, connection : WebRTCLibPeerConnection):
		connection.set_local_description(type, sdp)
		if type == "offer":
			client.send_offer(type, sdp, connection_list.find_key(connection))
			print("sending offer")
		else:
			client.send_answer(type, sdp, connection_list.find_key(connection))
			print("sending answer")

func ice_created(media: String, index: int, _name: String, connection : WebRTCLibPeerConnection):
		client.send_ice(media, index, _name, connection_list.find_key(connection))
		print("sending ice")


func _ice_received(media: String, index: int, _name: String, sender_id):
	connection_list.get(sender_id).add_ice_candidate(media, index, _name)
	print("ice received")

func _offer_received(type: String, sdp: String, sender_id):
	connection_list.get(sender_id).set_remote_description(type, sdp)
	print("offer received")

func _answer_received(type: String, sdp: String, sender_id):
	connection_list.get(sender_id).set_remote_description(type, sdp)
	print("answer received")

func _peer_connected(id : int):
	delete_in_lobby_menu.emit()
	
	var game_scene_node = get_node("../game_scene")
	if not game_scene_node:
		var game_scene = game_scene_template.instantiate()
		game_scene.set_multiplayer_authority(User.ID)
		game_scene.name = "game_scene"
		get_parent().add_child(game_scene)
	
	game_scene_node = get_node("../game_scene")
	var check_my_player = game_scene_node.get_node("%s" %ID)
	if not check_my_player:
		var player_character = player_character_template.instantiate()
		player_character.set_multiplayer_authority(User.ID)
		player_character.name = str(User.ID)
		game_scene_node.add_child(player_character)
	
	var player_character = player_character_template.instantiate()
	player_character.set_multiplayer_authority(id)
	player_character.name = str(id)
	game_scene_node.add_child(player_character)
	
	for connection in connection_list.values():
		print("Peer connected with id %d" %connection_list.find_key(connection))

func _peer_disconnected(id : int):
	print("Peer disconnected with id %d" %id)
	connection_list.erase(id)
	
	get_node("../game_scene/%s" %id).queue_free()

func _game_start_received(peer_ids : String):
	
	var arr = peer_ids.split("***", false)
	
	
	for id_string in arr:
		User.connection_list.get(id_string.to_int()).create_offer()

func reset_connection():
	for connection in connection_list.values():
		connection.close()
	
	
	client.queue_free()
	client = Client.new()
	user_name = ""
	is_host = false
	current_lobby_list = ""
	current_lobby_name = ""
	host_name = ""
	print("User reset!")
	ID = -1
	peers.clear()
	reset.emit()

