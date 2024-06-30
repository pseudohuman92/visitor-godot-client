extends Button


func _on_pressed():
	match name:
		"Save":
			save()
		"Load":
			load_()
		"New":
			GS.decklist = []
			GS.deck_name = "New Deck"
			GS.decklist_changed = true


func save():
	var file = FileAccess.open("user://"+GS.deck_name+".deck", FileAccess.WRITE)
	file.store_line(GS.deck_name)
	var i = 0
	while i < GS.decklist.size():
		var card = GS.decklist[i]
		var count = 0
		while i < GS.decklist.size() and card.get_name() == GS.decklist[i].get_name():
			i += 1
			count += 1
		file.store_line(str(count)+";"+card.get_set()+";"+GS.sanitize_card_name(card.get_name()))
	file.flush()
	file.close()

func load_():
	find_parent("DeckBuilder").find_child("LoadDeckDialog").set_visible(true)


func _on_file_dialog_file_selected(path):
	print(path)
	GS.decklist = []
	var file = FileAccess.open(path, FileAccess.READ)
	GS.deck_name = file.get_line()
	find_parent("DeckBuilder").find_child("DeckName").update()
	while !file.eof_reached():
		var line = file.get_line();
		var count = line.substr(0, line.find(";")).to_int()
		var rest = line.substr(line.find(";")+1)
		var set_ = rest.substr(0, rest.find(";"))
		var cardname = rest.substr(rest.find(";")+1)
		for card in GS.collection:
			if set_ == card.get_set() and cardname == GS.sanitize_card_name(card.get_name()):
				for i in count:
					GS.decklist.append(card)
	file.close()
	GS.decklist_changed = true
