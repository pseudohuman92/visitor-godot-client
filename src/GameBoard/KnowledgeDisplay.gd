extends HBoxContainer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GS.gameState:
		get_children().map(func (c):c.set_visible(false))
		if name.contains("KnowledgeSelection"):
			if SS.selecting_for == SS.selection_type.KNOWLEDGE:
				set_visible(true)
				SS.selection_message = "Select a knowledge to gain."
				SS.selection_targets.map(func(k):
					var cont = find_child(CS.to_knowledge_string(k)+"Container")
					cont.set_visible(true)
					var border = cont.get_theme_stylebox("panel").duplicate()
					border.set_border_color(Color.GREEN_YELLOW)
					cont.add_theme_stylebox_override("panel", border)
					find_child(CS.to_knowledge_string(k)+"Label").set_text(""))
			else:
				set_visible(false)
		else:
			var knowledge
			if name.contains("Player"):
				knowledge = GS.gameState.get_player().get_knowledgePool()
			if name.contains("Opponent"):
				knowledge = GS.gameState.get_opponent().get_knowledgePool()
			knowledge.map(func(k):
				var cont = find_child(CS.to_knowledge_string(k.get_knowledge())+"Container")
				cont.set_visible(true)
				var border = cont.get_theme_stylebox("panel").duplicate()
				border.set_border_color(Color.TRANSPARENT)
				cont.add_theme_stylebox_override("panel", border)
				find_child(CS.to_knowledge_string(k.get_knowledge())+"Label").set_text(str(k.get_count())))

