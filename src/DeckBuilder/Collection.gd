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
	for f in filters:
		coll = coll.filter(f)
	if filter_text:
		coll = coll.filter(contains_text)
	max_page = int(coll.size()/card_count)
	page = min(page, max_page)
	for card in coll.slice(page*card_count, (page+1)*card_count):
		var c = GS.CollectionCardScene.instantiate()
		c.setup(card)
		add_child(c)

func clear():
	get_children().map(func(c):remove_child(c))
