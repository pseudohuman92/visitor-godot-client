extends "res://src/GameBoard/CardContainer.gd"

const DISCARD_OVERLAP_RATIO := 0.8
const DISCARD_COLUMN_GAP := 18.0
const NORMAL_CARD_GAP := 4.0
const VIEWPORT_SIDE_MARGIN := 96.0
const MAX_DISCARD_ROWS_PER_COLUMN := 5

var discard_layout := false

func _ready():
	resized.connect(queue_sort)
	queue_sort()

func sync_cards(cards, square=false, setup=true):
	var created = super.sync_cards(cards, square, setup)
	queue_sort()
	return created

func set_discard_layout(enabled: bool):
	if discard_layout == enabled:
		return
	discard_layout = enabled
	update_minimum_size()
	queue_sort()

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_cards()

func _get_minimum_size() -> Vector2:
	var count = get_child_count()
	if count == 0:
		return Vector2.ZERO
	var card_size = _card_dimensions()
	if discard_layout:
		var columns = _discard_column_count(count, card_size)
		var cards_per_column = ceili(float(count) / columns)
		var step = card_size.y * (1.0 - DISCARD_OVERLAP_RATIO)
		return Vector2(columns * card_size.x + (columns - 1) * DISCARD_COLUMN_GAP,
			card_size.y + (cards_per_column - 1) * step)
	return Vector2(count * card_size.x + (count - 1) * NORMAL_CARD_GAP, card_size.y)

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
	return Vector2(200.0, 300.0)

func _discard_column_count(count: int, card_size: Vector2) -> int:
	var available_width = maxf(1.0, get_viewport_rect().size.x - VIEWPORT_SIDE_MARGIN * 2.0)
	var columns_that_fit = maxi(1, int(floor((available_width + DISCARD_COLUMN_GAP)
		/ (card_size.x + DISCARD_COLUMN_GAP))))
	var columns_for_row_limit = ceili(float(count) / MAX_DISCARD_ROWS_PER_COLUMN)
	return mini(count, mini(columns_that_fit, columns_for_row_limit))

func _layout_cards():
	var cards = get_children()
	var count = cards.size()
	if count == 0:
		return
	var card_size = _card_dimensions()
	var columns = _discard_column_count(count, card_size) if discard_layout else 1
	var cards_per_column = ceili(float(count) / columns) if discard_layout else count
	var gap = DISCARD_COLUMN_GAP if discard_layout else NORMAL_CARD_GAP
	var step = card_size.y * (1.0 - DISCARD_OVERLAP_RATIO) if discard_layout else 0.0
	var layout_width = columns * card_size.x + (columns - 1) * gap
	var start_x = maxf(0.0, (size.x - layout_width) * 0.5)
	for index in range(count):
		var card = cards[index] as Control
		card.size = card_size
		if discard_layout:
			var column = int(index / cards_per_column)
			var row = index % cards_per_column
			card.position = Vector2(start_x + column * (card_size.x + gap), row * step)
			card.z_index = row
		else:
			card.position = Vector2(start_x + index * (card_size.x + gap),
				maxf(0.0, (size.y - card_size.y) * 0.5))
			card.z_index = index
