extends Control

class_name Card
var card
var initial_size
var blocking = false
var blocked = false
var display = false
var hover = false

signal draw_target_arrows()
signal remove_target_arrows()

func setup(card=null, square=false):
	CS.setup_card(self, card)

func get_border_color():
	if card:
		if SS.is_selecting():
			match GS.gameState.get_phase():
				GS.Types.Phase.ATTACK:
					if SS.selected_single.has(card.get_id()):
						return Color.DARK_RED
					elif card.get_canAttack():
						return Color.DARK_GREEN

				GS.Types.Phase.BLOCK:
					if blocking:
						return Color.NAVY_BLUE
					elif blocked:
						return Color.YELLOW
					elif (!SS.selecting_card and card.get_canBlock()) \
					or SS.selection_targets.has(card.get_id()):
						return Color.DARK_GREEN

			if SS.selected_single.has(card.get_id()):
				return Color.GREEN_YELLOW
			elif SS.selection_targets.has(card.get_id()):
				return Color.DARK_GREEN

		if !SS.is_selecting() and card.get_controller() == GS.playerId \
		and (card.get_canPlay() or card.get_canStudy() or card.get_canActivate()):
			return Color.DARK_GREEN

		if card.get_combat() and card.get_combat().get_attackTarget():
			return Color.DARK_RED
		elif card.get_combat() and card.get_combat().get_blockedAttacker():
			return Color.NAVY_BLUE

	return Color.WHITE_SMOKE

func set_border_color(color):
		var border = get_theme_stylebox("panel").duplicate()
		border.set_border_color(color)
		add_theme_stylebox_override("panel", border)

func _get_drag_data(_at_position):
	if !card or GS.is_waiting or \
	SS.is_selecting() or \
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
	set_drag_preview(prev)
	return self

func _on_mouse_entered():
	if !GS.is_dragging:
		if card and card.get_targets():
			for c in card.get_targets():
				GS.arrow_targets.append([card.get_id(), c])
			draw_target_arrows.emit()
		hover = true
		set_border_color(Color.DARK_GOLDENROD)


func _on_mouse_exited():
	if !GS.is_dragging:
		if (card and card.get_targets()):
			remove_target_arrows.emit()
		hover = false

func _process(delta):
	if !display and !hover:
		set_border_color(get_border_color())


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if card:
				if SS.is_selecting():
					if (SS.selection_targets.has(card.get_id()) and GS.gameState.get_phase() != GS.Types.Phase.BLOCK) or \
					(GS.gameState.get_phase() == GS.Types.Phase.ATTACK and card.get_canAttack()):
						if SS.selected_single.has(card.get_id()):
							SS.selected_single.erase(card.get_id())
						else:
							SS.selected_single.append(card.get_id())
							SS.check_smart_select()

					elif GS.gameState.get_phase() == GS.Types.Phase.BLOCK :
						if !SS.selecting_card:
							if blocking:
								var cards = SS.selected[card.get_id()]
								SS.selected.erase(card.get_id())
								GS.block_arrow_targets.erase(card.get_id())
								blocking = false
								cards[1].blocked = false
								print ("Block arrow removed")
								print (GS.block_arrow_targets)
								remove_target_arrows.emit(true)
								draw_target_arrows.emit(true)
							elif !blocking and card.get_combat() \
							and card.get_combat().get_possibleBlockTargets():
								SS.selecting_card = self;
								SS.selection_targets = card.get_combat().get_possibleBlockTargets()
						else:
							if SS.selection_targets.has(card.get_id()) and !blocked:
								SS.selecting_card.blocking = true
								SS.selected[SS.selecting_card.card.get_id()] = [SS.selecting_card, self]
								GS.block_arrow_targets[SS.selecting_card.card.get_id()] = [SS.selecting_card.card.get_id(), card.get_id()]
								blocked = true
								SS.selecting_card = null
								SS.selection_targets = []
								print ("Block arrow added")
								print (GS.block_arrow_targets)
								remove_target_arrows.emit(true)
								draw_target_arrows.emit(true)
							elif SS.selecting_card == self:
								SS.selecting_card = null;
								SS.selection_targets = []

				elif GS.has_initiative() and card.get_canActivate():
					var activated_abilities = card.get_activateTargets()
					if activated_abilities.size() == 1:
						SS.process_selections(activated_abilities[0].get_targets(), card, GS.gameSocket.activate_card, SS.selection_type.ACTIVATE, activated_abilities[0].get_id())
					else:
						GS.popup_message = "Select and ability to activate."
						GS.ability_selection_popup = true
						for ability in activated_abilities:
							var c = GS.AbilityCardScene.instantiate()
							c.setup(card, ability)
							GS.popup_cards.append(c)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if card:
				var parent = find_parent("GameBoard")
				if GS.bigger_popup:
					parent.remove_child(GS.bigger_popup)
				GS.bigger_popup = GS.CardScene.instantiate()
				GS.bigger_popup.setup(card)
				GS.bigger_popup.z_index = z_index + 1
				GS.bigger_popup.set_scale(Vector2(2,2))
				GS.bigger_popup.set_global_position(Vector2(0,0))
				GS.bigger_popup.find_child("InternalContainer").display=true
				parent.add_child(GS.bigger_popup)

		if event.is_released():
			if GS.bigger_popup:
				var parent = find_parent("GameBoard")
				parent.remove_child(GS.bigger_popup)
