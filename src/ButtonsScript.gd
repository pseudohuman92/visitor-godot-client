extends Button

func _process(_delta):
	set_disabled(GlobalState.is_waiting)
	match name:
		"Keep":
			set_visible(GlobalState.gameState and GlobalState.gameState.get_phase() == GlobalState.Types.Phase.REDRAW)
		"Redraw":
			set_visible(GlobalState.gameState and GlobalState.gameState.get_phase() == GlobalState.Types.Phase.REDRAW)
		"Pass":
			set_visible(GlobalState.has_initiative())
	
func _on_pressed():
	match name:
		"Keep":
			GlobalState.gameSocket.keep()
		"Redraw":
			GlobalState.gameSocket.redraw()
		"Pass":
			GlobalState.gameSocket.pass_()
