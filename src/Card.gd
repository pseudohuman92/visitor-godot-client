extends Control

class_name Card
var card
var initial_pos
var initial_size
var attacking = false

signal draw_target_arrows()
signal remove_target_arrows()

func setup(card=null):
	initial_pos = get_global_position()
	if card:
		self.card = card
		var image_box = find_child("CardImage").get_theme_stylebox("panel").duplicate()
		image_box.set_texture(GS.get_card_image(card.get_set(),card.get_name()))
		find_child("CardImage").add_theme_stylebox_override("panel", image_box)
		find_child("CostArea").update(card.get_cost(), card.get_knowledgeCost())
		find_child("Name").set_text(card.get_name())
		if card.get_types()[0] == "Spell" and card.get_subtypes() and card.get_subtypes()[0] == "Cantrip":
			find_child("TypeIcon").set_texture(GS.get_type_icon("Cantrip"))
		else:
			find_child("TypeIcon").set_texture(GS.get_type_icon(card.get_types()[0]))
		var ability_text = ""
		var combat = card.get_combat()
		if combat:
			find_child("Stats").set_visible(true)
			find_child("Stats").set_text(str(combat.get_attack())+" / "+str(combat.get_health()))
			if combat.get_combatAbilities():
				ability_text += GS.to_array_string(combat.get_combatAbilities()) + "\n"
		else:
			find_child("Stats").set_text("")
			find_child("StatsBG").set_visible(false)
		ability_text += card.get_description()
		if find_child("Ability"):
			if ability_text != "":
				find_child("Ability").set_visible(true)
				find_child("Ability").set_text_custom(ability_text, card.get_name())
			else:
				find_child("Ability").set_visible(false)
		set_name(card.get_id())
		set_unique_name_in_owner(true)
		if (GS.gameState.get_phase() == GS.Types.Phase.ATTACK_PLAY or \
			GS.gameState.get_phase() == GS.Types.Phase.BLOCK or \
			GS.gameState.get_phase() == GS.Types.Phase.BLOCK_PLAY) \
			and card.get_combat() and card.get_combat().get_attackTarget():
				z_index = 1
				set_rotation(PI/4)
		else:
			z_index = 0
			set_rotation(0)
	else:
		var image_box = find_child("CardImage").get_theme_stylebox("panel").duplicate()
		image_box.set_texture(load(GS.card_back_path))
		find_child("CardImage").add_theme_stylebox_override("panel", image_box)
		find_child("Contents").set_visible(false)

func set_border_color():
	if card:
		var border = find_child("InternalContainer").get_theme_stylebox("panel").duplicate()
		if GS.selected.has(card.get_id()):
			border.set_border_color(Color.RED)
		elif (!GS.is_selecting() and (card.get_canPlay() or card.get_canStudy() or \
		card.get_canActivate())) or card.get_canAttack() or \
		card.get_canBlock() or \
		(GS.is_selecting() and GS.selection_info and GS.selection_info.get_possibleTargets().has(card.get_id())):
			border.set_border_color(Color.GREEN_YELLOW)
		else:
			border.set_border_color(Color.WHITE_SMOKE)
		find_child("InternalContainer").add_theme_stylebox_override("panel", border)

func _get_drag_data(_at_position):
	if !card or GS.is_waiting or \
	GS.is_selecting() or \
	not (card.get_canPlay() or card.get_canStudy()):
		return null
	GS.is_dragging = true
	GS.dragged_card = self
	set_scale(Vector2(1,1))
	var copy = GS.CardScene.instantiate()
	if card:
		copy.setup(card)
	var prev = Control.new()
	prev.add_child(copy)
	copy.set_position(copy.get_position() - copy.get_size()/2)
	set_drag_preview(prev)
	set_visible(false)
	return self

func _on_mouse_entered():
	if !GS.is_dragging:
		#initial_pos = get_global_position()
		#set_scale(Vector2(1.5,1.5))
		#z_index = 1
		#var size = find_child("Border").get_size()
		#var pos = get_global_position()-size/3
		#set_global_position(Vector2(min(max(0, pos.x), 1820-size.x), min(max(0, pos.y), 930-size.y)))

		if card and card.get_targets():
			for c in card.get_targets():
				GS.arrow_targets.append([card.get_id(), c])
			draw_target_arrows.emit()
		#var parentName = get_parent().get_name()

		#if parentName.contains("Player"):
		#	set_position(Vector2(initial_pos.x, initial_pos.y - get_size().y))
		#elif parentName.contains("Stack"):
		#	set_position(Vector2(initial_pos.x - get_size().x/2, initial_pos.y))

func _on_mouse_exited():
	if !GS.is_dragging:
		#set_scale(Vector2(1,1))
		#z_index = 0
		#set_global_position(initial_pos)
		if card and card.get_targets():
			remove_target_arrows.emit()
		#set_position(initial_pos)

func _process(delta):
	set_border_color()
	if card:
		if (GS.gameState.get_phase() == GS.Types.Phase.ATTACK_PLAY or \
			GS.gameState.get_phase() == GS.Types.Phase.BLOCK or \
			GS.gameState.get_phase() == GS.Types.Phase.BLOCK_PLAY) \
			and card.get_combat() and card.get_combat().get_attackTarget()\
			and !attacking:
				attacking = true
				set_position(get_position()-Vector2(0, 20))
		elif GS.gameState.get_phase() != GS.Types.Phase.ATTACK_PLAY and \
			GS.gameState.get_phase() != GS.Types.Phase.BLOCK and \
			GS.gameState.get_phase() != GS.Types.Phase.BLOCK_PLAY \
			and attacking:
			set_position(get_position()+Vector2(0, 20))
			attacking = false

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if card:
				if GS.is_selecting() and \
				((GS.selection_info and GS.selection_info.get_possibleTargets().has(card.get_id())) or \
				card.get_canAttack() or \
				card.get_canBlock()):
					if GS.selected.has(card.get_id()):
						GS.selected.erase(card.get_id())
					else:
						GS.selected.append(card.get_id())
				elif card.get_canActivate():
					var activated_abilities = card.get_activateTargets()
					if activated_abilities.size() == 1:
						var targets = activated_abilities[0];
						GS.selection_info = targets
						GS.selected = []
						if targets.get_maxTargets() == 0:
							GS.gameSocket.activate_card(card.get_id())
						elif targets.get_minTargets() == targets.get_possibleTargets().size():
							GS.selected = targets.get_possibleTargets()
							GS.gameSocket.activate_card(card.get_id())
						else:
							GS.targeting_type = GS.targeting_for.ACTIVATE
							GS.targeting_card = card
					else:
						GS.popup_message = "Select and ability to activate."
						GS.ability_selection_popup = true
						for ability in activated_abilities:
							var c = GS.AbilityCardScene.instantiate()
							c.setup(card, ability)
							GS.popup_cards.append(c)
						#create Cards for popup
