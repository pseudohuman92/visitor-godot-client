extends VBoxContainer

func _can_drop_data(at_position, data):
	return true
	
func _drop_data(at_position, data):
	print("Dropped to Play Area: ", data.card.get_id())
	data.set_visible(true)
	GlobalState.is_dragging = false

