extends Node

class_name GameSocket

var _client = WebSocketPeer.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY

signal update_game_state(new_state)
signal game_ended(win)

func play_card(id):
	print("Sending Play Card: ", id)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_playCard()
	jq.set_cardId(id)
	for c in GS.selected:
		jq.add_targets(c)
	GS.selected = []
	GS.selection_info = null
	send_message(cm)

func activate_card(id):
	print("Sending Activate Card: ", id)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_activateCard()
	jq.set_cardId(id)
	jq.set_abilityId(GS.selection_info.get_id())
	for c in GS.selected:
		jq.add_targets(c)
	GS.selected = []
	GS.selection_info = null
	send_message(cm)

func study_card(id):
	print("Sending Study Card: ", id)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_studyCard()
	jq.set_cardId(id)
	if GS.selected.size() > 0:
		jq.set_selectedKnowledge(GS.selected[0])
		GS.selected = []
	send_message(cm)

func keep():
	print("Sending Keep")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	cm.new_keep()
	send_message(cm)

func redraw():
	print("Sending Redraw")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	cm.new_redraw()
	send_message(cm)

func pass_():
	print("Sending Pass")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	cm.new_pass()
	send_message(cm)

func select_attackers():
	print("Sending Attackers: ")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_selectAttackers()
	if GS.selected:
		for a in GS.selected:
			var att = jq.add_attackers()
			att.set_attackerId(a)
			att.set_attacksTo(GS.gameState.get_opponent().get_id())
	GS.selected = []
	send_message(cm)

func select_blockers(blockers = null):
	print("Sending Blockers: ", blockers)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_selectBlockers()
	if GS.selected:
		for a in GS.selected:
			var att = jq.add_blockers()
			att.set_blockerId(a[0])
			att.set_blockedBy(a[1])
	GS.selected = []
	send_message(cm)

func select_from():
	print("Sending SelectFrom: ")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_selectFromResponse()
	jq.set_messageType(GS.select_from_type)
	if GS.selected:
		for a in GS.selected:
			jq.add_selected(a)
	GS.selected = []
	GS.select_from_type = null
	GS.selection_info = null
	send_message(cm)

func decode_proto_message(data):
	var message = GS.ServerGameMessages.ServerGameMessage.new()
	var result_code = message.from_bytes(data)
	if result_code == GS.ServerGameMessages.PB_ERR.NO_ERRORS:
		print("GAME OK")
	else:
		print("GAME ERROR: ", result_code)
		print("GAME ERROR: ", message.to_string())
		return


	#print("Game Data received: ", message.to_string())
	GS.is_waiting = false
	if message.has_updateGameStateP():
		var lr = message.get_updateGameStateP()
		update_game_state.emit(lr.get_game())

	elif message.has_selectFrom():
		var lr = message.get_selectFrom()
		GS.selection_info = lr.get_targets()
		GS.select_from_type = lr.get_messageType()
		GS.selected = []
		update_game_state.emit(lr.get_game())

	elif message.has_gameEnd():
		var lr = message.get_endGame()
		update_game_state.emit(lr.get_game())
		game_ended.emit(lr.get_win())

	elif message.has_newDraft():
		print("New Draft: ", message.get_newDraft())
		var lr = message.get_newDraft()
		var draftState = lr.get_draft()
		#Create new draft here

func connect_to_server():
	_client.connect_to_url(GS.get_game_URL())
	GS.is_waiting = false

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
	GS.is_waiting = true
	_client.send(data.to_bytes(), _write_mode)
