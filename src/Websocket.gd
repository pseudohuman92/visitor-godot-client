extends Node

class_name Websocket

var _client = WebSocketPeer.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var buf_size = 65536*8

var decklist = ["3;base.Eagle",
			"3;base.Hawk",
			"3;base.Leech",

			"3;base.Owl",
			"3;base.Ox",
			"3;base.Pistol Shrimp",
			"3;base.Porcupine",
			"3;base.Seagull",
			"3;base.Sparrow",
			"3;base.Turtle"]

signal initialize_game_state(new_state)
signal got_login_response()

func joinQueue():
	var cm = GlobalState.ClientMessages.ClientMessage.new()
	var jq = cm.new_joinQueue()
	jq.set_gameType(GlobalState.Types.GameType.AI_BO1_CONSTRUCTED)
	decklist.map(func(c): jq.add_decklist(c))
	send_message(cm)

func decode_proto_message(data):
	var message = GlobalState.ServerMessages.ServerMessage.new()
	var result_code = message.from_bytes(data)
	if result_code == GlobalState.ServerMessages.PB_ERR.NO_ERRORS:
		print("OK")
	else:
		print("ERR: ", result_code)
		
	
	GlobalState.is_waiting = false
	print("Data received: ", message.to_string())
	if message.has_loginResponse():
		var lr = message.get_loginResponse()
		GlobalState.gameId = lr.get_gameId();
		GlobalState.playerId = lr.get_playerId();
		print("Login Response: \n\tGameID: ", GlobalState.gameId, "\n\tPlayerId: ", GlobalState.playerId)
		got_login_response.emit()
		
	elif message.has_newGame():
		print("New Game: ")
		var lr = message.get_newGame()
		GlobalState.gameType = lr.get_gameType()
		GlobalState.aiId = lr.get_aiId()
		initialize_game_state.emit(lr.get_game())
		# Create a new game here
	elif message.has_newDraft():
		print("New Draft: ", message.get_newDraft())
		var lr = message.get_newDraft()
		var draftState = lr.get_draft()
		#Create new draft here
	

func connect_to_server():
	print("Connecting")
	_client.set_inbound_buffer_size(buf_size)
	_client.set_outbound_buffer_size(buf_size)
	randomize()	
	GlobalState.userId = str(randi() % 100000 +1)
	_client.connect_to_url(GlobalState.websocket_url+GlobalState.userId)
	
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
	GlobalState.is_waiting = true
	_client.send(data.to_bytes(), _write_mode)
