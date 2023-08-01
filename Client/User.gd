extends Node

var client : Client = Client.new()
var user_name : String = ""
var other_user_name : String = "Empty Slot"
var current_lobby_name : String = ""
var current_lobby_list : String = ""
var is_host : bool = false

var connection : WebRTCPeerConnection
var rtc_peer : WebRTCMultiplayerPeer

signal reset
signal initialize_host
signal initialize_peer

func after_main_menu_init():
	client.offer_received.connect(_offer_received)
	client.answer_received.connect(_answer_received)
	client.ice_received.connect(_ice_received)
	client.reset_connection.connect(reset_connection)

func init_connection():
	connection = WebRTCPeerConnection.new()
	rtc_peer = WebRTCMultiplayerPeer.new()
	connection.initialize({"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"]}]})
	connection.session_description_created.connect(session_created)
	connection.ice_candidate_created.connect(ice_created)
	if is_host:
		rtc_peer.create_server()
		rtc_peer.add_peer(connection, 2)
		#client.get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
		rtc_peer.peer_connected.connect(_peer_connected)
		rtc_peer.peer_disconnected.connect(_peer_disconnected)
		client.get_tree().get_multiplayer().multiplayer_peer = rtc_peer
	else:
		rtc_peer.create_client(2)
		rtc_peer.add_peer(connection, 1)
		rtc_peer.peer_connected.connect(_peer_connected)
		rtc_peer.peer_disconnected.connect(_peer_disconnected)
		#client.get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
		client.get_tree().get_multiplayer().multiplayer_peer = rtc_peer
		client.get_tree().get_multiplayer().connected_to_server.connect(_connected_to_host)


func session_created(type: String, sdp: String):	
	connection.set_local_description(type, sdp)
	if type == "offer":
		client.send_offer(type, sdp)
		print("sending offer")
	else:
		client.send_answer(type, sdp)
		print("sending answer")

func ice_created(media: String, index: int, _name: String):
	client.send_ice(media, index, _name)
	print("sending ice")

func _ice_received(media: String, index: int, _name: String):
	connection.add_ice_candidate(media, index, _name)
	print("ice received")

func _offer_received(type: String, sdp: String):
	connection.set_remote_description(type, sdp)

func _answer_received(type: String, sdp: String):
	connection.set_remote_description(type, sdp)


func _peer_connected(id : int):
	print("Peer connected with id %d" %id)

func _peer_disconnected(id : int):
	print("Peer disconnected with id %d" %id)

func _connected_to_host():
	print("Connected to host")
	print("Trying to initialize game and send feedback to host!")
	initialize_game.rpc()

@rpc("any_peer","call_local","reliable")
func initialize_game():
	if is_host:
		initialize_host.emit()
	else:
		initialize_peer.emit()


func reset_connection():
	client.queue_free()
	client = Client.new()
	user_name = ""
	is_host = false
	current_lobby_list = ""
	current_lobby_name = ""
	other_user_name = "Empty Slot"
	print("User reset!")
	reset.emit()
