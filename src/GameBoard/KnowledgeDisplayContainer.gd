extends PanelContainer

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var board = find_parent("GameBoard")
			if is_instance_valid(board) and bool(board.get("tutorial_mode")) and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				board.call("notify_tutorial_action", "knowledge_select", CS.to_knowledge_type(name.substr(0,1)))
				accept_event()
				return
			if find_parent("PlayerDisplay") and SS.selecting_for == SS.selection_type.KNOWLEDGE and \
			SS.selection_targets.has(CS.to_knowledge_type(name.substr(0,1))):
				SS.selected_single.append(CS.to_knowledge_type(name.substr(0,1)))
				SS.selection_targets = []
				SS.selecting_for = SS.selection_type.NONE
				GS.gameSocket.study_card(SS.selecting_card.get_id())
