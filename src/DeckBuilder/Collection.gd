extends GridContainer

var page = 0
var max_page = 0
var card_count = 32
var filters = []
var filter_text = ""

func _ready():
	_update_grid_density()
	get_window().size_changed.connect(_update_grid_density)

func _update_grid_density():
	var compact = get_window().size.x < 1600 or get_window().size.y < 900
	var next_columns = 6 if compact else 8
	var next_card_count = 18 if compact else 32
	if columns == next_columns and card_count == next_card_count:
		return
	columns = next_columns
	card_count = next_card_count
	if not GS.collection.is_empty():
		populate()

func contains_text(card):
	var query = filter_text.to_lower()
	return card.get_name().to_lower().contains(query) or card.get_description().to_lower().contains(query)

func populate():
	clear()
	var coll = GS.collection
	for f in filters:
		coll = coll.filter(f)
	if filter_text:
		coll = coll.filter(contains_text)
	max_page = maxi(0, ceili(float(coll.size()) / card_count) - 1)
	page = clampi(page, 0, max_page)
	var empty_state = get_parent().get_node_or_null("EmptyState") if get_parent() else null
	if empty_state:
		empty_state.visible = coll.is_empty()
		empty_state.text = "No cards found. Clear search or filters." if filter_text or not filters.is_empty() else "No cards available."
	for card in coll.slice(page*card_count, (page+1)*card_count):
		var c = GS.CollectionCardScene.instantiate()
		c.setup(card)
		add_child(c)

func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()
