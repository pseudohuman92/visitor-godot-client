extends Container

var page = 0
var max_page = 0
var card_count = 32
var filters = []
var filter_text = ""

func contains_text(card):
	return card.get_name().contains(filter_text) or card.get_description().contains(filter_text)

func populate():
	clear()
	var coll = GS.collection
	print(coll)
	for f in filters:
		coll = coll.filter(f)
	if filter_text:
		coll = coll.filter(contains_text)
	max_page = maxi(0, ceili(float(coll.size()) / card_count) - 1)
	page = clampi(page, 0, max_page)
	for card in coll.slice(page*card_count, (page+1)*card_count):
		var c = GS.CollectionCardScene.instantiate()
		c.setup(card)
		add_child(c)

func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()
