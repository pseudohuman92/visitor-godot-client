extends Control

func _can_drop_data(at_position, data):
	return true

func _drop_data(at_position, data):
	if data.card:
		print("Dropped to " + get_name() + ": ", data.card.get_id())
		#data.set_visible(true)
		GS.is_dragging = false
		GS.dragged_card = null
		if name.contains("PlayContainer") and data.card.get_canPlay():
			var target_options = data.card.get_playTargets()
			if target_options:
				GS.selection_info = target_options
				GS.targeting_card = data.card
				GS.targeting_type = GS.targeting_for.PLAY
				data.set_visible(true)
			else:
				GS.gameSocket.play_card(data.card.get_id())
		elif name.contains("PlayerDeck") and data.card.get_canStudy():
			if data.card.get_knowledgeCost().size() < 2:
				GS.gameSocket.study_card(data.card.get_id())
		else:
			data.set_visible(true)

func _process(delta):
	if GS.gameState:
		var border = get_theme_stylebox("panel").duplicate()
		if name.contains("PlayerDeck") and GS.dragged_card and GS.dragged_card.card.get_canStudy():
			border.set_border_color(Color.GREEN_YELLOW)
		elif name.contains("PlayerDeck"):
			border.set_border_color(Color.TRANSPARENT)
		elif name.contains("PlayContainer") and GS.dragged_card and GS.dragged_card.card.get_canPlay():
			border.set_border_color(Color.GREEN_YELLOW)
		elif name.contains("PlayContainer"):
			border.set_border_color(Color.TRANSPARENT)

		elif name.contains("PlayerDisplay") and GS.gameState.get_player().get_id() == GS.gameState.get_activePlayer():
			border.set_border_color(Color.YELLOW)
		elif name.contains("PlayerDisplay"):
			border.set_border_color(Color.TRANSPARENT)
		elif name.contains("OpponentDisplay") and GS.gameState.get_opponent().get_id() == GS.gameState.get_activePlayer():
			border.set_border_color(Color.YELLOW)
		elif name.contains("OpponentDisplay"):
			border.set_border_color(Color.TRANSPARENT)
		add_theme_stylebox_override("panel", border)
