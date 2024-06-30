extends VBoxContainer

var children = []
# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(cost, knowledge):
		children.map(func (c):remove_child(c))
		#get_children().map(func (c):c.set_visible(false))
		if cost:
			find_child("CostBG").set_visible(true)
			find_child("Cost").set_text(cost)

		for k in knowledge:
			var ks = CS.to_knowledge_string(k.get_knowledge())
			for i in k.get_count():
				var c = find_child(ks+"BG", false).duplicate()
				c.set_visible(true)
				#c.find_child(ks+"Label").set_text("")
				children.append(c)
				add_child(c)

		set_visible(true)
