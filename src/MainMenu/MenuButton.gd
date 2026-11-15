extends Button

func _on_file_dialog_file_selected(path):
	var result = CS.read_deck_file(path)
	if result.has("error"):
		CS.show_error(result.error)
		return
	GS.game_decklist = result.lines
	get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")

func _on_pressed():
	print("Click")
	match name:
		"DeckBuilder":
			get_tree().change_scene_to_file("res://src/DeckBuilder/DeckBuilder.tscn")
		"PlayMulti":
			GS.queue_type = GS.Types.GameType.BO1_CONSTRUCTED
			find_parent("MainMenu").find_child("FileDialog").set_visible(true)
		"PlayAI":
			GS.queue_type = GS.Types.GameType.AI_BO1_CONSTRUCTED
			find_parent("MainMenu").find_child("FileDialog").set_visible(true)
		"PlayTest":
			GS.game_decklist = GS.test_decklist.duplicate()
			GS.queue_type = GS.Types.GameType.BO1_CONSTRUCTED
			get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")
