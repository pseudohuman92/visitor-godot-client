extends LineEdit

func _on_text_changed(new_text):
	var collection = find_parent("MainContainer").find_child("Collection")
	collection.filter_text = new_text.strip_edges()
	collection.page = 0
	collection.populate()
