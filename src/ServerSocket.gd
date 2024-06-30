extends Node

class_name Websocket

var _client = WebSocketPeer.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY

signal initialize_game_state(new_state)
signal got_login_response()
signal got_collection(collection)

func get_collection():
	print("Getting Collection")
	var cm = GS.ClientMessages.ClientMessage.new()
	var jq = cm.new_getCollection()
	send_message(cm)

func joinQueue(type):
	var cm = GS.ClientMessages.ClientMessage.new()
	var jq = cm.new_joinQueue()
	GS.gameType = type
	jq.set_gameType(type)
	GS.game_decklist.map(func(c): jq.add_decklist(c))
	send_message(cm)

func decode_proto_message(data):
	var message = GS.ServerMessages.ServerMessage.new()
	var result_code = message.from_bytes(data)
	if result_code == GS.ServerMessages.PB_ERR.NO_ERRORS:
		print("OK")
	else:
		print("ERR: ", result_code)
		print("ERR: ", message.to_string())
		return

	GS.is_waiting = false
	#print("Data received: ", message.to_string())
	if message.has_loginResponse():
		var lr = message.get_loginResponse()
		GS.gameId = lr.get_gameId();
		GS.playerId = lr.get_playerId();
		print("Login Response: \n\tGameID: ", GS.gameId, "\n\tPlayerId: ", GS.playerId)
		got_login_response.emit()

	elif message.has_newGame():
		print("New Game: ")
		var lr = message.get_newGame()
		GS.gameId = lr.get_game().get_id();
		GS.playerId = lr.get_game().get_player().get_id();
		GS.aiId = lr.get_aiId()
		initialize_game_state.emit(lr.get_game())

	elif message.has_getCollectionResponse():
		print("Got Collection: ")
		var lr = message.get_getCollectionResponse()
		got_collection.emit(lr.get_cards())

		# Create a new game here

	elif message.has_newDraft():
		print("New Draft: ", message.get_newDraft())
		var lr = message.get_newDraft()
		var draftState = lr.get_draft()
		#Create new draft here


func connect_to_server():
	print("Connecting")
	randomize()
	GS.userId = str(randi() % 100000 +1)
	_client.connect_to_url(GS.websocket_url+GS.userId)

func _process(_delta):
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		_client_received()
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.
		GS.socket = null


func _client_close_request(code, reason):
	print("Close code: %d, reason: %s" % [code, reason])


func _peer_connected(id):
	print("%s: Client just connected" % id)


func _exit_tree():
	_client.disconnect_from_host(1001, "Bye bye!")


func _client_connected(protocol):
	print("Client just connected with protocol: %s" % protocol)
	_client.get_peer(1).set_write_mode(_write_mode)


func _client_disconnected(clean=true):
	print("Client just disconnected. Was clean: %s" % clean)

func _client_received(_p_id = 1):
	while _client.get_available_packet_count():
		decode_proto_message(_client.get_packet())


func send_message(data):
	GS.is_waiting = true
	_client.send(data.to_bytes(), _write_mode)
