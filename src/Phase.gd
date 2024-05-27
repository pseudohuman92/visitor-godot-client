extends Label

func _process(delta):
	if GS.gameState:
		set_text(GS.get_phase_name())
