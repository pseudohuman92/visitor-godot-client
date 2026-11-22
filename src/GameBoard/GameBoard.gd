extends Node2D

signal tutorial_action(action: String, payload: Variant)

var tutorial_mode := false
var tutorial_submit_enabled := false
var arrows = []
var block_arrows = []
var _state_revision = 0
var _zone_bytes = {}
var _display_values = {}
var _board_hud_root: Control
var _opponent_hud: Control
var _player_hud: Control
var _opponent_active_frame: Panel
var _player_active_frame: Panel
var _phase_indicator: PanelContainer
var _phase_step_chips: Array[PanelContainer] = []
var _phase_step_labels: Array[Label] = []
var _phase_steps: Array = []
var _opponent_front: Control
var _opponent_deck_area: Control
var _opponent_hand: Control
var _opponent_hand_mask: Control
var _player_front: Control
var _player_deck_area: Control
var _player_hand: Control
var _player_time_ms := 0
var _opponent_time_ms := 0
var _clock_active_player_id := ""
var _clock_snapshot_msec := 0
var _clock_initialized := false
var _clock_running := true
@export_range(0.0, 2.0, 0.01) var card_move_duration := 0.28
var _card_movement
const CARD_ZONES = ["PlayerHand", "PlayerUnitArea", "PlayerAssetArea", "PlayerDiscard", "OpponentUnitArea", "OpponentAssetArea", "OpponentDiscard", "Stack"]

func _find_board_node(node_name: String):
	return find_child(node_name, true, false)

func _ready():
	if OS.get_cmdline_user_args().has("--ai-vs-ai-demo"):
		GS.queue_type = GS.Types.GameType.AI_VS_AI
		GS.game_decklist = GS.ai_vs_ai_demo_decklist.duplicate()
	GS.close_connections()
	_apply_reference_board_composition()
	SFX.reset_match()
	if tutorial_mode:
		_prepare_tutorial_client()
		return
	var socket = Websocket.new()
	socket.connect("initialize_game_state", initialize_game_state)
	socket.connect("got_login_response", func(): socket.joinQueue(GS.queue_type))
	GS.socket = socket
	socket.connect_to_server()

func _apply_reference_board_composition():
	var main_container = _find_board_node("MainContainer")
	var old_layout = _find_board_node("HBoxContainer")
	var old_display_area = _find_board_node("DisplayArea")
	var old_opponent_display = _find_board_node("OpponentDisplay")
	var old_player_display = _find_board_node("PlayerDisplay")
	var play_area = _find_board_node("PlayArea")
	var stack_container = _find_board_node("StackContainer")
	var opponent_hand_zone = _find_board_node("OpponentHand")
	_player_hand = _find_board_node("ScrollContainer4")
	if not main_container or not old_layout or not old_display_area or not old_opponent_display \
			or not old_player_display or not play_area or not stack_container or not opponent_hand_zone or not _player_hand:
		return

	_opponent_hand = opponent_hand_zone.get_parent()
	_opponent_front = old_opponent_display.find_child("OpponentDisplayFront", true, false)
	_opponent_deck_area = old_opponent_display.find_child("OpponentDeckArea", true, false)
	_player_front = old_player_display.find_child("PlayerDisplayFront", true, false)
	_player_deck_area = old_player_display.find_child("PlayerDeckArea", true, false)
	if not _opponent_front or not _opponent_deck_area or not _player_front or not _player_deck_area:
		return

	# Replace the left-side HUD column with top and bottom rows around the board.
	var board_layout = VBoxContainer.new()
	board_layout.name = "BoardLayout"
	board_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_layout.add_theme_constant_override("separation", 0)
	main_container.remove_child(old_layout)
	main_container.add_child(board_layout)

	var opponent_row = Control.new()
	opponent_row.name = "OpponentHudRow"
	opponent_row.custom_minimum_size = Vector2(0, 260)
	board_layout.add_child(opponent_row)
	var battle_row = HBoxContainer.new()
	battle_row.name = "BattleRow"
	battle_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_row.add_theme_constant_override("separation", 8)
	board_layout.add_child(battle_row)
	var player_row = Control.new()
	player_row.name = "PlayerHudRow"
	player_row.custom_minimum_size = Vector2(0, 300)
	board_layout.add_child(player_row)

	old_layout.remove_child(play_area)
	old_layout.remove_child(stack_container)
	battle_row.add_child(play_area)
	battle_row.add_child(stack_container)
	play_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack_container.custom_minimum_size.x = 180
	stack_container.size_flags_horizontal = Control.SIZE_FILL
	stack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	old_layout.queue_free()

	var hud_layer = CanvasLayer.new()
	hud_layer.name = "BoardHudLayer"
	hud_layer.layer = 2
	add_child(hud_layer)
	_board_hud_root = Control.new()
	_board_hud_root.name = "BoardHudRoot"
	_board_hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_hud_root.visible = false
	hud_layer.add_child(_board_hud_root)

	_opponent_hud = Control.new()
	_opponent_hud.name = "OpponentDisplay"
	_opponent_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_opponent_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_hud_root.add_child(_opponent_hud)
	_opponent_hand_mask = Control.new()
	_opponent_hand_mask.name = "OpponentHandMask"
	_opponent_hand_mask.clip_contents = true
	_opponent_hand_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opponent_hud.add_child(_opponent_hand_mask)
	_player_hud = Control.new()
	_player_hud.name = "PlayerDisplay"
	_player_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_hud_root.add_child(_player_hud)
	_opponent_front.reparent(_opponent_hud)
	_opponent_deck_area.reparent(_opponent_hud)
	_opponent_hand.reparent(_opponent_hand_mask)
	_player_front.reparent(_player_hud)
	_player_deck_area.reparent(_player_hud)
	_player_hand.reparent(_player_hud)
	old_display_area.queue_free()
	_prepare_information_panels()
	_setup_deck_count_hover()
	_create_active_player_frames()
	_create_phase_indicator()
	var divider = _find_board_node("PlayAreaSeparator")
	if divider:
		divider.hide()
	var old_phase_label = _find_board_node("Phase")
	if old_phase_label:
		old_phase_label.hide()

	get_viewport().size_changed.connect(_layout_board_hud)
	_layout_board_hud()

func _prepare_information_panels():
	for prefix in ["Opponent", "Player"]:
		var energy_display = _find_board_node(prefix + "EnergyDisplay")
		if not energy_display:
			continue
		var avatar = energy_display.find_child("AvatarContainer", true, false)
		if avatar:
			avatar.hide()
		var clock = _find_board_node(prefix + "Clock")
		var health_row = energy_display.find_child("HealthRow", true, false)
		if clock and health_row:
			clock.reparent(health_row, false)
			clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			clock.custom_minimum_size = Vector2(0, 28)
			clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var energy_row = energy_display.find_child("EnergyRow", true, false)
		var knowledge = _find_board_node(prefix + "KnowledgeDisplay")
		if energy_row and knowledge:
			knowledge.reparent(energy_row, false)
			knowledge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			energy_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		if prefix == "Opponent" and energy_row:
			energy_display.move_child(energy_row, 0)

func _setup_deck_count_hover():
	for prefix in ["Opponent", "Player"]:
		var deck = _find_board_node(prefix + "Deck") as Control
		var count = _find_board_node(prefix + "DeckSize") as Control
		if not deck or not count:
			continue
		count.visible = false
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck.mouse_entered.connect(_set_deck_count_visibility.bind(count, true))
		deck.mouse_exited.connect(_set_deck_count_visibility.bind(count, false))

func _set_deck_count_visibility(count: Control, visible: bool):
	if is_instance_valid(count):
		count.visible = visible

func _create_active_player_frames():
	if not is_instance_valid(_board_hud_root):
		return
	_opponent_active_frame = _new_active_player_frame("OpponentActiveFrame")
	_player_active_frame = _new_active_player_frame("PlayerActiveFrame")
	_board_hud_root.add_child(_opponent_active_frame)
	_board_hud_root.add_child(_player_active_frame)

func _new_active_player_frame(frame_name: String) -> Panel:
	var frame = Panel.new()
	frame.name = frame_name
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = false
	frame.z_index = 15
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = Color("#67DDF5")
	style.set_border_width_all(4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	frame.add_theme_stylebox_override("panel", style)
	return frame

func _update_active_player_indicator(state):
	if not state or not is_instance_valid(_player_active_frame) or not is_instance_valid(_opponent_active_frame):
		return
	var active_player_id = state.get_activePlayer()
	if active_player_id.is_empty():
		active_player_id = state.get_turnPlayer()
	var player = state.get_player()
	var opponent = state.get_opponent()
	var player_is_active = player and player.get_id() == active_player_id
	var opponent_is_active = opponent and opponent.get_id() == active_player_id
	if not player_is_active and not opponent_is_active:
		player_is_active = player and player.get_id() == GS.playerId
		if not player_is_active:
			opponent_is_active = opponent != null
	_player_active_frame.visible = player_is_active
	_opponent_active_frame.visible = opponent_is_active

func _create_phase_indicator():
	if not is_instance_valid(_board_hud_root) or is_instance_valid(_phase_indicator):
		return
	_phase_steps = [
		{"phase": GS.Types.Phase.REDRAW, "label": "REDRAW", "name": "Redraw"},
		{"phase": GS.Types.Phase.BEGIN, "label": "BEGIN", "name": "Begin"},
		{"phase": GS.Types.Phase.MAIN_BEFORE, "label": "MAIN 1", "name": "Main Before"},
		{"phase": GS.Types.Phase.ATTACK, "label": "ATTACK", "name": "Attack"},
		{"phase": GS.Types.Phase.ATTACK_PLAY, "label": "ATK PLAY", "name": "Attack Play"},
		{"phase": GS.Types.Phase.BLOCK, "label": "BLOCK", "name": "Block"},
		{"phase": GS.Types.Phase.BLOCK_PLAY, "label": "BLK PLAY", "name": "Block Play"},
		{"phase": GS.Types.Phase.MAIN_AFTER, "label": "MAIN 2", "name": "Main After"},
		{"phase": GS.Types.Phase.END, "label": "END", "name": "End"},
	]
	_phase_indicator = PanelContainer.new()
	_phase_indicator.name = "GamePhaseIndicator"
	_phase_indicator.custom_minimum_size = Vector2(0, 80)
	_phase_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_indicator.z_index = 10
	var shell = StyleBoxFlat.new()
	shell.bg_color = Color("#111416")
	shell.border_color = Color("#72685B")
	shell.set_border_width_all(1)
	shell.corner_radius_top_left = 5
	shell.corner_radius_top_right = 5
	shell.corner_radius_bottom_left = 5
	shell.corner_radius_bottom_right = 5
	shell.shadow_color = Color(0, 0, 0, 0.65)
	shell.shadow_size = 8
	shell.shadow_offset = Vector2(0, 3)
	_phase_indicator.add_theme_stylebox_override("panel", shell)
	_board_hud_root.add_child(_phase_indicator)
	var margins = MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 6)
	margins.add_theme_constant_override("margin_top", 4)
	margins.add_theme_constant_override("margin_right", 6)
	margins.add_theme_constant_override("margin_bottom", 4)
	_phase_indicator.add_child(margins)
	var rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 2)
	margins.add_child(rows)
	var row: HBoxContainer
	for index in range(_phase_steps.size()):
		if index % 3 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 2)
			row.size_flags_vertical = Control.SIZE_EXPAND_FILL
			rows.add_child(row)
		var step = _phase_steps[index]
		var chip = PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 20)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.tooltip_text = step["name"]
		var label = Label.new()
		label.text = step["label"]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-SemiBold-Tracked.tres"))
		label.add_theme_font_size_override("font_size", 14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(label)
		row.add_child(chip)
		_phase_step_chips.append(chip)
		_phase_step_labels.append(label)

func _update_phase_indicator(state):
	if not is_instance_valid(_phase_indicator) or state == null:
		return
	var current_index = -1
	for index in range(_phase_steps.size()):
		if _phase_steps[index]["phase"] == state.get_phase():
			current_index = index
			break
	for index in range(_phase_step_chips.size()):
		var chip_style = StyleBoxFlat.new()
		chip_style.set_border_width_all(1)
		chip_style.corner_radius_top_left = 3
		chip_style.corner_radius_top_right = 3
		chip_style.corner_radius_bottom_left = 3
		chip_style.corner_radius_bottom_right = 3
		var label_color = Color("#8D8880")
		if index == current_index:
			chip_style.bg_color = Color("#18333B")
			chip_style.border_color = Color("#67DDF5")
			chip_style.set_border_width_all(2)
			chip_style.shadow_color = Color(0.18, 0.78, 0.94, 0.65)
			chip_style.shadow_size = 6
			label_color = Color("#F3F1E9")
		elif index < current_index:
			chip_style.bg_color = Color("#28231E")
			chip_style.border_color = Color("#796448")
			label_color = Color("#D1C0A3")
		else:
			chip_style.bg_color = Color("#17191A")
			chip_style.border_color = Color("#45433F")
		_phase_step_chips[index].add_theme_stylebox_override("panel", chip_style)
		_phase_step_labels[index].add_theme_color_override("font_color", label_color)

func _prepare_tutorial_client():
	GS.gameType = GS.Types.GameType.BO1_CONSTRUCTED
	GS.playerId = "tutorial-player"
	GS.is_waiting = false
	GS.is_spectating_ai_match = false
	GS.connection_error = ""
	GS.pending_decision = ""
	GS.clear_popup()
	var socket = preload("res://src/Tutorial/TutorialGameSocket.gd").new()
	socket.name = "TutorialGameSocket"
	socket.action_requested.connect(_on_tutorial_socket_action)
	add_child(socket)
	GS.gameSocket = socket
	_create_tutorial_submit_button()
	_find_board_node("LoadingPanel").hide()
	_find_board_node("AiVsAiResult").hide()
	_find_board_node("OptionsOverlay").hide()
	_install_tutorial_input_targets()

func _install_tutorial_input_targets():
	var targets = {
		"OpponentDisplayFront": "opponent_info",
		"OpponentDeck": "opponent_deck",
		"OpponentUnitArea": "opponent_zone",
		"PlayerDisplayFront": "player_info",
		"PlayerDeckBorder": "player_deck",
		"PlayerUnitArea": "player_zone"
	}
	for node_name in targets:
		var control = _find_board_node(node_name)
		if not control is Control:
			continue
		if node_name in ["OpponentUnitArea", "PlayerUnitArea", "PlayerDeckBorder", "OpponentDeck"]:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		control.gui_input.connect(_on_tutorial_target_input.bind(targets[node_name]))
	for deck_node_name in ["PlayerDeck", "PlayerDeckSize", "OpponentDeckSize"]:
		var deck_child = _find_board_node(deck_node_name)
		if deck_child is Control:
			deck_child.mouse_filter = Control.MOUSE_FILTER_PASS
	var submit = _find_board_node("TutorialSubmit")
	if submit:
		submit.pressed.connect(_on_tutorial_submit_pressed)

func _on_tutorial_target_input(event, target_id: String):
	if tutorial_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		notify_tutorial_action("target_click", target_id)

func _on_tutorial_socket_action(action: String, payload: Variant):
	notify_tutorial_action(action, payload)

func notify_tutorial_action(action: String, payload: Variant = null):
	if tutorial_mode:
		tutorial_action.emit(action, payload)

func _create_tutorial_submit_button():
	var action_layer = CanvasLayer.new()
	action_layer.name = "TutorialActionLayer"
	action_layer.layer = 120
	add_child(action_layer)
	var submit = Button.new()
	submit.name = "TutorialSubmit"
	submit.custom_minimum_size = Vector2(240, 56)
	submit.size = submit.custom_minimum_size
	submit.theme = preload("res://src/Themes/MainTheme.tres")
	submit.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-SemiBold-Tracked.tres"))
	submit.add_theme_font_size_override("font_size", 22)
	submit.add_theme_stylebox_override("normal", preload("res://assets/ui/styles/button_primary_default.tres"))
	submit.add_theme_stylebox_override("hover", preload("res://assets/ui/styles/button_primary_hover.tres"))
	submit.add_theme_stylebox_override("pressed", preload("res://assets/ui/styles/button_primary_pressed.tres"))
	submit.add_theme_stylebox_override("disabled", preload("res://assets/ui/styles/button_primary_disabled.tres"))
	submit.text = "SUBMIT"
	submit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	submit.visible = false
	action_layer.add_child(submit)
	_layout_tutorial_submit_button()
	get_viewport().size_changed.connect(_layout_tutorial_submit_button)

func _layout_tutorial_submit_button():
	var submit = _find_board_node("TutorialSubmit")
	if not submit:
		return
	submit.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	submit.position = Vector2(maxf(12.0, get_viewport_rect().size.x - 500.0), get_viewport_rect().size.y - 260.0)

func _on_tutorial_submit_pressed():
	if not tutorial_mode or not GS.gameState or not GS.gameSocket:
		return
	match GS.gameState.get_phase():
		GS.Types.Phase.ATTACK:
			GS.gameSocket.select_attackers()
		GS.Types.Phase.BLOCK:
			GS.gameSocket.select_blockers()

func set_tutorial_submit_enabled(enabled: bool):
	tutorial_submit_enabled = enabled
	var submit = _find_board_node("TutorialSubmit")
	if submit:
		submit.visible = enabled
		if enabled and GS.gameState:
			submit.text = "DECLARE ATTACK" if GS.gameState.get_phase() == GS.Types.Phase.ATTACK else "CONFIRM BLOCKS"
		submit.disabled = (GS.gameState.get_phase() == GS.Types.Phase.ATTACK \
			and SS.selected_single.is_empty()) or (GS.gameState.get_phase() == GS.Types.Phase.BLOCK \
			and SS.selected.is_empty())

func _layout_board_hud():
	if not is_instance_valid(_board_hud_root):
		return
	var viewport_size = get_viewport_rect().size
	var front_width = min(430.0, viewport_size.x * 0.42)
	var front_height = 160.0
	var front_scale = 0.5
	var deck_scale = 0.4
	var deck_size = Vector2(400, 280)
	var deck_width = deck_size.x * deck_scale
	var deck_height = deck_size.y * deck_scale
	var deck_x = viewport_size.x - deck_width - 32
	var front_x = deck_x + (deck_width - front_width * front_scale) * 0.5
	var opponent_deck_y = 4.0
	var opponent_info_y = opponent_deck_y + deck_height + 8
	var player_deck_y = viewport_size.y - deck_height - 4
	var player_info_y = player_deck_y - front_height * front_scale - 8
	_place_board_hud_control(_opponent_front,
		Vector2(front_x, opponent_info_y), Vector2(front_width, front_height), front_scale)
	_place_board_hud_control(_player_front,
		Vector2(front_x, player_info_y), Vector2(front_width, front_height), front_scale)
	var info_frame_size = Vector2(front_width, front_height) * front_scale
	_place_board_hud_control(_opponent_active_frame,
		Vector2(front_x, opponent_info_y), info_frame_size)
	_place_board_hud_control(_player_active_frame,
		Vector2(front_x, player_info_y), info_frame_size)
	if is_instance_valid(_phase_indicator):
		_place_board_hud_control(_phase_indicator,
			Vector2(front_x, maxf(8.0, player_info_y - info_frame_size.y - 8.0)),
			info_frame_size)
	var opponent_hand_width = viewport_size.x * 0.76
	var opponent_card_height = viewport_size.y * O.card_height
	var opponent_visible_height = opponent_card_height * 0.5
	_place_board_hud_control(_opponent_hand_mask,
		Vector2((viewport_size.x - opponent_hand_width) * 0.5, 0),
		Vector2(opponent_hand_width, opponent_visible_height))
	_place_board_hud_control(_opponent_hand, Vector2(0, -opponent_visible_height),
		Vector2(opponent_hand_width, opponent_card_height))
	_place_board_hud_control(_opponent_deck_area,
		Vector2(deck_x, opponent_deck_y), deck_size, deck_scale)
	_place_board_hud_control(_player_deck_area,
		Vector2(deck_x, player_deck_y), deck_size, deck_scale)
	var hand_width = viewport_size.x * 0.76
	var hand_height = viewport_size.y * O.card_height * 0.5
	_place_board_hud_control(_player_hand,
		Vector2((viewport_size.x - hand_width) * 0.5, viewport_size.y - hand_height),
		Vector2(hand_width, hand_height))

func _place_board_hud_control(control: Control, position: Vector2, size: Vector2,
			control_scale: float = 1.0):
	if not is_instance_valid(control):
		return
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.size = size
	control.scale = Vector2.ONE * control_scale

func initialize_game_state(new_state):
	GS.gameState = new_state
	GS.gameId = new_state.get_id()
	GS.playerId = new_state.get_player().get_id()

	_find_board_node("PlayerEnergyDisplay").find_child("AvatarContainer", true, false).set_name(new_state.get_player().get_id())
	_find_board_node("OpponentEnergyDisplay").find_child("AvatarContainer", true, false).set_name(new_state.get_opponent().get_id())
	if not tutorial_mode:
		initialize_game_socket()
	else:
		_find_board_node("LoadingPanel").hide()
		_find_board_node("AiVsAiResult").hide()
	update_game_state(new_state)
	if is_instance_valid(_board_hud_root):
		_board_hud_root.visible = true

func initialize_game_socket():
	var gameSocket = GameSocket.new()
	gameSocket.connect("update_game_state", update_game_state)
	gameSocket.connect("game_ended", show_game_result)
	GS.gameSocket = gameSocket
	gameSocket.connect_to_server()
	_find_board_node("LoadingPanel").set_visible(false)
	_find_board_node("AiVsAiResult").set_visible(false)

func show_game_result(won):
	_clock_running = false
	_update_game_clocks()
	if not GS.is_spectating_ai_match:
		return
	var state = GS.gameState
	if state == null:
		return
	var winner = state.get_player().get_username() if won else state.get_opponent().get_username()
	_find_board_node("AiVsAiResultText").text = "AI VS AI MATCH COMPLETE\n%s WINS\nPress Escape for options." % winner.to_upper()
	_find_board_node("AiVsAiResult").set_visible(true)

func update_game_state(new_state):
	SFX.observe(new_state)
	# Capture before reconciliation detaches obsolete source views. Initial deal
	# has no previous visible positions and intentionally does not animate.
	var origins = _capture_card_origins() if not _zone_bytes.is_empty() else {}
	GS.gameState = new_state
	_update_phase_indicator(new_state)
	_update_active_player_indicator(new_state)
	_snapshot_game_clocks(new_state)
	_state_revision += 1
	if new_state.get_activePlayer() != GS.playerId:
		GS.is_waiting = true

	_sync_player(new_state.get_player(), "Player")
	_sync_player(new_state.get_opponent(), "Opponent")
	_sync_zone("Stack", new_state.get_stack())
	_animate_zone_changes(origins)

	_sync_local_block_selections()
	# Reconcile indicators without discarding unchanged hover/block arrows.
	_refresh_hover_arrows()
	if new_state.get_phase() == GS.Types.Phase.MAIN_AFTER:
		if not block_arrows.is_empty() or not GS.block_arrow_targets.is_empty():
			remove_target_arrows(true)
			GS.block_arrow_targets.clear()
	elif new_state.get_phase() == GS.Types.Phase.BLOCK_PLAY:
		populate_block_arrows(new_state)
	else:
		_sync_arrows(GS.block_arrow_targets.values(), true)

	if O.smart_pass and not tutorial_mode:
		check_smart_pass_deferred(new_state, _state_revision)

func _capture_card_origins():
	var origins = {}
	for zone_name in CARD_ZONES:
		for view in _find_board_node(zone_name).get_children():
			var data = view.find_child("InternalContainer", true, false).card
			if data and not data.get_id().is_empty():
				var rect = _card_movement.current_rect(data.get_id(), view) if is_instance_valid(_card_movement) else _screen_card_rect(view)
				origins[data.get_id()] = {"zone": zone_name, "rect": rect}
	return origins

func _screen_card_rect(view):
	var transform = view.get_global_transform_with_canvas()
	var offset = Vector2.ZERO
	var internal = view.find_child("InternalContainer", true, false)
	if internal != null and internal.has_method("get_hover_offset"):
		offset = internal.get_hover_offset()
	return Rect2(transform * offset, view.size * transform.get_scale().abs())

func _animate_zone_changes(origins):
	var destinations = {}
	for zone_name in CARD_ZONES:
		for view in _find_board_node(zone_name).get_children():
			var data = view.find_child("InternalContainer", true, false).card
			if data and not data.get_id().is_empty():
				destinations[data.get_id()] = {"zone": zone_name, "view": view, "data": data}
	if is_instance_valid(_card_movement):
		for id in _card_movement.motions.keys():
			if not destinations.has(id):
				_card_movement.cancel(id)
	for id in destinations:
		var target = destinations[id]
		if not origins.has(id) or origins[id].zone == target.zone:
			if is_instance_valid(_card_movement):
				_card_movement.refresh(id, target.data, target.zone.ends_with("UnitArea") or target.zone.ends_with("AssetArea"))
			continue
		if not is_instance_valid(_card_movement):
			_card_movement = preload("res://src/GameBoard/CardMovement.gd").new()
			_card_movement.name = "CardMovement"
			add_child(_card_movement)
		_card_movement.duration = card_move_duration
		_card_movement.animate(id, target.view, target.data, target.zone.ends_with("UnitArea") or target.zone.ends_with("AssetArea"), origins[id].rect)

func _card_center(id, view):
	if is_instance_valid(_card_movement) and _card_movement.motions.has(id):
		var rect = _card_movement.current_rect(id, view)
		return get_global_transform_with_canvas().affine_inverse() * rect.get_center()
	var offset = Vector2.ZERO
	var internal = view.find_child("InternalContainer", true, false)
	if internal != null and internal.has_method("get_hover_offset"):
		offset = internal.get_hover_offset()
	var center = view.get_global_transform_with_canvas() * (view.size * 0.5 + offset)
	return get_global_transform_with_canvas().affine_inverse() * center

func _sync_player(player, prefix):
	_set_text_if_changed(prefix + "DeckSize", str(player.get_deckSize()) if player else "0")
	var energy = [player.get_energy(), player.get_maxEnergy(), player.get_health()] if player else []
	if _display_values.get(prefix + "Energy") != energy:
		_find_board_node(prefix + "EnergyDisplay").update_player(player)
		_display_values[prefix + "Energy"] = energy
	var knowledge = []
	if player:
		for group in player.get_knowledgePool():
			knowledge.append([group.get_knowledge(), group.get_count()])
	if _display_values.get(prefix + "Knowledge") != knowledge:
		_find_board_node(prefix + "KnowledgeDisplay").update_pool(player.get_knowledgePool() if player else [])
		_display_values[prefix + "Knowledge"] = knowledge

	if prefix == "Opponent":
		var hand = []
		hand.resize(player.get_handSize() if player else 0)
		_sync_zone("OpponentHand", hand, false, false)
	else:
		_sync_zone("PlayerHand", player.get_hand() if player else [])
	var units = []
	var assets = []
	if player:
		for card in player.get_play():
			if card.get_types().has("Unit"):
				units.append(card)
			else:
				assets.append(card)
	_sync_zone(prefix + "UnitArea", units, true)
	_sync_zone(prefix + "AssetArea", assets, true)
	var discarded = player.get_discardPile() if player else []
	_sync_zone(prefix + "Discard", [discarded.back()] if discarded else [])

func _set_text_if_changed(node_name, value):
	if _display_values.get(node_name) != value:
		_find_board_node(node_name).text = value
		_display_values[node_name] = value

func _sync_zone(node_name, cards, square=false, setup=true):
	var values = []
	if setup:
		for card in cards:
			values.append(card.to_bytes())
	else:
		values.append(cards.size())
	if _zone_bytes.get(node_name) == values and _find_board_node(node_name).get_child_count() == cards.size():
		# Refresh data references without touching the scene tree or presentation.
		if setup:
			var zone = _find_board_node(node_name)
			var ordered = cards.duplicate()
			if node_name == "Stack":
				ordered.reverse()
			for i in range(ordered.size()):
				zone.get_child(i).find_child("InternalContainer", true, false).card = ordered[i]
		return
	var created = _find_board_node(node_name).sync_cards(cards, square, setup)
	_zone_bytes[node_name] = values
	connect_arrow_signals(node_name, created)

func connect_arrow_signals(node_name, cards=null):
	var views = _find_board_node(node_name).get_children() if cards == null else cards
	for view in views:
		var internal = view.find_child("InternalContainer", true, false)
		if not internal.draw_target_arrows.is_connected(draw_target_arrows):
			internal.draw_target_arrows.connect(draw_target_arrows)
		if not internal.remove_target_arrows.is_connected(remove_target_arrows):
			internal.remove_target_arrows.connect(remove_target_arrows)

func _sync_local_block_selections():
	# Reused card nodes must not retain flags from a completed selection cycle.
	for key in SS.selected.keys():
		var pair = SS.selected[key]
		if pair is Array and pair.size() == 2:
			if not is_instance_valid(pair[0]) or not is_instance_valid(pair[1]) or not pair[0].is_inside_tree() or not pair[1].is_inside_tree():
				SS.selected.erase(key)
				GS.block_arrow_targets.erase(key)
	for zone_name in ["PlayerUnitArea", "OpponentUnitArea"]:
		for view in _find_board_node(zone_name).get_children():
			var internal = view.find_child("InternalContainer", true, false)
			internal.blocking = false
			internal.blocked = false
	for pair in SS.selected.values():
		if pair is Array and pair.size() == 2:
			pair[0].blocking = true
			pair[1].blocked = true

func _refresh_hover_arrows():
	var targets = []
	for zone_name in ["PlayerHand", "PlayerUnitArea", "PlayerAssetArea", "OpponentUnitArea", "OpponentAssetArea", "Stack"]:
		for view in _find_board_node(zone_name).get_children():
			var internal = view.find_child("InternalContainer", true, false)
			if internal.hover and internal.card:
				for target_id in internal.card.get_targets():
					targets.append([internal.card.get_id(), target_id])
	if GS.arrow_targets != targets:
		GS.arrow_targets = targets
	_sync_arrows(targets, false)

func _sync_arrows(targets, block):
	var store = block_arrows if block else arrows
	var desired = {}
	for pair in targets:
		desired[JSON.stringify(pair)] = pair
	var existing = {}
	for arrow in store.duplicate():
		var key = JSON.stringify([arrow.get_meta("start_id"), arrow.get_meta("end_id")])
		if desired.has(key) and not existing.has(key):
			existing[key] = arrow
		else:
			store.erase(arrow)
			remove_child(arrow)
			arrow.queue_free()
	for key in desired:
		if not existing.has(key):
			var pair = desired[key]
			draw_arrow(pair[0], pair[1], Color("80bddb") if block else Color("e5c180"), store)

func check_smart_pass_deferred(new_state, revision):
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or revision != _state_revision:
		return
	if O.smart_pass and GS.pending_decision.is_empty() and not GS.popup_cards:
		check_smart_pass(new_state)

func check_smart_pass(new_state):
	if not GS.is_waiting and new_state.get_activePlayer() == GS.playerId:
		if new_state.get_phase() == GS.Types.Phase.ATTACK and not GS.can_attack():
			GS.gameSocket.select_attackers()
		elif new_state.get_phase() == GS.Types.Phase.BLOCK and not GS.can_block():
			GS.gameSocket.select_blockers()
		elif GS.has_initiative() and not GS.has_action() and not SS.is_selecting():
			GS.gameSocket.pass_()

func draw_target_arrows(block = false):
	_sync_arrows(GS.block_arrow_targets.values() if block else GS.arrow_targets, block)

func remove_target_arrows(block = false):
	var store = block_arrows if block else arrows
	for arrow in store:
		if is_instance_valid(arrow):
			remove_child(arrow)
			arrow.queue_free()
	store.clear()
	if not block:
		GS.arrow_targets.clear()

func draw_arrow(start_id, end_id, color, store):
	var arrow = preload("res://src/GameBoard/TargetArrow.gd").new()
	arrow.name = "TargetArrow"
	arrow.tint = color
	arrow.set_meta("start_id", start_id)
	arrow.set_meta("end_id", end_id)
	add_child(arrow)
	store.append(arrow)
	update_arrow(arrow)

func update_arrow(arrow):
	var start_id = arrow.get_meta("start_id")
	var end_id = arrow.get_meta("end_id")
	var source = find_child(start_id, true, false)
	var target = find_child(end_id, true, false)
	if not is_instance_valid(source) or not is_instance_valid(target):
		arrow.visible = false
		return
	var source_center = _card_center(start_id, source)
	var target_center = _card_center(end_id, target)
	if source_center.distance_to(target_center) < 24.0:
		arrow.visible = false
		return
	var start = source_center
	var end = target_center
	# Containers can temporarily overlap while sorting; suppress reversed arrows.
	if (end - start).dot(target_center - source_center) <= 0:
		arrow.visible = false
		return
	arrow.visible = true
	arrow.set_endpoints(start, end)

func populate_block_arrows(state):
	var assignments = {}
	for player in [state.get_player(), state.get_opponent()]:
		if not player:
			continue
		for card in player.get_play():
			if card.get_combat() and card.get_combat().get_blockedAttacker():
				assignments[card.get_id()] = [card.get_id(), card.get_combat().get_blockedAttacker()]
	GS.block_arrow_targets = assignments
	_sync_arrows(assignments.values(), true)

func _process(_delta):
	_update_game_clocks()
	for arrow in arrows + block_arrows:
		if is_instance_valid(arrow):
			update_arrow(arrow)
	if not GS.connection_error.is_empty():
		_find_board_node("LoadingText").text = GS.connection_error + "\nPress Escape to return to the menu."
	if GS.socket:
		GS.socket._process(_delta)
	if GS.gameSocket:
		GS.gameSocket._process(_delta)
	if tutorial_mode and tutorial_submit_enabled:
		var options: Control = _find_board_node("OptionsOverlay") as Control
		var options_open: bool = is_instance_valid(options) and options.visible
		var submit: Button = _find_board_node("TutorialSubmit") as Button
		if is_instance_valid(submit):
			submit.visible = not options_open
			if not options_open:
				set_tutorial_submit_enabled(true)

func _snapshot_game_clocks(state):
	var player = state.get_player()
	var opponent = state.get_opponent()
	_player_time_ms = maxi(0, player.get_time()) if player else 0
	_opponent_time_ms = maxi(0, opponent.get_time()) if opponent else 0
	_clock_active_player_id = state.get_activePlayer()
	_clock_snapshot_msec = Time.get_ticks_msec()
	_clock_initialized = true
	_clock_running = true

func _update_game_clocks():
	if not _clock_initialized or not GS.gameState:
		return
	var elapsed_msec = maxi(0, Time.get_ticks_msec() - _clock_snapshot_msec) if _clock_running else 0
	var player = GS.gameState.get_player()
	var opponent = GS.gameState.get_opponent()
	var player_time = _player_time_ms
	var opponent_time = _opponent_time_ms
	if player and _clock_active_player_id == player.get_id():
		player_time = maxi(0, player_time - elapsed_msec)
	if opponent and _clock_active_player_id == opponent.get_id():
		opponent_time = maxi(0, opponent_time - elapsed_msec)
	_set_text_if_changed("PlayerClock", _format_clock(player_time))
	_set_text_if_changed("OpponentClock", _format_clock(opponent_time))

func _format_clock(time_msec: int) -> String:
	var total_seconds = ceili(float(maxi(0, time_msec)) / 1000.0)
	return "⌚ %02d:%02d" % [floori(float(total_seconds) / 60.0), total_seconds % 60]

func _exit_tree():
	_state_revision += 1
	GS.close_connections()
