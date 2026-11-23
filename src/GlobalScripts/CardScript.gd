extends Node

const text_icons = {
	"{B}": "res://assets/card-components/Icons/Factions/Blue.png",
	"{G}": "res://assets/card-components/Icons/Factions/Green.png",
	"{P}": "res://assets/card-components/Icons/Factions/Purple.png",
	"{R}": "res://assets/card-components/Icons/Factions/Red.png",
	"{Y}": "res://assets/card-components/Icons/Factions/Yellow.png",
#	"{Use}": "res://assets/card-components/use-icon-black.png",
	"{damage}": "res://assets/card-components/Icons/Combat/Attack.png",
	"{shield}": "res://assets/card-components/Icons/Combat/Shield.png",
	"{0}": "res://assets/card-components/Icons/Numbers/Colorless/0.png",
	"{1}": "res://assets/card-components/Icons/Numbers/Colorless/1.png",
	"{2}": "res://assets/card-components/Icons/Numbers/Colorless/2.png",
	"{3}": "res://assets/card-components/Icons/Numbers/Colorless/3.png",
	"{4}": "res://assets/card-components/Icons/Numbers/Colorless/4.png",
	"{5}": "res://assets/card-components/Icons/Numbers/Colorless/5.png",
	"{6}": "res://assets/card-components/Icons/Numbers/Colorless/6.png",
	"{7}": "res://assets/card-components/Icons/Numbers/Colorless/7.png",
	"{8}": "res://assets/card-components/Icons/Numbers/Colorless/8.png",
	"{9}": "res://assets/card-components/Icons/Numbers/Colorless/9.png",
	"{X}": "res://assets/card-components/Icons/Numbers/Colorless/X.png",
}

const CARD_PROPERTY_ICON_DIR = "res://assets/card-components/Icons/"
const DEPLOYING_ICON_PATH = CARD_PROPERTY_ICON_DIR + "deploying.png"
const KEYWORD_ICON_DIR = CARD_PROPERTY_ICON_DIR
const KEYWORD_ICON_ORDER = [
	"Deadly", "Defender", "FirstStrike", "Trample", "Evasive",
	"Vigilance", "Lifelink", "Reach", "Drain", "Unblockable",
	"Blitz", "Decay", "Regenerate",
]
const EDGE_ICON_SIZE = 28.0
const EDGE_ICON_STEP = 30.0
const EDGE_ICON_TOP = 42.0
const CARD_FRAME_DIR = "res://assets/card-components/Borders/"
const SHOW_CARD_BORDERS := true
const SHOW_CARD_IMAGE_BORDERS := false
const CARD_FRAME_BY_COLOR = {
	"B": "Parallax",
	"G": "Strain",
	"P": "Covenant",
	"R": "Ash",
	"Y": "Aegis",
}
const CARD_FRAME_OPENING_BY_NAME = {
	"Aegis": Rect2(0.061, 0.072, 0.879, 0.873),
	"Ash": Rect2(0.064, 0.096, 0.873, 0.843),
	"Covenant": Rect2(0.062, 0.110, 0.876, 0.790),
	"Factionless": Rect2(0.082, 0.096, 0.837, 0.827),
	"Parallax": Rect2(0.065, 0.081, 0.870, 0.843),
	"Strain": Rect2(0.084, 0.082, 0.831, 0.841),
}

func set_card_frame(card_view, card):
	if card_view == null or card_view.find_child("CardImage") == null:
		return
	var card_image = card_view.find_child("CardImage") as Control
	var internal = card_view.find_child("InternalContainer") as Control
	if card_view.name == "InternalContainer":
		internal = card_view as Control
	_set_card_border_visibility(internal, SHOW_CARD_BORDERS)
	_set_card_border_visibility(card_image, SHOW_CARD_BORDERS)
	var artwork = card_image.get_node_or_null("Artwork") as Control
	var frame = card_image.get_node_or_null("FactionFrame") as TextureRect
	if frame == null:
		frame = TextureRect.new()
		frame.name = "FactionFrame"
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		card_image.add_child(frame)
		var contents = card_image.get_node_or_null("Contents")
		if contents:
			card_image.move_child(frame, contents.get_index())
	if card == null:
		frame.hide()
		if artwork:
			artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return
	var frame_name = "Factionless"
	var knowledge_cost = card.get_knowledgeCost()
	if not knowledge_cost.is_empty():
		var color = to_knowledge_string(knowledge_cost[0].get_knowledge())
		frame_name = CARD_FRAME_BY_COLOR.get(color, frame_name)
	var opening: Rect2 = CARD_FRAME_OPENING_BY_NAME[frame_name]
	if artwork:
		if SHOW_CARD_IMAGE_BORDERS:
			artwork.anchor_left = opening.position.x
			artwork.anchor_top = opening.position.y
			artwork.anchor_right = opening.position.x + opening.size.x
			artwork.anchor_bottom = opening.position.y + opening.size.y
			artwork.offset_left = 0.0
			artwork.offset_top = 0.0
			artwork.offset_right = 0.0
			artwork.offset_bottom = 0.0
		else:
			artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.texture = load(CARD_FRAME_DIR + frame_name + ".png")
	frame.visible = SHOW_CARD_IMAGE_BORDERS

func _set_card_border_visibility(panel: Control, visible: bool):
	if panel == null:
		return
	var source_style
	if panel.has_meta("source_card_border_style"):
		source_style = panel.get_meta("source_card_border_style")
	else:
		source_style = panel.get_theme_stylebox("panel")
		panel.set_meta("source_card_border_style", source_style)
	if visible:
		panel.add_theme_stylebox_override("panel", source_style)
	else:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func get_card_image(set_name, card_name):
	var path = "res://assets/card-images/" + set_name + "/" + card_name + ".png"
	return load(path) if ResourceLoader.exists(path, "Texture2D") else null

func get_type_icon(type):
	return load ("res://assets/card-components/Icons/Types/"+type+".png")

func get_placeholder_image(type):
	return load("res://assets/card-images/placeholders/"+type+".png")

func to_knowledge_string(knowledge):
	match knowledge:
		GS.Types.Knowledge.BLUE:
			return "B"
		GS.Types.Knowledge.GREEN:
			return "G"
		GS.Types.Knowledge.RED:
			return "R"
		GS.Types.Knowledge.PURPLE:
			return "P"
		GS.Types.Knowledge.YELLOW:
			return "Y"
	return ""

func to_knowledge_color(knowledge):
	if knowledge:
		match knowledge[0].get_knowledge():
			GS.Types.Knowledge.BLUE:
				return Color.NAVY_BLUE
			GS.Types.Knowledge.GREEN:
				return Color.DARK_GREEN
			GS.Types.Knowledge.RED:
				return Color.DARK_RED
			GS.Types.Knowledge.PURPLE:
				return Color.REBECCA_PURPLE
			GS.Types.Knowledge.YELLOW:
				return Color.DARK_GOLDENROD
	return Color.DIM_GRAY

func to_knowledge_type(knowledge):
	match knowledge:
		"B":
			return GS.Types.Knowledge.BLUE
		"G":
			return GS.Types.Knowledge.GREEN
		"R":
			return GS.Types.Knowledge.RED
		"P":
			return GS.Types.Knowledge.PURPLE
		"Y":
			return GS.Types.Knowledge.YELLOW
	return GS.Types.Knowledge.NONE

func to_knowledge_string_with_count(knowledge):
	var s = ""
	for knw in knowledge:
		for i in knw.get_count():
			s += to_knowledge_string(knw.get_knowledge())
	return s

func to_knowledge_string_no_count(knowledge):
	var s = ""
	for knw in knowledge:
		s += to_knowledge_string(knw.get_knowledge())
	return s

func to_array_string(arr, sep = " "):
	var res = ""
	for s in arr:
		res += str(s) + sep
	return res

func position_in_bounds(size, pos):
		return Vector2(min(max(0, pos.x), 1820-size.x), min(max(0, pos.y), 930-size.y))

func compare_cost_name_cardP(a, b):
	var a_cost = str(a.get_cost()).strip_edges()
	var b_cost = str(b.get_cost()).strip_edges()
	var a_numeric = a_cost.is_valid_int() or a_cost.is_empty()
	var b_numeric = b_cost.is_valid_int() or b_cost.is_empty()
	if a_numeric != b_numeric:
		return a_numeric
	if a_numeric:
		if a_cost.to_int() != b_cost.to_int():
			return a_cost.to_int() < b_cost.to_int()
	else:
		var comparison = a_cost.naturalnocasecmp_to(b_cost)
		if comparison != 0:
			return comparison < 0
	var name_order = a.get_name().naturalnocasecmp_to(b.get_name())
	if name_order != 0:
		return name_order < 0
	return a.get_set().naturalnocasecmp_to(b.get_set()) < 0

func compare_color_cost_name_cardP(a, b):
	var a_c = a.get_knowledgeCost()
	var b_c = b.get_knowledgeCost()
	match to_knowledge_string_no_count(a_c).casecmp_to(to_knowledge_string_no_count(b_c)):
		-1: return true
		0: return compare_cost_name_cardP(a, b)
		1: return false

func change_stylebox_override(field, node, fun):
		var image_box = node.get_theme_stylebox(field).duplicate()
		fun.call(image_box)
		node.add_theme_stylebox_override(field, image_box)

func set_card_art(node, texture, modulate_color=Color.WHITE):
	node.texture = texture
	node.modulate = modulate_color

func set_stylebox_knowledge_color(field, node, color):
	change_stylebox_override(field, node, func(style_box):
		if style_box is StyleBoxTexture:
			style_box.modulate_color = color
		elif style_box is StyleBoxFlat:
			style_box.bg_color = color)

func load_card_image_and_type(c):
	var image = get_card_image(c.card.get_set(), c.card.get_name())
	var type
	if c.card.get_types()[0] == "Spell" and c.card.get_subtypes():
		type = c.card.get_subtypes()[0]
	else:
		type = c.card.get_types()[0]
	var tint = Color.WHITE
	if image == null:
		image = get_placeholder_image(type)
		tint = Color.GRAY
	set_card_art(c.find_child("Artwork"), image, tint)
	c.find_child("TypeIcon").set_texture(get_type_icon(type))


func set_card_property_icons(card_view, combat):
	var card_image = card_view.find_child("CardImage") as Control
	if card_image == null:
		return
	var icons = []
	if combat:
		var abilities = combat.get_combatAbilities()
		if combat.get_deploying() and not abilities.has("Blitz"):
			icons.append(["Deploying", DEPLOYING_ICON_PATH])
		for keyword in KEYWORD_ICON_ORDER:
			if abilities.has(keyword):
				icons.append([keyword, KEYWORD_ICON_DIR + keyword.to_snake_case() + ".png"])
	var column = card_image.get_node_or_null("CardPropertyIcons") as Control
	if icons.is_empty():
		if column:
			column.hide()
		return
	if column == null:
		column = Control.new()
		column.name = "CardPropertyIcons"
		column.anchor_left = 1.0
		column.anchor_right = 1.0
		column.offset_left = -EDGE_ICON_SIZE - 2.0
		column.offset_right = -2.0
		column.offset_top = EDGE_ICON_TOP
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.z_index = 1
		card_image.add_child(column)
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var square = card_view.get_parent() is AspectRatioContainer and card_view.get_parent().ratio > 0.95
	var max_icons = 3 if square else 4
	var visible_count = mini(icons.size(), max_icons)
	if icons.size() > max_icons:
		visible_count -= 1
	var overflow = icons.size() - visible_count
	for index in range(visible_count):
		var icon = TextureRect.new()
		icon.name = icons[index][0] + "Icon"
		icon.texture = load(icons[index][1])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.position = Vector2(0.0, index * EDGE_ICON_STEP)
		icon.size = Vector2.ONE * EDGE_ICON_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(icon)
	if overflow > 0:
		var badge = Panel.new()
		badge.name = "OverflowBadge"
		badge.position = Vector2(0.0, visible_count * EDGE_ICON_STEP)
		badge.size = Vector2.ONE * EDGE_ICON_SIZE
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#1C2022")
		style.border_color = Color("#6C7375")
		style.set_border_width_all(1)
		badge.add_theme_stylebox_override("panel", style)
		var count = Label.new()
		count.text = "+" + str(overflow)
		count.set_anchors_preset(Control.PRESET_FULL_RECT)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.add_theme_font_size_override("font_size", 16)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(count)
		column.add_child(badge)
	column.offset_bottom = EDGE_ICON_TOP + (visible_count + (1 if overflow > 0 else 0) - 1) * EDGE_ICON_STEP + EDGE_ICON_SIZE
	column.show()


func setup_card(n, card=null):
	CS.set_card_frame(n, card)
	if card:
		n.card = card
		n.find_child("Contents").show()
		CS.load_card_image_and_type(n)
		n.find_child("CostArea").update(card.get_cost(), card.get_knowledgeCost())
		n.find_child("Name").set_text(card.get_name())
		n.find_child("DepletePanel").set_visible(card.get_depleted())
		CS.set_stylebox_knowledge_color("normal", n.find_child("Name"), to_knowledge_color(card.get_knowledgeCost()))
		var ability_text = ""
		var combat = card.get_combat()
		if combat:
			n.find_child("Stats").set_visible(true)
			var stats_text = ""
			if combat.get_attack():
				n.find_child("Attack").set_text(str(combat.get_attack()))
			else:
				n.find_child("Attack").set_text("0")
			n.find_child("Shield").set_visible(combat.get_shield() != 0)
			if combat.get_shield():
				n.find_child("Shield").set_text(str(combat.get_shield()))
			else:
				n.find_child("Shield").set_visible(false)
			if combat.get_health():
				n.find_child("Health").set_text(str(combat.get_health()))
			else:
				n.find_child("Health").set_text("0")
			if combat.get_combatAbilities():
				ability_text += to_array_string(combat.get_combatAbilities(), ", ").trim_suffix(", ") + "\n"
		else:
			n.find_child("Stats").set_visible(false)
		set_card_property_icons(n, combat)
		ability_text += card.get_description()
		if n.find_child("Ability"):
			if ability_text != "":
				n.find_child("AbilityPanel").set_visible(true)
				n.find_child("Ability").set_text_custom(ability_text, card.get_name())
				CS.change_stylebox_override("panel", n.find_child("AbilityPanel"), func(b): b.set_bg_color(to_knowledge_color(card.get_knowledgeCost())-Color(0,0,0,0.4)))
			else:
				n.find_child("AbilityPanel").set_visible(false)
	else:
		CS.set_card_art(n.find_child("Artwork"), load(GS.card_back_path))
		n.find_child("Contents").set_visible(false)
		set_card_property_icons(n, null)

func sanitize_card_name(name):
	return name.replace(" ","").replace(".","").replace("-","")

func read_deck_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Could not open deck: " + error_string(FileAccess.get_open_error())}
	var deck_name = file.get_line().strip_edges()
	if deck_name.is_empty():
		file.close()
		return {"error": "The deck must have a name on the first line."}
	var entries = []
	var lines = []
	var counts = {}
	var line_number = 1
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		line_number += 1
		if line.is_empty():
			continue
		var separator = line.find(";")
		var dot = line.find(".", separator + 1)
		var count_text = line.substr(0, separator)
		if separator <= 0 or dot <= separator + 1 or dot >= line.length() - 1 or not count_text.is_valid_int():
			file.close()
			return {"error": "Invalid deck entry on line %d." % line_number}
		var count = count_text.to_int()
		var set_name = line.substr(separator + 1, dot - separator - 1)
		var card_name = line.substr(dot + 1)
		var key = set_name + "." + card_name
		counts[key] = counts.get(key, 0) + count
		if count < 1 or counts[key] > 3:
			file.close()
			return {"error": "Deck entries must contain one to three copies per card (line %d)." % line_number}
		entries.append({"count": count, "set": set_name, "card": card_name})
		lines.append(str(count) + ";" + key)
	file.close()
	return {"name": deck_name, "entries": entries, "lines": lines}

func show_error(message):
	if not is_inside_tree() or get_tree().current_scene == null:
		return
	var dialog = AcceptDialog.new()
	dialog.title = "Unable to complete action"
	dialog.dialog_text = message
	get_tree().current_scene.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func set_cost_texture(background: TextureRect, cost):
	# Number artwork already includes the printed value; never overlay a label.
	var old_label = background.find_child("Cost")
	if old_label:
		old_label.hide()
	var value = str(cost).strip_edges() if cost != null else ""
	if value.is_empty():
		background.texture = null
		background.hide()
		return
	var path = "res://assets/card-components/Icons/Numbers/Colorless/" + value + ".png"
	if not ResourceLoader.exists(path, "Texture2D"):
		background.texture = null
		background.hide()
		push_warning("Missing card cost texture: " + path)
		return
	background.texture = load(path)
	background.show()
