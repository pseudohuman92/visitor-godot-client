extends VBoxContainer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(cost, knowledge):
		get_children().map(func (c):c.set_visible(false))
		var at_least_one = false
		if cost:
			find_child("CostBG").set_visible(true)
			find_child("Cost").set_text(cost)
			at_least_one = true
		for k in knowledge:
			match k.get_knowledge():
				GS.Types.Knowledge.BLUE:
					find_child("BlueKnowledgeBG", false).set_visible(true)
					find_child("BlueKnowledgeLabel").set_text(str(k.get_count()))
					at_least_one = true
				GS.Types.Knowledge.GREEN:
					find_child("GreenKnowledgeBG", false).set_visible(true)
					find_child("GreenKnowledgeLabel").set_text(str(k.get_count()))
					at_least_one = true
				GS.Types.Knowledge.PURPLE:
					find_child("PurpleKnowledgeBG", false).set_visible(true)
					find_child("PurpleKnowledgeLabel").set_text(str(k.get_count()))
					at_least_one = true
				GS.Types.Knowledge.RED:
					find_child("RedKnowledgeBG", false).set_visible(true)
					find_child("RedKnowledgeLabel").set_text(str(k.get_count()))
					at_least_one = true
				GS.Types.Knowledge.YELLOW:
					find_child("YellowKnowledgeBG", false).set_visible(true)
					find_child("YellowKnowledgeLabel").set_text(str(k.get_count()))
					at_least_one = true
		set_visible(at_least_one)
