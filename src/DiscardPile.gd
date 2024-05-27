extends Control

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if name.contains("Player"):
				GS.ability_selection_popup = false
				GS.popup_message = "Player's Discard Pile"
				GS.popup_cards = GS.gameState.get_player().get_discardPile()
			elif name.contains("Opponent"):
				GS.ability_selection_popup = false
				GS.popup_message = "Opponent's Discard Pile"
				GS.popup_cards = GS.gameState.get_opponent().get_discardPile()
