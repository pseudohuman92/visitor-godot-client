extends HBoxContainer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GS.gameState:
		get_children().map(func (c):c.set_visible(false))
		var knowledge
		if name.contains("Player"):
			knowledge = GS.gameState.get_player().get_knowledgePool()
		if name.contains("Opponent"):
			knowledge = GS.gameState.get_opponent().get_knowledgePool()
		for k in knowledge:
			match k.get_knowledge():
				GS.Types.Knowledge.BLUE:
					find_child("BlueKnowledgeBG", false).set_visible(true)
					find_child("BlueKnowledgeLabel").set_text(str(k.get_count()))
				GS.Types.Knowledge.GREEN:
					find_child("GreenKnowledgeBG", false).set_visible(true)
					find_child("GreenKnowledgeLabel").set_text(str(k.get_count()))
				GS.Types.Knowledge.PURPLE:
					find_child("PurpleKnowledgeBG", false).set_visible(true)
					find_child("PurpleKnowledgeLabel").set_text(str(k.get_count()))
				GS.Types.Knowledge.RED:
					find_child("RedKnowledgeBG", false).set_visible(true)
					find_child("RedKnowledgeLabel").set_text(str(k.get_count()))
				GS.Types.Knowledge.YELLOW:
					find_child("YellowKnowledgeBG", false).set_visible(true)
					find_child("YellowKnowledgeLabel").set_text(str(k.get_count()))
