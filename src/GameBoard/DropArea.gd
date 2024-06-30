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
			SS.process_selections(data.card.get_playTargets(), data.card, GS.gameSocket.play_card, SS.selection_type.PLAY)
		elif name.contains("PlayerDeck") and data.card.get_canStudy():
			if data.card.get_knowledgeCost().size() < 2:
				GS.gameSocket.study_card(data.card.get_id())
			else:
				GS.clear_selection_data()
				SS.selecting_card = data.card
				SS.selecting_for = SS.selection_type.KNOWLEDGE
				for k in data.card.get_knowledgeCost():
					SS.selection_targets.append(k.get_knowledge())

		#else:
			#data.set_visible(true)

func _process(delta):
	if GS.gameState:
		var border = get_theme_stylebox("panel").duplicate()
		if name.contains("PlayerDeck"):
			if GS.dragged_card and GS.dragged_card.card.get_canStudy():
				border.set_border_color(Color.GREEN_YELLOW)
			else:
				border.set_border_color(Color.TRANSPARENT)

		elif name.contains("PlayContainer"):
			if GS.dragged_card and GS.dragged_card.card.get_canPlay():
				border.set_border_color(Color.GREEN_YELLOW)
			else:
				border.set_border_color(Color.TRANSPARENT)

		add_theme_stylebox_override("panel", border)
