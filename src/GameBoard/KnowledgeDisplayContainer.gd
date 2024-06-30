extends PanelContainer

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if find_parent("PlayerDisplay") and SS.selecting_for == SS.selection_type.KNOWLEDGE and \
			SS.selection_targets.has(CS.to_knowledge_type(name.substr(0,1))):
				SS.selected.append(CS.to_knowledge_type(name.substr(0,1)))
				SS.selection_targets = []
				SS.selecting_for = SS.selection_type.NONE
				GS.gameSocket.study_card(SS.selecting_card.get_id())
