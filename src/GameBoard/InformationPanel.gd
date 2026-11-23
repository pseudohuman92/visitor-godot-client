extends Control

# A compact version of the two-tier match HUD. Both players use this view;
# the opponent's tiers are reversed to preserve the board's mirrored layout.
const FRAME = preload("res://assets/ui/kit/surfaces/panels/ui_panel_standard.tres")
const FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold-Tracked.tres")
const ICONS = "res://assets/ui/kit/icons/png_64/ui_icon_%s_64.png"
const FACTIONS = {
	"B": {"name": "PARALLAX", "icon": "Blue", "color": Color("#62c6ee")},
	"G": {"name": "STRAIN", "icon": "Green", "color": Color("#78cb96")},
	"P": {"name": "COVENANT", "icon": "Purple", "color": Color("#c68ce1")},
	"R": {"name": "ASH", "icon": "Red", "color": Color("#de7874")},
	"Y": {"name": "AEGIS", "icon": "Yellow", "color": Color("#e2c26f")},
}
const CODES = ["B", "G", "P", "R", "Y"]
const UNAVAILABLE_KNOWLEDGE_TINT := Color(0.28, 0.28, 0.28)

var mirrored := false
var _name_label: Label
var _health_label: Label
var _energy_label: Label
var _studies_label: Label
var _knowledge_labels := {}
var _knowledge_icons := {}
var _knowledge_hit_areas := {}
var _choosing_knowledge := false
var _knowledge_choices := []
var _can_study := false

func configure(is_opponent: bool) -> void:
	mirrored = is_opponent
	mouse_filter = Control.MOUSE_FILTER_PASS
	var main_y := 60.0 if mirrored else 8.0
	var lower_y := 8.0 if mirrored else 67.0
	_name_label = _add_text("OPPONENT" if mirrored else "PLAYER", Vector2(17, main_y + 7), Vector2(93, 24), 19)
	_add_text("OPPONENT" if mirrored else "PLAYER", Vector2(18, main_y + 31), Vector2(92, 14), 10, Color("#75c9e5"))
	_add_icon("health", Vector2(121, main_y + 13), Vector2(25, 25), Color("#d45c5e"))
	_add_text("HEALTH", Vector2(150, main_y + 5), Vector2(52, 14), 10, Color("#b5aaa5"))
	_health_label = _add_text("20", Vector2(149, main_y + 17), Vector2(53, 30), 28)
	_add_icon("energy", Vector2(211, main_y + 13), Vector2(24, 24), Color("#5dd6e8"))
	_add_text("ENERGY", Vector2(239, main_y + 5), Vector2(46, 14), 10, Color("#91d5df"))
	_energy_label = _add_text("0/0", Vector2(239, main_y + 18), Vector2(47, 28), 20)
	_add_icon("study", Vector2(294, main_y + 13), Vector2(24, 24), Color("#c9d479"))
	_add_text("STUDY", Vector2(322, main_y + 5), Vector2(36, 14), 10, Color("#c9d479"))
	_studies_label = _add_text("1", Vector2(321, main_y + 17), Vector2(37, 30), 25)
	_add_text("KNOWLEDGE", Vector2(17, lower_y + 3), Vector2(104, 13), 11, Color("#b8aaa0"))
	for index in range(CODES.size()):
		var code: String = CODES[index]
		var faction: Dictionary = FACTIONS[code]
		var x := 18.0 + 69.0 * index
		var icon := TextureRect.new()
		icon.name = faction["name"] + "Icon"
		icon.texture = load("res://assets/card-components/Icons/Factions/%s.png" % faction["icon"])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(x, lower_y + 19)
		icon.size = Vector2(25, 25)
		add_child(icon)
		_knowledge_icons[code] = icon
		_knowledge_labels[code] = _add_text("0", Vector2(x + 31, lower_y + 18), Vector2(29, 27), 21, faction["color"])
		var hit_area := Control.new()
		hit_area.name = code + "KnowledgeHitArea"
		hit_area.position = Vector2(x, lower_y + 16)
		hit_area.size = Vector2(62, 29)
		hit_area.mouse_filter = Control.MOUSE_FILTER_PASS
		hit_area.tooltip_text = faction["name"] + " knowledge"
		hit_area.gui_input.connect(_on_knowledge_input.bind(code))
		add_child(hit_area)
		_knowledge_hit_areas[code] = hit_area
	queue_redraw()

func _draw() -> void:
	draw_style_box(FRAME, Rect2(Vector2.ZERO, size))
	var main_y := 60.0 if mirrored else 8.0
	var lower_y := 8.0 if mirrored else 67.0
	draw_rect(Rect2(8, main_y, 356, 52), Color("#0b1118e8"))
	draw_rect(Rect2(8, lower_y, 356, 45), Color("#0b1118e8"))
	draw_rect(Rect2(8, main_y, 3, 52), Color("#368fbb"))
	draw_rect(Rect2(8, lower_y, 3, 45), Color("#368fbb"))
	draw_line(Vector2(12, 57), Vector2(360, 57), Color("#6e7677"), 1)
	for x in [116.0, 205.0, 288.0]:
		draw_line(Vector2(x, main_y + 6), Vector2(x, main_y + 46), Color("#657579"), 1)
	for index in range(1, CODES.size()):
		var x := 13.0 + 69.0 * index
		draw_line(Vector2(x, lower_y + 18), Vector2(x, lower_y + 43), Color("#455055"), 1)
	if _choosing_knowledge:
		for index in range(CODES.size()):
			var code: String = CODES[index]
			if _knowledge_choices.has(CS.to_knowledge_type(code)):
				var x := 15.0 + 69.0 * index
				var rect := Rect2(x, lower_y + 15, 65, 32)
				draw_rect(rect, Color(0.37, 0.46, 0.20, 0.36))
				draw_rect(rect, Color.GREEN_YELLOW, false, 2.0)
	if _can_study and not mirrored:
		draw_rect(Rect2(5, 5, size.x - 10, size.y - 10), Color.GREEN_YELLOW, false, 2.0)

func update_player(player) -> void:
	var username: String = player.get_username() if player else ""
	if username.is_empty():
		username = "OPPONENT" if mirrored else "PLAYER"
	_name_label.text = username.to_upper()
	_name_label.add_theme_font_size_override("font_size", 14 if username.length() > 10 else 17 if username.length() > 7 else 19)
	_health_label.text = str(player.get_health()) if player else "0"
	_energy_label.text = "%d/%d" % [player.get_energy(), player.get_maxEnergy()] if player else "0/0"
	_studies_label.text = str(player.get_studiesLeft()) if player else "0"

func update_pool(pool) -> void:
	var counts := {}
	for group in pool:
		counts[CS.to_knowledge_string(group.get_knowledge())] = group.get_count()
	for code in CODES:
		_knowledge_labels[code].text = str(counts.get(code, 0))

func _process(_delta: float) -> void:
	_update_knowledge_choices()
	var can_study = false
	if not mirrored and GS.gameState and not GS.is_waiting:
		for card in GS.gameState.get_player().get_hand():
			if card.get_canStudy():
				can_study = true
				break
	if can_study != _can_study:
		_can_study = can_study
		queue_redraw()
	if not GS.gameState:
		return
	var player = GS.gameState.get_opponent() if mirrored else GS.gameState.get_player()
	var valid = SS.selection_targets.has(player.get_id())
	var tint = SS.INVALID_TARGET_MODULATE if SS.is_targeting_board_object() and not valid else Color.WHITE
	if modulate != tint:
		modulate = tint

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not mirrored and data is Card and is_instance_valid(data) and data.card \
		and data.card.get_canStudy() and not GS.is_waiting

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	var board = find_parent("GameBoard")
	GS.clear_drag()
	if is_instance_valid(board) and bool(board.get("tutorial_mode")):
		GS.gameSocket.study_card(data.card.get_id())
		return
	var costs = data.card.get_knowledgeCost()
	if costs.is_empty():
		SS.selected_single.append(GS.Types.Knowledge.NONE)
		GS.gameSocket.study_card(data.card.get_id())
	elif costs.size() == 1:
		SS.selected_single.append(costs[0].get_knowledge())
		GS.gameSocket.study_card(data.card.get_id())
	else:
		SS.clear_selection_data()
		SS.selecting_card = data.card
		SS.selecting_for = SS.selection_type.KNOWLEDGE
		SS.selection_message = "Select a knowledge to gain from your information panel."
		for cost in costs:
			SS.selection_targets.append(cost.get_knowledge())

func _update_knowledge_choices() -> void:
	var choosing = not mirrored and SS.selecting_for == SS.selection_type.KNOWLEDGE
	var choices = SS.selection_targets if choosing else []
	if choosing == _choosing_knowledge and choices == _knowledge_choices:
		return
	_choosing_knowledge = choosing
	_knowledge_choices = choices.duplicate()
	for code in CODES:
		var available = _knowledge_choices.has(CS.to_knowledge_type(code))
		var tint = UNAVAILABLE_KNOWLEDGE_TINT if choosing and not available else Color.WHITE
		_knowledge_icons[code].self_modulate = tint
		_knowledge_labels[code].self_modulate = tint
		_knowledge_hit_areas[code].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if choosing and available else Control.CURSOR_ARROW
		_knowledge_hit_areas[code].tooltip_text = "Choose %s knowledge" % FACTIONS[code]["name"] if choosing and available else FACTIONS[code]["name"] + " knowledge"
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if not GS.gameState or not SS.is_targeting_board_object():
		return
	var player = GS.gameState.get_opponent() if mirrored else GS.gameState.get_player()
	var id = player.get_id()
	if SS.selection_targets.has(id):
		if SS.selected_single.has(id):
			SS.selected_single.erase(id)
		else:
			SS.selected_single.append(id)
		SS.check_smart_select()
		accept_event()

func _on_knowledge_input(event: InputEvent, code: String) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if mirrored or SS.selecting_for != SS.selection_type.KNOWLEDGE \
			or not SS.selection_targets.has(CS.to_knowledge_type(code)):
		return
	var board = find_parent("GameBoard")
	if is_instance_valid(board) and bool(board.get("tutorial_mode")):
		board.call("notify_tutorial_action", "knowledge_select", CS.to_knowledge_type(code))
		get_viewport().set_input_as_handled()
	else:
		SS.selected_single.append(CS.to_knowledge_type(code))
		SS.selection_targets = []
		SS.selecting_for = SS.selection_type.NONE
		GS.gameSocket.study_card(SS.selecting_card.get_id())
		get_viewport().set_input_as_handled()

func _add_icon(icon_name: String, at: Vector2, dimensions: Vector2, color: Color) -> void:
	var icon := TextureRect.new()
	icon.texture = load(ICONS % icon_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = at
	icon.size = dimensions
	add_child(icon)

func _add_text(value: String, at: Vector2, dimensions: Vector2, font_size: int,
		color: Color = Color("#edece7")) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
