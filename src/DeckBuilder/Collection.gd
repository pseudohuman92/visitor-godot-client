extends Container

var page = 0
var max_page = 0
var card_count = 32
var filters = []

func populate():
	clear()
	var coll = GS.collection
	for f in filters:
		coll = coll.filter(f)
	max_page = int(coll.size()/card_count)
	page = min(page, max_page)
	for card in coll.slice(page*card_count, (page+1)*card_count):
		var c = GS.CollectionCardScene.instantiate()
		c.setup(card)
		add_child(c)

func clear():
	get_children().map(func(c):remove_child(c))
