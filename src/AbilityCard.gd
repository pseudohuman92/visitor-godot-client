extends PanelContainer

var card
var targets

func setup(card, targets):
		self.card = card
		self.targets = targets
		var image_box = find_child("CardImage").get_theme_stylebox("panel").duplicate()
		image_box.set_texture(GS.get_card_image(card.get_set(),card.get_name()))
		find_child("CardImage").add_theme_stylebox_override("panel", image_box)

		find_child("Ability").set_text_custom(targets.get_targetMessage(), card.get_name())
		set_name(targets.get_id())

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			GS.selection_info = targets
			GS.selected = []
			if targets.get_maxTargets() == 0:
				GS.gameSocket.activate_card(card.get_id())
			elif targets.get_minTargets() == targets.get_possibleTargets().size():
				GS.selected = targets.get_possibleTargets()
				GS.gameSocket.activate_card(card.get_id())
			else:
				GS.targeting_type = GS.targeting_for.ACTIVATE
				GS.targeting_card = card
			GS.popup_cards = []
			GS.popup_message = ""

