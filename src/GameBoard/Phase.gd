extends Label

func _process(_delta):
	if GS.gameState:
		var phase = GS.get_phase_name()
		if text != phase:
			text = phase
