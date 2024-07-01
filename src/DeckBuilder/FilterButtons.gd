extends TextureButton

func C_filter(card):
	return card.get_knowledgeCost().size() != 0

func B_filter(card):
	for k in card.get_knowledgeCost():
		if k.get_knowledge() == GS.Types.Knowledge.BLUE:
			return false
	return true
func G_filter(card):
	for k in card.get_knowledgeCost():
		if k.get_knowledge() == GS.Types.Knowledge.GREEN:
			return false
	return true

func P_filter(card):
	for k in card.get_knowledgeCost():
		if k.get_knowledge() == GS.Types.Knowledge.PURPLE:
			return false
	return true

func R_filter(card):
	for k in card.get_knowledgeCost():
		if k.get_knowledge() == GS.Types.Knowledge.RED:
			return false
	return true

func Y_filter(card):
	for k in card.get_knowledgeCost():
		if k.get_knowledge() == GS.Types.Knowledge.YELLOW:
			return false
	return true

func unit_filter(card):
	return not card.get_types().has("Unit")

func ritual_filter(card):
	return not(card.get_types().has("Spell") and card.get_subtypes().has("Ritual"))

func cantrip_filter(card):
	return not(card.get_types().has("Spell") and card.get_subtypes().has("Cantrip"))

func tome_filter(card):
	return not card.get_types().has("Tome")

func asset_filter(card):
	return not card.get_types().has("Asset")



func _on_toggled(toggled_on):
	var coll = find_parent("MainContainer").find_child("Collection")
	if toggled_on:
		match name:
			"C":
				coll.filters.append(C_filter)
			"B":
				coll.filters.append(B_filter)
			"G":
				coll.filters.append(G_filter)
			"P":
				coll.filters.append(P_filter)
			"R":
				coll.filters.append(R_filter)
			"Y":
				coll.filters.append(Y_filter)
			"Unit":
				coll.filters.append(unit_filter)
			"Ritual":
				coll.filters.append(ritual_filter)
			"Cantrip":
				coll.filters.append(cantrip_filter)
			"Asset":
				coll.filters.append(asset_filter)
			"Tome":
				coll.filters.append(tome_filter)
		find_child("Panel").set_visible(true)
	else:
		match name:
			"C":
				coll.filters.erase(C_filter)
			"B":
				coll.filters.erase(B_filter)
			"G":
				coll.filters.erase(G_filter)
			"P":
				coll.filters.erase(P_filter)
			"R":
				coll.filters.erase(R_filter)
			"Y":
				coll.filters.erase(Y_filter)
			"Unit":
				coll.filters.erase(unit_filter)
			"Ritual":
				coll.filters.erase(ritual_filter)
			"Cantrip":
				coll.filters.erase(cantrip_filter)
			"Asset":
				coll.filters.erase(asset_filter)
			"Tome":
				coll.filters.erase(tome_filter)
		find_child("Panel").set_visible(false)
	coll.populate()
