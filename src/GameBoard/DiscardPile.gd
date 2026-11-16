extends Control

func _on_gui_input(event):
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed or not GS.gameState:
		return
	var board = find_parent("GameBoard")
	if is_instance_valid(board) and bool(board.get("tutorial_mode")):
		board.call("notify_tutorial_action", "target_click", "player_discard" if name.contains("Player") else "opponent_discard")
		return
	GS.popup_discard_pile = true
	if name.contains("Player"):
		GS.ability_selection_popup = false
		GS.popup_message = "Player's Discard Pile"
		GS.popup_cards = GS.gameState.get_player().get_discardPile()
	elif name.contains("Opponent"):
		GS.ability_selection_popup = false
		GS.popup_message = "Opponent's Discard Pile"
		GS.popup_cards = GS.gameState.get_opponent().get_discardPile()
