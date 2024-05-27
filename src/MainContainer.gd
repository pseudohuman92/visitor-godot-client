extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	set_size(get_viewport_rect().size)


func _can_drop_data(at_position, data):
	return true

func _drop_data(at_position, data):
	if data.card:
		print("Dropped to " + get_name() + ": ", data.card.get_id())
		#data.set_visible(true)
		GS.is_dragging = false
		GS.dragged_card = null
		data.set_visible(true)

