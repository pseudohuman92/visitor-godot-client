extends CanvasLayer

const BODY_FONT = preload("res://assets/fonts/Barlow-Regular.ttf")
const HEADING_FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const MAIN_THEME = preload("res://src/Themes/MainTheme.tres")
const DESCRIPTIONS = {
	"Deadly": "Combat damage from this unit destroys damaged units.",
	"Defender": "This unit cannot attack.",
	"FirstStrike": "Deals combat damage before units without First Strike.",
	"Trample": "Excess combat damage to a blocker reaches the defending player.",
	"Evasive": "Can only be blocked by units with Evasive or Reach.",
	"Vigilance": "Attacking does not deplete this unit.",
	"Lifelink": "Damage dealt by this unit also heals its controller.",
	"Reach": "Can block units with Evasive.",
	"Drain": "Damage dealt by this unit also heals this unit.",
	"Unblockable": "This unit cannot be blocked.",
	"Blitz": "Can attack while deploying.",
	"Decay": "At the start of its turn, loses 1 attack and 1 current and maximum health.",
	"Regenerate": "Heals at the start of its turn.",
}

func setup(card_data, collection_card := false):
	layer = 30
	var viewport_size := get_viewport().get_visible_rect().size
	var surface := Control.new()
	surface.name = "CardPreviewSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.theme = MAIN_THEME
	add_child(surface)

	var abilities: Array[String] = []
	if card_data.get_combat():
		for keyword in CS.KEYWORD_ICON_ORDER:
			if card_data.get_combat().get_combatAbilities().has(keyword):
				abilities.append(keyword)

	var card_size := Vector2(viewport_size.y * O.card_height * O.card_aspect_ratio, viewport_size.y * O.card_height)
	var preview_scale := minf(2.0, (viewport_size.y - 48.0) / card_size.y)
	var preview_size := card_size * preview_scale
	var gap := 24.0
	var tooltip_width := minf(390.0, viewport_size.x * 0.35)
	var total_width := preview_size.x + (gap + tooltip_width if not abilities.is_empty() else 0.0)
	var origin := Vector2(maxf(24.0, (viewport_size.x - total_width) * 0.5), maxf(24.0, (viewport_size.y - preview_size.y) * 0.5))

	var preview = GS.CollectionCardScene.instantiate() if collection_card else GS.CardScene.instantiate()
	preview.setup(card_data)
	surface.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	preview.position = origin
	preview.size = card_size
	preview.scale = Vector2.ONE * preview_scale
	if not collection_card:
		preview.find_child("InternalContainer").display = true
	_ignore_mouse(preview)

	if not abilities.is_empty():
		_add_tooltips(surface, abilities, origin + Vector2(preview_size.x + gap, 0.0), tooltip_width, minf(preview_size.y, viewport_size.y - 48.0))

func _add_tooltips(surface: Control, abilities: Array[String], position: Vector2, width: float, max_height: float):
	var panel_size := Vector2(width, minf(max_height, 80.0 + abilities.size() * 78.0))
	var panel := PanelContainer.new()
	panel.name = "KeywordTooltips"
	panel.position = position
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171b1f")
	style.border_color = Color("#805453")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	panel.add_theme_stylebox_override("panel", style)
	surface.add_child(panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 15)
	margins.add_theme_constant_override("margin_right", 15)
	margins.add_theme_constant_override("margin_top", 13)
	margins.add_theme_constant_override("margin_bottom", 13)
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margins.add_child(content)

	var title := Label.new()
	title.text = "KEYWORD ABILITIES"
	title.add_theme_font_override("font", HEADING_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#e8e5df"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(list)
	for keyword in abilities:
		_add_keyword_row(list, keyword, width - 54.0)

func _add_keyword_row(list: VBoxContainer, keyword: String, width: float):
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(row)

	var icon := TextureRect.new()
	icon.texture = load(CS.KEYWORD_ICON_DIR + keyword.to_snake_case() + ".png")
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var labels := VBoxContainer.new()
	labels.custom_minimum_size.x = width - 44.0
	labels.add_theme_constant_override("separation", 2)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(labels)

	var heading := Label.new()
	heading.text = "First Strike" if keyword == "FirstStrike" else keyword
	heading.add_theme_font_override("font", HEADING_FONT)
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("#e8e5df"))
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(heading)

	var description := Label.new()
	description.text = DESCRIPTIONS.get(keyword, "")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_override("font", BODY_FONT)
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color("#c8c9c6"))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(description)

func _ignore_mouse(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		GS.close_bigger_popup()
