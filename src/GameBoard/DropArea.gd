extends Control

func _can_drop_data(_at_position, data):
	if not data is Card or not is_instance_valid(data) or not data.card or GS.is_waiting:
		return false
	return (name.contains("PlayContainer") and data.card.get_canPlay()) or \
		(name.contains("PlayerDeck") and data.card.get_canStudy())

func _drop_data(at_position, data):
	if not _can_drop_data(at_position, data):
		return
	if data.card:
		var board = find_parent("GameBoard")
		if is_instance_valid(board) and bool(board.get("tutorial_mode")):
			GS.clear_drag()
			if name.contains("PlayContainer"):
				GS.gameSocket.play_card(data.card.get_id())
			elif name.contains("PlayerDeck"):
				GS.gameSocket.study_card(data.card.get_id())
			return
		print("Dropped to " + get_name() + ": ", data.card.get_id())
		#data.set_visible(true)
		GS.clear_drag()
		if name.contains("PlayContainer") and data.card.get_canPlay():
			SS.process_selections(data.card.get_playTargets(), data.card, GS.gameSocket.play_card, SS.selection_type.PLAY)
		elif name.contains("PlayerDeck") and data.card.get_canStudy():
			if data.card.get_knowledgeCost().size() == 0:
				SS.selected_single.append(GS.Types.Knowledge.NONE)
				GS.gameSocket.study_card(data.card.get_id())
			elif data.card.get_knowledgeCost().size() == 1:
				SS.selected_single.append(data.card.get_knowledgeCost()[0].get_knowledge())
				GS.gameSocket.study_card(data.card.get_id())
			else:
				SS.clear_selection_data()
				SS.selecting_card = data.card
				SS.selecting_for = SS.selection_type.KNOWLEDGE
				SS.selection_message = "Select a knowledge to gain from your information panel."
				for k in data.card.get_knowledgeCost():
					SS.selection_targets.append(k.get_knowledge())

		#else:
			#data.set_visible(true)

func _process(delta):
	if GS.gameState:
		var border = get_theme_stylebox("panel").duplicate()
		if border is StyleBoxFlat:
			border.set_border_width_all(2)
			border.shadow_size = 0
			border.shadow_color = Color.TRANSPARENT
		if name.contains("PlayerDeck"):
			var can_study = false
			var player = GS.gameState.get_player()
			if player:
				for card in player.get_hand():
					if card.get_canStudy():
						can_study = true
						break
			if GS.dragged_card and GS.dragged_card.card and GS.dragged_card.card.get_canStudy():
				can_study = true
			if can_study:
				border.set_border_color(Color.GREEN_YELLOW)
			else:
				border.set_border_color(Color.TRANSPARENT)

		elif name.contains("PlayContainer"):
			if GS.dragged_card and GS.dragged_card.card.get_canPlay():
				border.set_border_color(Color.GREEN_YELLOW)
			else:
				border.set_border_color(Color.TRANSPARENT)

		add_theme_stylebox_override("panel", border)
