extends Node

enum Message {USER_NAME, LOBBY_LIST , NEW_LOBBY, JOIN_LOBBY, LEFT_LOBBY, LOBBY_MESSAGE, START_GAME, OFFER, ANSWER, ICE}

var server = TCPServer.new()
var hard_coded_port = 9999
var peers : Dictionary = {}
var lobbies = []
var to_remove = []


class Peer extends RefCounted:
	var id = -1
	var ws = WebSocketPeer.new()
	var user_name : String = ""
	
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
		var id = randi() % (1 << 31) + 1
		peers[id] = Peer.new(id, server.take_connection())
	
	for p in peers.values():
		p.ws.poll()
		
		while p.is_ws_open() and p.ws.get_available_packet_count():
			if parse_msg(p):
				pass
			else:
				print("Message received! ERROR can not parse! ")
		
		var state = p.ws.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			print("Peer %d disconnected from server!" %p.id)
			peers.erase(p.id)

func parse_msg(peer : Peer) -> bool:
	var msg : String = peer.ws.get_packet().get_string_from_utf8()
	if msg == "Test msg!":
		print("Succesfull connection!")
		return true
	
	var parsed = JSON.parse_string(msg)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("type") or not parsed.has("id") or \
	typeof(parsed.get("data")) != TYPE_STRING:
		return false
	if not str(parsed.type).is_valid_int() or not str(parsed.id).is_valid_int():
		return false
	
	var accepted_msg = {
		"type": str(parsed.type).to_int(),
		"id": str(parsed.id).to_int(),
		"data": parsed.data
	}
	
	if accepted_msg.type == Message.OFFER:
		find_lobby(peer).send_msg(Message.OFFER, 0, accepted_msg.data)
		print("Sending received offer !")
		return true
	
	if accepted_msg.type == Message.ANSWER:
		find_lobby(peer).send_msg(Message.ANSWER, 0, accepted_msg.data)
		print("Sending received answer!")
		return true
	
	if accepted_msg.type == Message.ICE:
		find_lobby(peer).send_msg(Message.ICE, 0, accepted_msg.data)
		print("Sending received ICE!")
		return true
	
	if accepted_msg.type == Message.LEFT_LOBBY:
		for i in lobbies:
			if i._name == accepted_msg.get("data"):
				if i.peers.size() == 1:
					to_remove.push_back(i)
				elif  i.peers.size() == 2:
					
					var delete_this : Peer
					for j in i.peers:
						if j.user_name != peer.user_name:
							j.send_msg(Message.LEFT_LOBBY, 0, peer.user_name)
						if j.user_name == peer.user_name:
							delete_this = j
					i.peers.erase(delete_this)
				return true
	
	if accepted_msg.type == Message.USER_NAME:
		peer.send_msg(Message.USER_NAME, 0, accepted_msg.data)
		peer.user_name = accepted_msg.get("data")
		print("User name received! Received name: %s" %accepted_msg.get("data"))
		return true
	
	if accepted_msg.type == Message.LOBBY_LIST:
		var list : String = ""
		
		for lobby in lobbies:
			list += lobby._name + " "
		
		peer.send_msg(Message.LOBBY_LIST, 0, list)
		print("Sending lobby list!")
		return true
	
	if accepted_msg.type == Message.NEW_LOBBY:
		
		for _lobby in lobbies:
			if _lobby._name == accepted_msg.get("data"):
				print("New lobby request received! Requested name: %s ! ERROR: LOBBY NAME TAKEN!" %accepted_msg.get("data"))
				peer.send_msg(Message.NEW_LOBBY, 0, "INVALID")
				return true
		
		var lobby = Lobby.new(peer.id, accepted_msg.get("data"))
		lobby.peers.push_back(peer)
		lobbies.push_back(lobby)
		peer.ws.send_text(JSON.stringify("FEEDBACK: New lobby name: %s" %accepted_msg.get("data")))
		peer.send_msg(Message.NEW_LOBBY, 0, accepted_msg.get("data"))
		print("New lobby request received! Requested name: %s" %accepted_msg.get("data"))
		return true
	
	if accepted_msg.type == Message.JOIN_LOBBY:
		peer.ws.send_text(JSON.stringify("FEEDBACK: Join lobby name: %s" %accepted_msg.get("data")))
		
		for _lobby in lobbies:
			if _lobby._name == accepted_msg.get("data"):
				if _lobby.peers.size() == 1:
					_lobby.peers[0].send_msg(Message.JOIN_LOBBY, 1, peer.user_name)
				peer.send_msg(Message.JOIN_LOBBY, 2, _lobby.peers[0].user_name)
				peer.send_msg(Message.JOIN_LOBBY, 0, _lobby._name)
				_lobby.peers.push_back(peer)
				print("Join lobby request received! Requested name: %s" %accepted_msg.get("data"))
				return true
			
		print("Join lobby request received! Requested name: %s ! ERROR: NO SUCH LOBBY!" %accepted_msg.get("data"))
		peer.send_msg(Message.JOIN_LOBBY, 0, "INVALID")
		return true
	
	if accepted_msg.type == Message.LOBBY_MESSAGE:
		for i in lobbies:
			if i.peers.has(peer):
				for j in i.peers:
					j.send_msg(Message.LOBBY_MESSAGE, 0, accepted_msg.get("data"))
				return true
	
	
	return false;


func clean_up():
	for i in to_remove:
		lobbies.erase(i)
	
	var temp_arr : Array
	for i in lobbies:
		for j in i.peers:
			if peers.has(j.id):
				continue
			else:
				temp_arr.push_back(j)
		
		for k in temp_arr:
			i.peers.erase(k)
		
		if i.peers.size() == 0:
			to_remove.push_back(i)

func find_lobby(peer : Peer):
	for i in lobbies:
		if i.peers.has(peer) and i.peers.size() == 2:
			for a in i.peers:
				if a != peer:
					return a
