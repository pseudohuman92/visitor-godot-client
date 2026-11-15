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
	var deck_name = GS.deck_name.strip_edges().replace("\n", " ").replace("\r", " ")
	if deck_name.is_empty():
		CS.show_error("Enter a deck name before saving.")
		return
	var path = "user://" + deck_name.validate_filename() + ".deck"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		CS.show_error("Could not save deck: " + error_string(FileAccess.get_open_error()))
		return
	file.store_line(deck_name)
	var counts = {}
	for card in GS.decklist:
		var key = card.get_set() + "." + CS.sanitize_card_name(card.get_name())
		counts[key] = counts.get(key, 0) + 1
	for key in counts:
		file.store_line(str(counts[key]) + ";" + key)
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK:
		CS.show_error("Could not finish saving deck: " + error_string(error))

func load_():
	find_parent("DeckBuilder").find_child("LoadDeckDialog").show()

func _on_file_dialog_file_selected(path):
	var result = CS.read_deck_file(path)
	if result.has("error"):
		CS.show_error(result.error)
		return
	var cards = []
	for entry in result.entries:
		var match_card = null
		for card in GS.collection:
			if card.get_set() == entry.set and CS.sanitize_card_name(card.get_name()) == entry.card:
				match_card = card
				break
		if match_card == null:
			CS.show_error("Card not found in your collection: " + entry.set + "." + entry.card)
			return
		for i in entry.count:
			cards.append(match_card)
	cards.sort_custom(CS.compare_cost_name_cardP)
	GS.decklist = cards
	GS.deck_name = result.name
	GS.decklist_changed = true
