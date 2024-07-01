extends LineEdit

func _on_text_changed(new_text):
	find_parent("MainContainer").find_child("Collection").filter_text = new_text
	find_parent("MainContainer").find_child("Collection").populate()
