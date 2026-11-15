extends Node

class_name GameSocket

var _client = WebSocketPeer.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var _polling = false

signal update_game_state(new_state)
signal game_ended(win)
signal decision_requested(kind, request)
signal connection_failed(reason)

func play_card(id):
	print("Sending Play Card: ", id)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_playCard()
	jq.set_cardId(id)
	for c in SS.selected.values():
		var ts = jq.add_targets()
		ts.set_id(c["selection_id"])
		for t in c["selected"]:
			ts.add_targets(t)
	SS.clear_selection_data()
	send_message(cm)

func activate_card(id):
	print("Sending Activate Card: ", id)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_activateCard()
	jq.set_cardId(id)
	jq.set_abilityId(SS.selection_ability_id)
	for c in SS.selected.values():
		var ts = jq.add_targets()
		ts.set_id(c["selection_id"])
		for t in c["selected"]:
			ts.add_targets(t)
	SS.clear_selection_data()
	send_message(cm)

func study_card(id):
	print("Sending Study Card: ", id)
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_studyCard()
	jq.set_cardId(id)
	if SS.selected_single.size() > 0:
		jq.set_selectedKnowledge(SS.selected_single[0])
	SS.clear_selection_data()
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
	for a in SS.selected_single:
		var att = jq.add_attackers()
		att.set_attackerId(a)
		att.set_attacksTo(GS.gameState.get_opponent().get_id())
	SS.clear_selection_data()
	send_message(cm)

func select_blockers():
	print("Sending Blockers: ")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_selectBlockers()
	for a in SS.selected.values():
		var att = jq.add_blockers()
		att.set_blockerId(a[0].card.get_id())
		att.set_blockedBy(a[1].card.get_id())
	SS.clear_selection_data()
	send_message(cm)

func select_from():
	print("Sending SelectFrom: ")
	var cm = GS.ClientGameMessages.ClientGameMessage.new()
	var jq = cm.new_selectFromResponse()
	jq.set_messageType(SS.select_from_type)
	for a in SS.selected_single:
		jq.add_selected(a)
	SS.clear_selection_data()
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

	GS.is_waiting = false
	GS.pending_decision = ""
	GS.connection_error = ""
	if message.has_updateGameStateP():
		var lr = message.get_updateGameStateP()
		update_game_state.emit(lr.get_game())

	elif message.has_selectFrom():
		var lr = message.get_selectFrom()
		GS.gameState = lr.get_game()
		SS.clear_selection_data()
		SS.callback = select_from
		SS.select_from_type = lr.get_messageType()
		SS.process_selection(lr.get_targets())
		update_game_state.emit(lr.get_game())

	elif message.has_gameEnd():
		var lr = message.get_gameEnd()
		GS.is_waiting = true
		update_game_state.emit(lr.get_game())
		SFX.finish_match(lr.get_game().get_id(), lr.get_win())
		game_ended.emit(lr.get_win())

	# These schema features have no complete decision UI in this client yet.
	# Surface them explicitly, preserve the snapshot, and prevent accidental passes.
	elif message.has_orderCards():
		request_decision("orderCards", message.get_orderCards())
	elif message.has_selectXValue():
		request_decision("selectXValue", message.get_selectXValue())
	elif message.has_assignDamage():
		request_decision("assignDamage", message.get_assignDamage())
	elif message.has_selectKnowledge():
		request_decision("selectKnowledge", message.get_selectKnowledge())
	elif message.has_pickCard():
		request_decision("pickCard", message.get_pickCard())
	else:
		_fail("Received a match message without a supported payload.")

func request_decision(kind, request):
	GS.pending_decision = kind
	GS.is_waiting = true
	GS.connection_error = "This client has no decision screen for %s. Return to the menu with Escape." % kind
	if request.has_method("get_game"):
		update_game_state.emit(request.get_game())
	decision_requested.emit(kind, request)

func connect_to_server():
	GS.connection_error = ""
	GS.is_waiting = true
	var url = GS.get_game_URL()
	if url == null or str(url).is_empty():
		_fail("This game type has no configured match endpoint.")
		return ERR_INVALID_PARAMETER
	var error = _client.connect_to_url(url)
	_polling = error == OK
	if error != OK:
		_fail("Could not connect to the match: %s" % error_string(error))
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
		_fail("Match connection closed (%d): %s" % [_client.get_close_code(), _client.get_close_reason()])

func close():
	_polling = false
	_client.close(1001, "Leaving match")

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
		_fail("The match connection is not open.")
		return ERR_UNAVAILABLE
	var error = _client.send(data.to_bytes(), _write_mode)
	if error != OK:
		_fail("Could not send match action: %s" % error_string(error))
		return error
	GS.is_waiting = true
	GS.connection_error = ""
	return OK
