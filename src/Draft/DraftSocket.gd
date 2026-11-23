extends Node

class_name DraftSocket

signal pick_requested(draft_state, candidates, message)
signal draft_completed(draft_state)
signal connection_failed(reason)

var _client := WebSocketPeer.new()
var _polling := false
var _closing := false
var _completed := false
var _awaiting_pick := false
var _candidate_ids: Array[String] = []
var _last_offer := ""

func connect_to_server() -> Error:
	_closing = false
	var url = GS.get_game_URL()
	if url == null or str(url).is_empty():
		_fail("This draft has no configured endpoint.")
		return ERR_INVALID_PARAMETER
	var error := _client.connect_to_url(url)
	_polling = error == OK
	if error != OK:
		_fail("Could not connect to the draft: %s" % error_string(error))
	return error

func pick_card(card_id: String) -> Error:
	if _completed or _awaiting_pick or not _candidate_ids.has(card_id):
		return ERR_INVALID_PARAMETER
	if _client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_fail("The draft connection is not open.")
		return ERR_UNAVAILABLE
	var message = GS.ClientGameMessages.ClientGameMessage.new()
	message.new_pickCardResponse().set_pickedCard(card_id)
	var error := _client.send(message.to_bytes(), WebSocketPeer.WRITE_MODE_BINARY)
	if error != OK:
		_fail("Could not send draft pick: %s" % error_string(error))
		return error
	_awaiting_pick = true
	return OK

func _process(_delta: float) -> void:
	if not _polling:
		return
	_client.poll()
	var state := _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN or state == WebSocketPeer.STATE_CLOSED:
		_receive_packets()
	if state == WebSocketPeer.STATE_CLOSED:
		_polling = false
		if not _closing and not _completed:
			_fail("Draft connection closed (%d): %s" % [_client.get_close_code(), _client.get_close_reason()])

func _receive_packets() -> void:
	while _client.get_available_packet_count() > 0:
		var message = GS.ServerGameMessages.ServerGameMessage.new()
		if message.from_bytes(_client.get_packet()) != GS.ServerGameMessages.PB_ERR.NO_ERRORS:
			_fail("Could not read a draft message.")
			continue
		if not message.has_pickCard():
			_fail("Received an unexpected draft message.")
			continue
		var offer = message.get_pickCard()
		var draft_state = offer.get_draft()
		if draft_state.get_completed():
			_completed = true
			_awaiting_pick = false
			_candidate_ids.clear()
			draft_completed.emit(draft_state)
			continue
		var ids: Array[String] = []
		for card in offer.get_candidates():
			ids.append(card.get_id())
		var signature := "%d:%s" % [draft_state.get_decklist().size(), ",".join(ids)]
		if signature == _last_offer and _awaiting_pick:
			continue
		_last_offer = signature
		_awaiting_pick = false
		_candidate_ids = ids
		pick_requested.emit(draft_state, offer.get_candidates(), offer.get_messageP())

func close() -> void:
	_closing = true
	_polling = false
	_client.close(1001, "Leaving draft")

func _exit_tree() -> void:
	close()

func _fail(reason: String) -> void:
	connection_failed.emit(reason)
