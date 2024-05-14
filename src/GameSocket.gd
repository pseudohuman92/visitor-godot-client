extends Node

class_name GameSocket

var _client = WebSocketPeer.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var websocket_url
var buf_size= 65536*8

signal update_game_state(new_state)
signal game_ended(win)

func play_card(id):
	print("Sending Play Card: ", id)
	var cm = GlobalState.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_playCard()
	jq.set_cardID(id)
	send_message(cm)

func study_card(id):
	print("Sending Study Card: ", id)
	var cm = GlobalState.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_studyCard()
	jq.set_cardID(id)
	send_message(cm)

func keep():
	print("Sending Keep")
	var cm = GlobalState.ClientGameMessages.ClientGameMessage.new()
	cm.new_keep()
	send_message(cm)
	
func redraw():
	print("Sending Redraw")
	var cm = GlobalState.ClientGameMessages.ClientGameMessage.new()
	cm.new_redraw()
	send_message(cm)
	
func pass_():
	print("Sending Pass")
	var cm = GlobalState.ClientGameMessages.ClientGameMessage.new()
	cm.new_pass()
	send_message(cm)

func decode_proto_message(data):
	var message = GlobalState.ServerGameMessages.ServerGameMessage.new()
	var result_code = message.from_bytes(data)
	if result_code == GlobalState.ServerGameMessages.PB_ERR.NO_ERRORS:
		print("GAME OK")
	else:
		print("GAME ERROR: ", result_code)
		

	print("Game Data received: ", message.to_string())
	GlobalState.is_waiting = false
	if message.has_updateGameStateP():
		var lr = message.get_updateGameStateP()
		update_game_state.emit(lr.get_game())
		
	elif message.has_endGame():
		var lr = message.get_endGame()
		update_game_state.emit(lr.get_game())
		game_ended.emit(lr.get_win())

	elif message.has_newDraft():
		print("New Draft: ", message.get_newDraft())
		var lr = message.get_newDraft()
		var draftState = lr.get_draft()
		#Create new draft here
	

func _init():
	websocket_url = GlobalState.get_game_URL()

func connect_to_server():
	_client.set_inbound_buffer_size(buf_size)
	_client.set_outbound_buffer_size(buf_size)
	_client.connect_to_url(websocket_url)
	GlobalState.is_waiting = false
	
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
		print("GameSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.


func _client_close_request(code, reason):
	print("Close code: %d, reason: %s" % [code, reason])


func _peer_connected(id):
	print("%s: Client just connected" % id)


func _exit_tree():
	_client.disconnect_from_host(1001, "Bye bye!")


func _client_connected(protocol):
	print("Client just connected with protocol: %s" % protocol)
	_client.set_write_mode(_write_mode)


func _client_disconnected(clean=true):
	print("Client just disconnected. Was clean: %s" % clean)


func _client_received():
	while _client.get_available_packet_count():
		decode_proto_message(_client.get_packet())

func send_message(data):
	GlobalState.is_waiting = true
	_client.send(data.to_bytes(), _write_mode)
