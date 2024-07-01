extends Button

func _on_file_dialog_file_selected(path):
	print(path)
	GS.game_decklist = []
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_line() #Skip deck name
	while !file.eof_reached():
		var line = file.get_line()
		if line:
			GS.game_decklist.append(line)
	file.close()
	print(GS.game_decklist)
	get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")

func _on_pressed():
	print("Click")
	match name:
		"DeckBuilder":
			get_tree().change_scene_to_file("res://src/DeckBuilder/DeckBuilder.tscn")
		"Play":
			find_parent("MainMenu").find_child("FileDialog").set_visible(true)

