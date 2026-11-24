extends Control

const TOTAL_ROUNDS := 20
const TOTAL_PICKS := TOTAL_ROUNDS * 2
const CARD_BUTTON_SIZE := Vector2(244, 390)
const CARD_VIEW_SIZE := Vector2(220, 308)
const PICK_STYLE = preload("res://assets/ui/styles/button_secondary_default.tres")
const PICK_HOVER_STYLE = preload("res://assets/ui/styles/button_secondary_hover.tres")
const PICK_DISABLED_STYLE = preload("res://assets/ui/styles/button_secondary_disabled.tres")
const PICK_FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold-Tracked.tres")

@onready var status_label: Label = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/Status
@onready var progress_label: Label = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/Progress
@onready var instructions_label: Label = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/Instructions
@onready var error_label: Label = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/Error
@onready var candidate_cards: HBoxContainer = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/ChoicesCenter/CandidateCards
@onready var completed_scroll: ScrollContainer = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/ChoicesCenter/CompletedScroll
@onready var completed_cards: GridContainer = $Margins/Layout/Body/ChoicesPanel/ChoicesMargin/ChoicesLayout/ChoicesCenter/CompletedScroll/CompletedCards
@onready var picked_count: Label = $Margins/Layout/Body/DeckPanel/DeckMargin/DeckLayout/PickedCount
@onready var deck_list: VBoxContainer = $Margins/Layout/Body/DeckPanel/DeckMargin/DeckLayout/DeckScroll/DeckList
@onready var play_match_button: Button = $Margins/Layout/Body/DeckPanel/DeckMargin/DeckLayout/PlayDraftMatch
@onready var retry_button: Button = $Margins/Layout/Body/DeckPanel/DeckMargin/DeckLayout/Retry

var _draft_state
var _ai_draft := false
var _submitted := false
var _pick_buttons: Array[Button] = []
var _candidate_by_id := {}
var _picked_cards := []
var _picked_card_ids: Array[String] = []

func _ready() -> void:
	GS.close_connections()
	_resize_completed_gallery()
	get_window().size_changed.connect(_resize_completed_gallery)
	_ai_draft = GS.queue_type == GS.Types.GameType.AI_DRAFT
	GS.queue_type = GS.Types.GameType.AI_DRAFT if _ai_draft else GS.Types.GameType.P2_DRAFT
	GS.game_decklist = []
	GS.draft_id = ""
	GS.is_waiting = true
	if _ai_draft:
		status_label.text = "Preparing AI draft"
	progress_label.text = "20 rounds, two picks per round"
	_render_decklist([])
	_connect_profile()

func _resize_completed_gallery() -> void:
	completed_scroll.custom_minimum_size.y = clampf(get_window().size.y * 0.52, 330.0, 560.0)

func _process(delta: float) -> void:
	if is_instance_valid(GS.socket):
		GS.socket._process(delta)
	if is_instance_valid(GS.gameSocket):
		GS.gameSocket._process(delta)

func _connect_profile() -> void:
	var socket = Websocket.new()
	GS.socket = socket
	socket.got_login_response.connect(func(): socket.joinQueue(GS.queue_type))
	socket.draft_started.connect(_on_draft_started)
	socket.connection_failed.connect(_on_profile_failed)
	socket.connect_to_server()

func _on_draft_started(draft_state) -> void:
	_draft_state = draft_state
	GS.draft_id = draft_state.get_id()
	GS.gameId = GS.draft_id
	GS.playerId = draft_state.get_playerId()
	GS.gameType = GS.queue_type
	status_label.text = "Draft AI ready" if _ai_draft else "Opponent found"
	progress_label.text = "Connecting to the draft table"
	instructions_label.text = "Your first choices are on their way."
	error_label.text = ""
	retry_button.hide()
	_connect_draft()

func _connect_draft() -> void:
	var socket = preload("res://src/Draft/DraftSocket.gd").new()
	GS.gameSocket = socket
	socket.pick_requested.connect(_on_pick_requested)
	socket.draft_completed.connect(_on_draft_completed)
	socket.connection_failed.connect(_on_draft_failed)
	socket.connect_to_server()

func _on_pick_requested(draft_state, candidates, message: String) -> void:
	_draft_state = draft_state
	_submitted = false
	error_label.text = ""
	retry_button.hide()
	play_match_button.hide()
	var count := _count_picks(draft_state.get_decklist())
	var round_number := floori(float(count) / 2.0) + 1
	var pick_number := count % 2 + 1
	status_label.text = "Choose a card"
	progress_label.text = "ROUND %d / %d     PICK %d / 2" % [round_number, TOTAL_ROUNDS, pick_number]
	instructions_label.text = message if not message.is_empty() else "Choose one of the cards below."
	_render_decklist(draft_state.get_decklist())
	_clear_candidates()
	candidate_cards.show()
	completed_scroll.hide()
	for card in candidates:
		_add_candidate(card)
	if candidates.is_empty():
		_on_draft_failed("The draft offer did not contain any cards.")

func _add_candidate(card) -> void:
	_candidate_by_id[card.get_id()] = card
	var button := Button.new()
	button.name = "Pick_%s" % card.get_id().replace("-", "")
	button.custom_minimum_size = CARD_BUTTON_SIZE
	button.tooltip_text = card.get_name() + "\n" + card.get_description()
	button.add_theme_stylebox_override("normal", PICK_STYLE)
	button.add_theme_stylebox_override("hover", PICK_HOVER_STYLE)
	button.add_theme_stylebox_override("pressed", PICK_HOVER_STYLE)
	button.add_theme_stylebox_override("disabled", PICK_DISABLED_STYLE)
	button.pressed.connect(_on_pick_pressed.bind(card.get_id(), card.get_name()))
	candidate_cards.add_child(button)
	_pick_buttons.append(button)
	var view = GS.CardScene.instantiate()
	view.name = "DraftCard"
	view.setup(card)
	_set_mouse_filter_ignore_recursive(view)
	button.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	view.position = Vector2(12, 10)
	view.size = CARD_VIEW_SIZE
	var pick_label := Label.new()
	pick_label.text = "PICK %s" % card.get_name().to_upper()
	pick_label.position = Vector2(12, 330)
	pick_label.size = Vector2(220, 48)
	pick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pick_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pick_label.add_theme_font_override("font", PICK_FONT)
	pick_label.add_theme_font_size_override("font_size", 17)
	pick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(pick_label)

func _set_mouse_filter_ignore_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore_recursive(child)

func _on_pick_pressed(card_id: String, card_name: String) -> void:
	if _submitted or not is_instance_valid(GS.gameSocket):
		return
	var error = GS.gameSocket.pick_card(card_id)
	if error != OK:
		_on_draft_failed("Could not pick %s: %s" % [card_name, error_string(error)])
		return
	if _candidate_by_id.has(card_id) and not _picked_card_ids.has(card_id):
		_picked_cards.append(_candidate_by_id[card_id])
		_picked_card_ids.append(card_id)
	_submitted = true
	for button in _pick_buttons:
		button.disabled = true
	status_label.text = "Picked %s" % card_name
	instructions_label.text = "Waiting for the next offer." if _ai_draft else "Waiting for the other player to pick."
	var pending_count := _count_picks(_draft_state.get_decklist()) + 1
	picked_count.text = "%d / %d cards (pending)" % [pending_count, TOTAL_PICKS]
	_add_deck_line("Pending: %s" % card_name, true)

func _on_draft_completed(draft_state) -> void:
	_draft_state = draft_state
	_clear_candidates()
	candidate_cards.hide()
	_render_completed_cards()
	_render_decklist(draft_state.get_decklist())
	status_label.text = "Draft complete"
	progress_label.text = "ALL %d ROUNDS COMPLETE" % TOTAL_ROUNDS
	instructions_label.text = "Your deck is ready. Join the draft match when you are ready."
	error_label.text = ""
	retry_button.hide()
	play_match_button.show()

func _render_decklist(lines: Array) -> void:
	for child in deck_list.get_children():
		child.queue_free()
	var count := _count_picks(lines)
	picked_count.text = "%d / %d cards" % [count, TOTAL_PICKS]
	if lines.is_empty():
		_add_deck_line("Your picks will appear here.", true)
		return
	for line in lines:
		var quantity := maxi(1, int(line.get_slice(";", 0)))
		var card_class: String = str(line).get_slice(";", 1).get_slice(".", 1)
		var display_name: String = card_class.to_snake_case().replace("_", " ").capitalize()
		for picked_card in _picked_cards:
			if CS.sanitize_card_name(picked_card.get_name()) == card_class:
				display_name = picked_card.get_name()
				break
		_add_deck_line("%d × %s" % [quantity, display_name])

func _add_deck_line(value: String, muted := false) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	if muted:
		label.add_theme_color_override("font_color", Color("#879090"))
	deck_list.add_child(label)

func _count_picks(lines: Array) -> int:
	var count := 0
	for line in lines:
		count += int(line.get_slice(";", 0))
	return count

func _clear_candidates() -> void:
	_pick_buttons.clear()
	_candidate_by_id.clear()
	for child in candidate_cards.get_children():
		child.queue_free()

func _render_completed_cards() -> void:
	for child in completed_cards.get_children():
		child.queue_free()
	for card in _picked_cards:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(180, 252)
		completed_cards.add_child(slot)
		var view = GS.CardScene.instantiate()
		view.setup(card)
		_set_mouse_filter_ignore_recursive(view)
		slot.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		view.position = Vector2.ZERO
		view.size = slot.custom_minimum_size
	completed_cards.visible = not _picked_cards.is_empty()
	completed_scroll.visible = completed_cards.visible
	completed_scroll.scroll_vertical = 0

func _on_play_match_pressed() -> void:
	if _draft_state == null or not _draft_state.get_completed():
		return
	GS.game_decklist = _draft_state.get_decklist().duplicate()
	GS.draft_id = _draft_state.get_id()
	GS.queue_type = GS.Types.GameType.AI_DRAFT_GAME if _ai_draft else GS.Types.GameType.P2_DRAFT_GAME
	get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/MainMenu/MainMenu.tscn")

func _on_retry_pressed() -> void:
	retry_button.hide()
	error_label.text = ""
	if _draft_state == null:
		get_tree().reload_current_scene()
		return
	if is_instance_valid(GS.gameSocket):
		GS.gameSocket.close()
		GS.gameSocket.queue_free()
	status_label.text = "Reconnecting to draft"
	_connect_draft()

func _on_profile_failed(reason: String) -> void:
	if _draft_state == null:
		_on_draft_failed(reason)
	else:
		error_label.text = "Profile connection lost. Your draft connection is still active."

func _on_draft_failed(reason: String) -> void:
	status_label.text = "Connection interrupted"
	error_label.text = reason
	retry_button.show()
	for button in _pick_buttons:
		button.disabled = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _exit_tree() -> void:
	GS.close_connections()
