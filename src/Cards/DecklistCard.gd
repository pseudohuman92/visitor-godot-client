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
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and card:
				GS.show_card_preview(card, true)
			elif not event.pressed:
				GS.close_bigger_popup()
