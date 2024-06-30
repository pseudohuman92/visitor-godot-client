extends HBoxContainer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GS.gameState:
		var energy
		var maxEnergy
		var health
		if name.contains("Player"):
			find_child("EnergyLabel").set_text( \
				str (GS.gameState.get_player().get_energy()) + "/" + \
				str(GS.gameState.get_player().get_maxEnergy()))
			find_child("HealthLabel").set_text(str(GS.gameState.get_player().get_health()))
		if name.contains("Opponent"):
			find_child("EnergyLabel").set_text( \
				str (GS.gameState.get_opponent().get_energy()) + "/" + \
				str(GS.gameState.get_opponent().get_maxEnergy()))
			find_child("HealthLabel").set_text(str(GS.gameState.get_opponent().get_health()))
