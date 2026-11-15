extends VBoxContainer

func populate(cards):
	clear()
	var i = 0
	while i < cards.size():
		var card = cards[i]
		var count = 0
		while i < cards.size() and card.get_name() == cards[i].get_name() and card.get_set() == cards[i].get_set():
			i += 1
			count += 1
		var c = GS.DecklistCardScene.instantiate()
		c.setup(card, count)
		add_child(c)

func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _process(delta):
	if GS.decklist_changed:
		populate(GS.decklist)
		find_parent("DeckBuilder").find_child("DeckName").update()
		GS.decklist_changed = false
