extends VBoxContainer

# Called only when the displayed player's energy/max-energy/health changes.
func update_player(player):
	var energy = "%d/%d" % [player.get_energy(), player.get_maxEnergy()] if player else "0/0"
	var health = str(player.get_health()) if player else "0"
	if find_child("EnergyLabel").text != energy:
		find_child("EnergyLabel").text = energy
	if find_child("HealthLabel").text != health:
		find_child("HealthLabel").text = health
