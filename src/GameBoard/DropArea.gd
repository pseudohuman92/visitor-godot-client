extends Control

func _can_drop_data(_at_position, data):
	if not data is Card or not is_instance_valid(data) or not data.card or GS.is_waiting:
		return false
	return name.contains("PlayContainer") and data.card.get_canPlay()

func _drop_data(at_position, data):
	if not _can_drop_data(at_position, data):
		return
	if data.card:
		var board = find_parent("GameBoard")
		if is_instance_valid(board) and bool(board.get("tutorial_mode")):
			GS.clear_drag()
			if name.contains("PlayContainer"):
				GS.gameSocket.play_card(data.card.get_id())
			return
		print("Dropped to " + get_name() + ": ", data.card.get_id())
		#data.set_visible(true)
		GS.clear_drag()
		if name.contains("PlayContainer") and data.card.get_canPlay():
			SS.process_selections(data.card.get_playTargets(), data.card, GS.gameSocket.play_card, SS.selection_type.PLAY)

		#else:
			#data.set_visible(true)

func _process(_delta):
	if GS.gameState and name.contains("PlayContainer"):
		var border = get_theme_stylebox("panel").duplicate()
		if border is StyleBoxFlat:
			border.set_border_width_all(2)
			border.shadow_size = 0
			border.shadow_color = Color.TRANSPARENT
		if GS.dragged_card and GS.dragged_card.card.get_canPlay():
			border.set_border_color(Color.GREEN_YELLOW)
		else:
			border.set_border_color(Color.TRANSPARENT)

		add_theme_stylebox_override("panel", border)
