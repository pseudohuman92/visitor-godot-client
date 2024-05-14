extends Control

func _can_drop_data(at_position, data):
	return true
	
func _drop_data(at_position, data):
	if data.card:
		print("Dropped to " + get_name() + ": ", data.card.get_id())
		#data.set_visible(true)
		GlobalState.is_dragging = false
		if name == "PlayArea" and data.card.get_canPlay():
			GlobalState.gameSocket.play_card(data.card.get_id())
		elif name == "PlayerDeck" and data.card.get_canStudy():
			GlobalState.gameSocket.study_card(data.card.get_id())

