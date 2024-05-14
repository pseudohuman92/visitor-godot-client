extends Control

var card
var initial_pos

func to_knowledge_string(knowledge):
	var s = ""
	for knw in knowledge:
		var label = ""
		match knw.get_knowledge():
			GlobalState.Types.Knowledge.BLUE:
				label = "B"
			GlobalState.Types.Knowledge.GREEN:
				label = "G"
			GlobalState.Types.Knowledge.RED:
				label = "R"
			GlobalState.Types.Knowledge.PURPLE:
				label = "P"
			GlobalState.Types.Knowledge.YELLOW:
				label = "Y"
				
		var count = knw.get_count()
		for i in count:
			s += label
	return s

func to_array_string(arr, sep = " "):
	var res = ""
	for s in arr:
		res += s + sep 
	return res
	
	
	
func setup(card):
	self.card = card
	find_child("Cost").set_text(card.get_cost()+" - "+to_knowledge_string(card.get_knowledgeCost()))
	find_child("Name").set_text(card.get_name())
	find_child("Type").set_text(to_array_string(card.get_types())+"- "+to_array_string(card.get_subtypes()))
	var ability_text = "" 
	var combat = card.get_combat()
	if combat:
		find_child("Stats").set_text(str(combat.get_attack())+" / "+str(combat.get_health()))
		ability_text += to_array_string(combat.get_combatAbilities()) + "\n"
	ability_text += card.get_description()
	find_child("Ability").set_text(ability_text)
	set_name(card.get_id())
	set_unique_name_in_owner(true)

func _get_drag_data(at_position):
	if GlobalState.is_waiting or \
	not (card.get_canPlay() or card.get_canStudy()):
		return null
	GlobalState.is_dragging = true
	var copy = self.duplicate()
	var prev = Control.new()
	prev.add_child(copy)
	copy.set_position(copy.get_position() - copy.get_size()/2)
	set_drag_preview(prev)
	#set_visible(false)
	return self

func _on_mouse_entered():
	if !GlobalState.is_dragging:
		set_scale(Vector2(2,2))
		initial_pos = get_position()
		var parentName = get_parent().get_name()
		if parentName.contains("Player"):
			set_position(Vector2(initial_pos.x, initial_pos.y - get_size().y))
		elif parentName.contains("Stack"):
			set_position(Vector2(initial_pos.x - get_size().x/2, initial_pos.y))

func _on_mouse_exited():
	if !GlobalState.is_dragging:
		set_scale(Vector2(1,1))
		set_position(initial_pos)
