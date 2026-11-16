extends Node

class_name Websocket

var _client = WebSocketPeer.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var _polling = false

signal initialize_game_state(new_state)
signal got_login_response()
signal got_collection(collection)
signal connection_failed(reason)

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
		GS.gameType = lr.get_gameType()
		GS.is_spectating_ai_match = GS.gameType == GS.Types.GameType.AI_VS_AI
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
	GS.connection_error = ""
	GS.is_waiting = true
	if GS.userId.is_empty():
		GS.userId = str(randi_range(1, 100000))
	var error = _client.connect_to_url(GS.get_profile_URL())
	_polling = error == OK
	if error != OK:
		_fail("Could not connect to the profile service: %s" % error_string(error))
	return error

func _process(_delta):
	if not _polling:
		return
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		_client_received()
	elif state == WebSocketPeer.STATE_CLOSED:
		_polling = false
		_fail("Profile connection closed (%d): %s" % [_client.get_close_code(), _client.get_close_reason()])

func close():
	_polling = false
	_client.close(1001, "Leaving profile")

func _exit_tree():
	close()

func _client_received():
	while _client.get_available_packet_count():
		decode_proto_message(_client.get_packet())

func _fail(reason):
	GS.is_waiting = true
	GS.connection_error = reason
	connection_failed.emit(reason)

func send_message(data):
	if _client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_fail("The profile connection is not open.")
		return ERR_UNAVAILABLE
	var error = _client.send(data.to_bytes(), _write_mode)
	if error != OK:
		_fail("Could not send profile request: %s" % error_string(error))
		return error
	GS.is_waiting = true
	GS.connection_error = ""
	return OK
