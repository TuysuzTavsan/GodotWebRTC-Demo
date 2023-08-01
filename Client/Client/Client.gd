extends Node
class_name Client

enum Message {USER_NAME, LOBBY_LIST , NEW_LOBBY, JOIN_LOBBY, LEFT_LOBBY, LOBBY_MESSAGE, START_GAME, OFFER, ANSWER, ICE}

var rtc_mp = WebRTCMultiplayerPeer.new()
var ws = WebSocketPeer.new()
var url = "ws://127.0.0.1:9999"
var client_connected : bool = false

signal invalid_new_lobby_name
signal invalid_join_lobby_name
signal join_lobby(lobby_name : String)
signal new_lobby(lobby_name : String)
signal lobby_list_received(lobby_list : PackedStringArray)
signal lobby_messsage_received(message : String, user_name : String)
signal other_user_joined_lobby(user_name : String)
signal host_name_received(host_name : String)
signal some_one_left_lobby(player_name : String)
signal offer_received(type: String, sdp: String)
signal answer_received(type: String, sdp: String)
signal ice_received(media: String, index: int, _name: String)
signal user_name_feedback_received
signal reset_connection

func _init():
	var error = ws.connect_to_url(url)
	if error != OK:
		print ("ERROR: Can not connect to url!")

func is_connection_valid() -> bool:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var error = ws.send_text("Test msg!")
		if error == OK:
			print("Connection seems OK! (But no server feedback at this point!)")
			return true
		else:
			print("ERROR: Connection failed!")
	
	return false

func _process(delta):
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count():
			parse_msg()
	elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = ws.get_close_code()
		var reason = ws.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.
		client_connected = false
		reset_connection.emit()

func parse_msg():
	var parsed = JSON.parse_string(ws.get_packet().get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("type") or not parsed.has("id") or \
	typeof(parsed.get("data")) != TYPE_STRING:
		return false
	
	var msg := parsed as Dictionary
	if not str(msg.type).is_valid_int() or not str(msg.id).is_valid_int():
		return false
	
	var type := str(msg.type).to_int()
	var src_id := str(msg.id).to_int()
	var data : String = str(msg.data)
	
	if type == Message.USER_NAME:
		User.user_name = data
		user_name_feedback_received.emit()
		client_connected = true
	
	if type == Message.ICE:
		var str_arr = data.split("***", true , 2)
		var media : String = str_arr[0]
		var index : int = int(str_arr[1])
		var _name : String = str_arr[2]
		ice_received.emit(media, index, _name)
		return
	
	if type == Message.ANSWER:
		var str_arr = data.split("***", true , 1)
		var _type : String = str_arr[0]
		var sdp : String = str_arr[1]
		answer_received.emit(_type, sdp)
		return
	
	if type == Message.OFFER:
		var str_arr = data.split("***", true , 1)
		var _type : String = str_arr[0]
		var sdp : String = str_arr[1]
		offer_received.emit(_type, sdp)
		return
	
	if type == Message.NEW_LOBBY:
		if data == "INVALID":
			invalid_new_lobby_name.emit()
			return
		else:
			new_lobby.emit(data)
			return
	
	if type == Message.JOIN_LOBBY:
		if src_id == 0:
			if data == "INVALID":
				invalid_join_lobby_name.emit()
				return
			else:
				join_lobby.emit(data)
				return
		if  src_id == 1:
			other_user_joined_lobby.emit(data)
			return
		if  src_id == 2:
			host_name_received.emit(data)
			return
	
	if type == Message.LOBBY_LIST:
		if data == "":
			var e : PackedStringArray
			print("Lobby list is empty!")
			lobby_list_received.emit(e)
			return
		else:
			var lobby_list_arr = data.split(" ", false)
			print("Lobby list received!")
			lobby_list_received.emit(lobby_list_arr)
			return
	
	if type == Message.LEFT_LOBBY:
		some_one_left_lobby.emit(data)
		print("Player: %s left this lobby !" %data)
		return
	
	if type == Message.LOBBY_MESSAGE:
		print("Lobby message received!")
		var arr = data.split("***", true, 1)
		var user_name = arr[0]
		var message = arr[1]
		lobby_messsage_received.emit(message, user_name)
	
	
	return false

func is_client_connected() -> bool:
	return client_connected











func send_user_name(_name : String):
	send_msg(Message.USER_NAME, 0, _name)

func request_lobby_list():
	send_msg(Message.LOBBY_LIST, 0, "")

func request_join_lobby(lobby_id : String):
	send_msg(Message.JOIN_LOBBY, 0, lobby_id)

func request_new_lobby(_name : String):
	send_msg(Message.NEW_LOBBY, 0, _name)

func send_chat_msg(message : String, user_name : String):
	var _message : String = user_name + "***" + message
	send_msg(Message.LOBBY_MESSAGE, 0 , _message)

func send_msg(type: int, id:int, data:String) -> int:
	return ws.send_text(JSON.stringify({"type": type, "id": id, "data": data}))

func send_left_info(lobby_name : String):
	send_msg(Message.LEFT_LOBBY, 0, lobby_name)

func send_start_game(lobby_name : String):
	send_msg(Message.START_GAME, 0, lobby_name)

func send_offer(type: String, sdp: String):
	send_msg(Message.OFFER, 0, type + "***" + sdp)

func send_answer(type: String, sdp: String):
	send_msg(Message.ANSWER, 0, type + "***" + sdp)

func send_ice(media: String, index: int, _name: String):
	send_msg(Message.ICE, 0, media + "***" + str(index) + "***" + _name )
