extends "res://src/GameBoard/CardContainer.gd"

@export_range(0.0, 0.95, 0.01) var overlap_ratio := 0.8

func _ready():
	resized.connect(queue_sort)
	queue_sort()

func sync_cards(cards, square=false, setup=true):
	var created = super.sync_cards(cards, square, setup)
	queue_sort()
	return created

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_pile()

func _get_minimum_size() -> Vector2:
	var count = get_child_count()
	if count == 0:
		return Vector2.ZERO
	var card_size = _card_dimensions()
	var step = card_size.y * (1.0 - overlap_ratio)
	return Vector2(card_size.x, card_size.y + step * (count - 1))

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

func _layout_pile():
	var cards = get_children()
	if cards.is_empty():
		return
	var card_size = _card_dimensions()
	if size.x > 0.0 and card_size.x > size.x:
		card_size *= size.x / card_size.x
	var step = card_size.y * (1.0 - overlap_ratio)
	var left = maxf(0.0, (size.x - card_size.x) * 0.5)
	for index in range(cards.size()):
		var card = cards[index] as Control
		card.size = card_size
		card.pivot_offset = Vector2(card_size.x * 0.5, card_size.y * 0.5)
		card.position = Vector2(left, index * step)
		card.rotation = 0.0
		card.z_index = index
