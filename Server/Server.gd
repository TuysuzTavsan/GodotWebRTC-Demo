extends Node

enum Message {USER_INFO, LOBBY_LIST , NEW_LOBBY, JOIN_LOBBY, LEFT_LOBBY, LOBBY_MESSAGE, \
START_GAME, OFFER, ANSWER, ICE, GAME_STARTING, HOST}

var server = TCPServer.new()
var hard_coded_port = 9999
var peers : Dictionary = {}
var lobbies = []
var to_remove_lobbys = []
var to_remove_peers = []

class Peer extends RefCounted:
	var id : = -1
	var ws = WebSocketPeer.new()
	var user_name : String = ""
	var is_host : bool = false
	
	func _init(peer_id, tcp):
		id = peer_id
		var error = ws.accept_stream(tcp)
		if error != OK:
			print("ERROR! Can not accept stream from a connection request!")
		else:
			print("Peer connection successfully accepted!")
	
	func send_msg(type:int, id:int, data:=""):
		return ws.send_text(JSON.stringify({"type": type,"id": id,"data": data,}))

	func is_ws_open() -> bool:
		return ws.get_ready_state() == WebSocketPeer.STATE_OPEN


class Lobby extends RefCounted:
	var peers = []
	var sealed : bool = false
	var _name : String = ""
	
	func _init(host_id : int, _lobby_name : String):
		_name = _lobby_name


func _init():
	var error = server.listen(hard_coded_port)
	if error != OK:
		print("\nERROR! Can not create server! ERROR CODE = %d" % error)
	else:
		print("\n\nServer created successfully!")

func _process(delta):
	poll()
	clean_up()

func poll():
	if server.is_connection_available():
		var id = randi() % (1 << 31)
		peers[id] = Peer.new(id, server.take_connection())
	
	for p in peers.values():
		p.ws.poll()
		
		while p.is_ws_open() and p.ws.get_available_packet_count():
			if parse_msg(p):
				pass
			else:
				print("Message received! ERROR can not parse! ")
		
		if p.ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			print("Peer %d disconnected from server!" %p.id)
			to_remove_peers.push_back(p)

func parse_msg(peer : Peer) -> bool:
	var msg : String = peer.ws.get_packet().get_string_from_utf8()
	if msg == "Test msg!":
		print("Test msg received!")
		return true
	
	var parsed = JSON.parse_string(msg)
	if not typeof(parsed) == TYPE_DICTIONARY \
	or not parsed.has("type") \
	or not parsed.has("id") \
	or not parsed.has("data"):
		return false
	
	var accepted_msg = {
	"type": str(parsed.type).to_int(),
	"id": str(parsed.id).to_int(),
	"data": parsed.data
	}
	
	if not str(accepted_msg.type).is_valid_int() \
	or not str(accepted_msg.id).is_valid_int():
		return false
	
	var type := str(accepted_msg.type).to_int()
	var src_id := str(accepted_msg.id).to_int()
	var data : String = str(accepted_msg.data)
	
	
	if type == Message.GAME_STARTING:
		var current_lobby = find_lobby_by_peer(peer)
		if current_lobby:
			var all_peer_ids : String = ""
			for player in current_lobby.peers:
				all_peer_ids += str(player.id) + "***"
			
			for player in current_lobby.peers:
				player.send_msg(Message.GAME_STARTING, 0 , all_peer_ids)
			
		return true
	
	if type == Message.OFFER:
		var str_arr = data.split("***", true , 2)
		var send_to_id = str_arr[2].to_int()
		var receiver_peer = find_peer_by_id(send_to_id)
		if receiver_peer:
			receiver_peer.send_msg(type, peer.id, data)
			print("Sending received OFFER! to peer %d" %peer.id)
			return true
		else:
			print("ERROR: OFFER received but ID do not match with any peer!")
			return false
			
	if type == Message.ANSWER:
		var str_arr = data.split("***", true , 2)
		var send_to_id = str_arr[2].to_int()
		var receiver_peer = find_peer_by_id(send_to_id)
		if receiver_peer:
			receiver_peer.send_msg(type, peer.id, data)
			print("Sending received ANSWER! to peer %d" %peer.id)
			return true
		else:
			print("ERROR: ANSWER received but ID do not match with any peer!")
			return false
			
	if type == Message.ICE:
		var str_arr = data.split("***", true , 3)
		var send_to_id = str_arr[3].to_int()
		var receiver_peer = find_peer_by_id(send_to_id)
		if receiver_peer:
			receiver_peer.send_msg(type, peer.id, data)
			print("Sending received ICE! to peer %d" %peer.id)
			return true
		else:
			print("ERROR: ICE received but ID do not match with any peer!")
			return false
	
	if type == Message.LEFT_LOBBY:
		var lobby = find_lobby_by_name(data)
		if lobby:
			if lobby.peers.size() == 1:
				to_remove_lobbys.push_back(lobby)
				peer.is_host = false
			elif  lobby.peers.size() > 1:
					var delete_after : Peer
					for lobby_peer in lobby.peers:
							lobby_peer.is_host = false
							if lobby_peer.user_name != peer.user_name:
								lobby_peer.send_msg(Message.LEFT_LOBBY, peer.id, peer.user_name)
							if lobby_peer.user_name == peer.user_name:
								delete_after = lobby_peer
					
					lobby.peers.erase(delete_after)
					lobby.peers[0].is_host = true
					
					for player in lobby.peers:
						player.send_msg(Message.HOST, lobby.peers[0].id, lobby.peers[0].user_name)
			return true
	
	if type == Message.USER_INFO:
		peer.send_msg(Message.USER_INFO, peer.id, data)
		peer.user_name = data
		print("User name received! Received name: %s" %data)
		return true
	
	if type == Message.LOBBY_LIST:
		var list : String = ""
		
		for lobby in lobbies:
			list += lobby._name + " "
		
		peer.send_msg(Message.LOBBY_LIST, 0, list)
		print("Sending lobby list!")
		return true
	
	if type == Message.NEW_LOBBY:
		
		for lobby in lobbies:
			if lobby._name == data:
				print("New lobby request received! Requested name: %s ! ERROR: LOBBY NAME TAKEN!" %data)
				peer.send_msg(Message.NEW_LOBBY, 0, "INVALID")
				return true
		
		var lobby= Lobby.new(peer.id, data)
		peer.is_host = true
		lobby.peers.push_back(peer)
		lobbies.push_back(lobby)
		peer.ws.send_text(JSON.stringify("FEEDBACK: New lobby name: %s" %data))
		peer.send_msg(Message.NEW_LOBBY, 0, data)
		print("New lobby request received! Requested name: %s" %data)
		return true
	
	if type == Message.JOIN_LOBBY:
		peer.ws.send_text(JSON.stringify("FEEDBACK: Join lobby name: %s" %data))
		
		var lobby = find_lobby_by_name(data)
		if lobby:
			peer.send_msg(Message.HOST, lobby.peers[0].id, lobby.peers[0].user_name)
			peer.send_msg(Message.JOIN_LOBBY, 0, "LOBBY_NAME" + lobby._name)
			
			for lobby_player in lobby.peers:
				lobby_player.send_msg(Message.JOIN_LOBBY, peer.id, "NEW_JOINED_USER_NAME" + peer.user_name)
				peer.send_msg(Message.JOIN_LOBBY, lobby_player.id, "EXISTING_USER_NAME" + lobby_player.user_name)
			
			lobby.peers.push_back(peer)
			print("Join lobby request received! Requested name: %s" %data)
			return true
		else:
			print("Join lobby request received! Requested name: %s ! ERROR: NO SUCH LOBBY!" %data)
			peer.send_msg(Message.JOIN_LOBBY, 0, "INVALID")
			return true
	
	if type == Message.LOBBY_MESSAGE:
		for i in lobbies:
			if i.peers.has(peer):
				for j in i.peers:
					j.send_msg(Message.LOBBY_MESSAGE, 0, data)
				return true
	
	
	return false;


func clean_up():
	for peer in to_remove_peers:
		peers.erase(peer.id)
	
	
	for lobby in to_remove_lobbys:
		lobbies.erase(lobby)
	
	var temp_arr : Array
	for lobby in lobbies:
		for lobby_player in lobby.peers:
			if not peers.has(lobby_player.id):
				temp_arr.push_back(lobby_player)
	
	
	for disconnected_peer in temp_arr:
		var searched_lobby = find_lobby_by_peer(disconnected_peer)
		if searched_lobby:
			if searched_lobby.peers.size() > 2:
				disconnected_peer.is_host = false
				searched_lobby.peers[0].is_host = true
			for peer in searched_lobby.peers:
				if not disconnected_peer == peer:
					peer.send_msg(Message.LEFT_LOBBY, disconnected_peer.id, disconnected_peer.user_name)
		
		searched_lobby.peers.erase(disconnected_peer)
		if searched_lobby.peers.size() == 0:
			to_remove_lobbys.push_back(searched_lobby)


func find_peer_by_id(id):
	for peer_id in peers.keys():
		if id == peer_id:
			return peers[peer_id]
	
	return false

func find_lobby_by_peer(peer : Peer):
	for lobby in lobbies:
		for lobby_player in lobby.peers:
			if lobby_player == peer:
				return lobby
	
	return false

func find_lobby_by_name(lobby_name : String):
	for lobby in lobbies:
		if lobby._name == lobby_name:
			return lobby
	
	return false
