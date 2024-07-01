extends PanelContainer

var hover = false

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if SS.is_selecting():
				var id
				if get_parent().name.contains("Player"):
					id = GS.gameState.get_player().get_id()
				else:
					id = GS.gameState.get_opponent().get_id()
				if SS.selection_targets.has(id):
					if SS.selected_single.has(id):
						SS.selected_single.erase(id)
					else:
						SS.selected_single.append(id)
						SS.check_smart_select()

func _process(_delta):
	if GS.gameState:
		var id
		if get_parent().name.contains("Player"):
			id = GS.gameState.get_player().get_id()
		else:
			id = GS.gameState.get_opponent().get_id()

		var border = get_theme_stylebox("panel").duplicate()

		if SS.is_selecting() and SS.selection_targets.has(id):
			if hover:
				border.set_border_color(Color.DARK_GOLDENROD)
			else:
				border.set_border_color(Color.GREEN_YELLOW)
		elif id == GS.gameState.get_activePlayer():
			border.set_border_color(Color.LIGHT_BLUE)
		else:
			border.set_border_color(Color.TRANSPARENT)

		add_theme_stylebox_override("panel", border)

func _on_mouse_entered():
	hover = true

func _on_mouse_exited():
	hover = false
