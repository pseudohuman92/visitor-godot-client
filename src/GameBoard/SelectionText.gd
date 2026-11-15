extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		set_text(GS.connection_error if not GS.connection_error.is_empty() else SS.selection_message)
