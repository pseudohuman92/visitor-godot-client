extends TextureRect

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GS.gameState:
		if GS.gameState.get_player().get_id() == GS.gameState.get_activePlayer():
			set_rotation(PI/4)
		elif GS.gameState.get_opponent().get_id() == GS.gameState.get_activePlayer():
			set_rotation(-PI/4)
