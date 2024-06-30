extends VBoxContainer

func populate(cards):
	clear()
	var i = 0
	while i < cards.size():
		var card = cards[i]
		var count = 0
		while i < cards.size() and card.get_name() == cards[i].get_name():
			i += 1
			count += 1
		var c = GS.DecklistCardScene.instantiate()
		c.setup(card, count)
		add_child(c)

func clear():
	get_children().map(func(c):remove_child(c))

func _process(delta):
	if GS.decklist_changed:
		populate(GS.decklist)
		find_parent("DeckBuilder").find_child("DeckName").update()
		GS.decklist_changed = false
