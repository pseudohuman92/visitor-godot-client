extends Button

func _on_file_dialog_file_selected(path):
	# The menu connects this dialog once; the clicked button already set queue_type.
	if not is_inside_tree():
		return
	var result = CS.read_deck_file(path)
	if result.has("error"):
		CS.show_error(result.error)
		return
	GS.game_decklist = result.lines
	get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")

func _on_pressed():
	SFX.play(&"ui_confirm")
	print("Click")
	match name:
		"DeckBuilder":
			get_tree().change_scene_to_file("res://src/DeckBuilder/DeckBuilder.tscn")
		"LearnToPlay":
			get_tree().change_scene_to_file("res://src/Tutorial/Tutorial.tscn")
		"PlayDraft":
			GS.queue_type = GS.Types.GameType.P2_DRAFT
			get_tree().change_scene_to_file("res://src/Draft/Draft.tscn")
		"PlayDraftAI":
			GS.queue_type = GS.Types.GameType.AI_DRAFT
			get_tree().change_scene_to_file("res://src/Draft/Draft.tscn")
		"PlayMulti":
			GS.queue_type = GS.Types.GameType.BO1_CONSTRUCTED
			_show_deck_dialog()
		"PlayAI":
			GS.queue_type = GS.Types.GameType.AI_BO1_CONSTRUCTED
			_show_deck_dialog()
		"PlayAIVsAI":
			GS.queue_type = GS.Types.GameType.AI_VS_AI
			_show_deck_dialog()
		"PlayTest":
			GS.game_decklist = GS.test_decklist.duplicate()
			GS.queue_type = GS.Types.GameType.BO1_CONSTRUCTED
			get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")

func _show_deck_dialog():
	var dialog = find_parent("MainMenu").find_child("FileDialog")
	if OS.has_feature("web"):
		# Browser file dialogs cannot browse the user's native filesystem. The
		# exported sample decks remain available through Godot's resource dialog.
		dialog.access = FileDialog.ACCESS_RESOURCES
		dialog.current_dir = "res://decks"
	else:
		var has_saved_deck := false
		for filename in DirAccess.get_files_at("user://"):
			if filename.get_extension().to_lower() == "deck":
				has_saved_deck = true
				break
		if not has_saved_deck:
			var prompt := ConfirmationDialog.new()
			prompt.title = "No saved decks"
			prompt.dialog_text = "Build and save a deck before starting a match."
			prompt.ok_button_text = "Open Deck Builder"
			prompt.cancel_button_text = "Back"
			find_parent("MainMenu").add_child(prompt)
			prompt.confirmed.connect(func(): get_tree().change_scene_to_file("res://src/DeckBuilder/DeckBuilder.tscn"))
			prompt.canceled.connect(prompt.queue_free)
			prompt.popup_centered()
			return
		dialog.access = FileDialog.ACCESS_USERDATA
		dialog.current_dir = "user://"
	dialog.clear_filters()
	dialog.add_filter("*.deck", "OMEN decks")
	dialog.show()
