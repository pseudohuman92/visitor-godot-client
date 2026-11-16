extends "res://src/GameBoard/CardContainer.gd"

@export var fan_direction := 1.0
@export_range(0.0, 0.7, 0.01) var overlap_ratio := 0.36
@export var maximum_angle_degrees := 18.0
@export var arc_height := 24.0
@export var card_rotation_offset_degrees := 0.0

func _ready():
	resized.connect(queue_sort)
	queue_sort()

func sync_cards(cards, square=false, setup=true):
	var created = super.sync_cards(cards, square, setup)
	queue_sort()
	return created

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_fan()

func _get_minimum_size() -> Vector2:
	var count = get_child_count()
	if count == 0:
		return Vector2.ZERO
	var card_size = _card_dimensions()
	var spacing = card_size.x * (1.0 - overlap_ratio)
	return Vector2(card_size.x + spacing * (count - 1), card_size.y + arc_height)

func _card_dimensions() -> Vector2:
	for card in get_children():
		if card is Control:
			var dimensions = card.get_combined_minimum_size()
			if dimensions.x <= 0.0:
				dimensions.x = card.size.x
			if dimensions.y <= 0.0:
				dimensions.y = card.size.y
			if dimensions.x > 0.0 and dimensions.y > 0.0:
				return dimensions
	return Vector2(150.0, 210.0)

func _layout_fan():
	var cards = get_children()
	var count = cards.size()
	if count == 0:
		return
	var card_size = _card_dimensions()
	var spacing = card_size.x * (1.0 - overlap_ratio)
	if count > 1 and size.x >= card_size.x:
		spacing = minf(spacing, (size.x - card_size.x) / (count - 1))
	var fan_width = card_size.x + spacing * (count - 1)
	var start_x = maxf(0.0, (size.x - fan_width) * 0.5)
	var spread = maxf(1.0, (count - 1) * 0.5)
	for index in range(count):
		var card = cards[index] as Control
		card.size = card_size
		var center_pivot = is_equal_approx(fposmod(card_rotation_offset_degrees, 360.0), 180.0)
		card.pivot_offset = card_size * 0.5 if center_pivot else Vector2(card_size.x * 0.5, card_size.y)
		var fan_position = (index - (count - 1) * 0.5) / spread
		var edge = absf(fan_position)
		card.position = Vector2(start_x + index * spacing, arc_height * edge * edge * fan_direction)
		card.rotation = deg_to_rad(maximum_angle_degrees * fan_position * fan_direction + card_rotation_offset_degrees)
		card.z_index = index
