extends PanelContainer

var hover = false
var _base_panel_style: StyleBox
var _last_visual_state = -1

func _ready():
	_base_panel_style = get_theme_stylebox("panel")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var board = find_parent("GameBoard")
			if is_instance_valid(board) and bool(board.get("tutorial_mode")) and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				board.call("notify_tutorial_action", "avatar_click", name)
				accept_event()
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

		var visual_state = 0
		if SS.is_selecting() and SS.selection_targets.has(id):
			if hover:
				visual_state = 2
			else:
				visual_state = 1
		elif id == GS.gameState.get_activePlayer():
			visual_state = 3
		if visual_state == _last_visual_state:
			return
		_last_visual_state = visual_state
		var highlight = Color.TRANSPARENT
		match visual_state:
			1: highlight = Color.GREEN_YELLOW
			2: highlight = Color.DARK_GOLDENROD
			3: highlight = Color.LIGHT_BLUE
		var border = _base_panel_style.duplicate() as StyleBox
		if border is StyleBoxFlat:
			(border as StyleBoxFlat).set_border_color(highlight)
		elif border is StyleBoxTexture and visual_state != 0:
			var source_tint = (_base_panel_style as StyleBoxTexture).modulate_color
			(border as StyleBoxTexture).modulate_color = source_tint.lerp(highlight, 0.78)

		add_theme_stylebox_override("panel", border)

func _on_mouse_entered():
	hover = true

func _on_mouse_exited():
	hover = false
