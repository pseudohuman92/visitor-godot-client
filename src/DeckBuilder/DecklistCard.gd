extends Control

var card

func setup(card, count):
	if card:
		self.card = card
		if card.get_cost():
			find_child("Cost").set_text(card.get_cost())
		else:
			find_child("Cost").set_visible(false)
		find_child("Name").set_text(card.get_name())
		CS.change_stylebox_override("normal", find_child("Name"), func(b): b.set_modulate(CS.to_knowledge_color(card.get_knowledgeCost())))
		find_child("Count").set_text(str(count)+"x")

func _on_mouse_entered():
		var border = find_child("InternalContainer").get_theme_stylebox("panel").duplicate()
		border.set_border_color(Color.GOLDENROD)
		find_child("InternalContainer").add_theme_stylebox_override("panel", border)

func _on_mouse_exited():
		var border = find_child("InternalContainer").get_theme_stylebox("panel").duplicate()
		border.set_border_color(Color.WHITE_SMOKE)
		find_child("InternalContainer").add_theme_stylebox_override("panel", border)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			GS.decklist.erase(card)
			GS.decklist_changed = true
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if card:
				var parent = find_parent("DeckBuilder")
				if GS.bigger_popup:
					parent.remove_child(GS.bigger_popup)
				GS.bigger_popup = GS.CollectionCardScene.instantiate()
				GS.bigger_popup.setup(card)
				parent.add_child(GS.bigger_popup)
				GS.bigger_popup.z_index = z_index + 1
				GS.bigger_popup.set_scale(Vector2(2,2))
				GS.bigger_popup.set_position(Vector2(0,0))

		if event.is_released():
			if GS.bigger_popup:
				var parent = find_parent("DeckBuilder")
				parent.remove_child(GS.bigger_popup)


