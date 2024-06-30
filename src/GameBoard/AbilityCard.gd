extends PanelContainer

var card
var targeting_ability

func setup(card, targeting_ability):
		self.card = card
		self.targeting_ability = targeting_ability
		var image_box = find_child("CardImage").get_theme_stylebox("panel").duplicate()
		var type
		if card.get_types()[0] == "Spell" and card.get_subtypes():
			type = card.get_subtypes()[0]
		else:
			type = card.get_types()[0]
		var image = CS.get_card_image(card.get_set(),card.get_name())
		if !image:
			image = CS.get_placeholder_image(type)
		image_box.set_texture(image)
		find_child("CardImage").add_theme_stylebox_override("panel", image_box)
		find_child("Ability").set_text_custom(targeting_ability.get_text(), card.get_name())
		set_name(targeting_ability.get_id())

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			GS.popup_cards = []
			GS.popup_message = ""
			SS.process_selections(targeting_ability.get_targets(), card, GS.gameSocket.activate_card, SS.selection_type.ACTIVATE, targeting_ability.get_id())

func _on_mouse_entered():
	var border = get_theme_stylebox("panel").duplicate()
	border.set_border_color(Color.DARK_GOLDENROD)
	add_theme_stylebox_override("panel", border)


func _on_mouse_exited():
	var border = get_theme_stylebox("panel").duplicate()
	border.set_border_color(Color.WHITE_SMOKE)
	add_theme_stylebox_override("panel", border)
