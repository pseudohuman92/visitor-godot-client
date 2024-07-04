extends Container

func populate(cards, square=false, setup=true):
	if GS.gameState:
		clear()
		if name == "Stack":
			cards.reverse()
		for card in cards:
			var c
			if square:
				c = GS.SquareCardScene.instantiate()
			else:
				c = GS.CardScene.instantiate()
			if setup:
				c.setup(card, square)
			else:
				c.setup()
			add_child(c)

func clear():
	get_children().map(func(c):remove_child(c))
