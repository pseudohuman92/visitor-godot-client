extends Button

func _process(_delta):
	var coll = find_parent("CollectionContainer").find_child("Collection")
	match name:
		"<":
			set_disabled(coll.page == 0)
		">":
			set_disabled(coll.page == coll.max_page)

func _on_pressed():
	var coll = find_parent("CollectionContainer").find_child("Collection")
	match name:
		"<":
			coll.page -= 1
		">":
			coll.page += 1
	coll.populate()

