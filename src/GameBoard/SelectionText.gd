extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var message = GS.connection_error if not GS.connection_error.is_empty() else SS.selection_message
	if text != message:
		text = message
	visible = not message.is_empty()
