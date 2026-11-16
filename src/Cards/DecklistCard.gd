extends Control

var card

func setup(card, count):
	if card:
		self.card = card
		CS.set_cost_texture(find_child("CostBG"), card.get_cost())
		find_child("Name").set_text(card.get_name())
		CS.set_stylebox_knowledge_color("normal", find_child("Name"), CS.to_knowledge_color(card.get_knowledgeCost()))
		find_child("Count").set_text(str(count)+"x")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			GS.decklist.erase(card)
			GS.decklist_changed = true
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if card:
				var parent = find_parent("DeckBuilder")
				if is_instance_valid(GS.bigger_popup):
					GS.close_bigger_popup()
				GS.bigger_popup = GS.CollectionCardScene.instantiate()
				GS.bigger_popup.setup(card)
				parent.add_child(GS.bigger_popup)
				GS.bigger_popup.z_index = z_index + 1
				GS.bigger_popup.set_scale(Vector2(2,2))
				GS.bigger_popup.set_position(Vector2(0,0))

		if event.is_released():
			if is_instance_valid(GS.bigger_popup):
				var parent = find_parent("DeckBuilder")
				GS.close_bigger_popup()
