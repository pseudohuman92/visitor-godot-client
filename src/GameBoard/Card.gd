extends Control

class_name Card
var card
var initial_size
var attacking = false
var block_index = -1
var blocked = false
var display = false
var hover = false

signal draw_target_arrows()
signal remove_target_arrows()

func setup(card=null, x=null):
	CS.setup_card(self, card)

func set_border_color():
	if card:
		var border = get_theme_stylebox("panel").duplicate()
		match GS.gameState.get_phase():
			GS.Types.Phase.MAIN_BEFORE, GS.Types.Phase.ATTACK_PLAY, GS.Types.Phase.BLOCK_PLAY, GS.Types.Phase.MAIN_AFTER, GS.Types.Phase.END:
				if SS.is_selecting():
					if SS.selected_single.has(card.get_id()):
						border.set_border_color(Color.GREEN_YELLOW)
					elif SS.selection_targets.has(card.get_id()):
						border.set_border_color(Color.DARK_GREEN)
					else:
						border.set_border_color(Color.WHITE_SMOKE)
				else:
					if get_parent().get_parent().get_parent().name.contains("Player") and (card.get_canPlay() or card.get_canStudy() or card.get_canActivate()):
						border.set_border_color(Color.DARK_GREEN)
					else:
						border.set_border_color(Color.WHITE_SMOKE)
			GS.Types.Phase.ATTACK:
				if SS.is_selecting():
					if SS.selected_single.has(card.get_id()):
						border.set_border_color(Color.DARK_RED)
					elif card.get_canAttack():
						border.set_border_color(Color.DARK_GREEN)
					else:
						border.set_border_color(Color.WHITE_SMOKE)
				else:
					border.set_border_color(Color.WHITE_SMOKE)
			GS.Types.Phase.BLOCK:
				if SS.is_selecting():
					if block_index > -1:
						border.set_border_color(Color.NAVY_BLUE)
					elif blocked:
						border.set_border_color(Color.YELLOW)
					elif (!SS.selecting_card and card.get_canBlock()) \
					or SS.selection_targets.has(card.get_id()):
						border.set_border_color(Color.DARK_GREEN)
					else:
						border.set_border_color(Color.WHITE_SMOKE)
				else:
					border.set_border_color(Color.WHITE_SMOKE)
			GS.Types.Phase.REDRAW, GS.Types.Phase.BEGIN, GS.Types.Phase.END:
				border.set_border_color(Color.WHITE_SMOKE)
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
	#set_visible(false)
	return self

func _on_mouse_entered():
	if !GS.is_dragging:
		if card and card.get_targets():
			for c in card.get_targets():
				GS.arrow_targets.append([card.get_id(), c])
			if block_index > -1:
				SS.selected[block_index]
				GS.arrow_targets.append([card.get_id(), SS.selected[block_index][1].card.get_id()])
			draw_target_arrows.emit()
		hover = true
		var border = get_theme_stylebox("panel").duplicate()
		border.set_border_color(Color.DARK_GOLDENROD)
		add_theme_stylebox_override("panel", border)


func _on_mouse_exited():
	if !GS.is_dragging:
		if (card and card.get_targets()) or block_index > 1:
			remove_target_arrows.emit()
		hover = false

func _process(delta):
	if !display:
		if !hover:
			set_border_color()
		if card:
			if (GS.gameState.get_phase() == GS.Types.Phase.ATTACK_PLAY or \
				GS.gameState.get_phase() == GS.Types.Phase.BLOCK or \
				GS.gameState.get_phase() == GS.Types.Phase.BLOCK_PLAY) \
				and card.get_combat() and card.get_combat().get_attackTarget()\
				and !attacking:
					attacking = true
					#set_position(get_position()-Vector2(0, 20))
					set_rotation(PI/8)
					set_scale(Vector2(0.707, 0.707))
			elif GS.gameState.get_phase() != GS.Types.Phase.ATTACK_PLAY and \
				GS.gameState.get_phase() != GS.Types.Phase.BLOCK and \
				GS.gameState.get_phase() != GS.Types.Phase.BLOCK_PLAY \
				and attacking:
				#set_position(get_position()+Vector2(0, 20))
				set_scale(Vector2(1, 1))
				set_rotation(0)
				attacking = false

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if card:
				if SS.is_selecting():
					if SS.selection_targets.has(card.get_id()) or \
					(GS.gameState.get_phase() == GS.Types.Phase.ATTACK and card.get_canAttack()):
						if SS.selected_single.has(card.get_id()):
							SS.selected_single.erase(card.get_id())
						else:
							SS.selected_single.append(card.get_id())
							#SS.print_selection_state()
							SS.check_smart_select()

					elif GS.gameState.get_phase() == GS.Types.Phase.BLOCK :
						if !SS.selecting_card:
							if block_index > -1:
								var cards = SS.selected[block_index]
								SS.selected.remove_at(block_index)
								block_index = -1
								cards[1].blocked = false
							elif block_index <= -1 and card.get_combat() \
							and card.get_combat().get_possibleBlockTargets():
								SS.selecting_card = self;
								SS.selection_targets = card.get_combat().get_possibleBlockTargets()
						else:
							if SS.selection_targets.has(card.get_id()) and !blocked:
								SS.selecting_card.block_index = SS.selected.size()
								SS.selected.append([GS.blocking_card, self])
								blocked = true
								SS.selecting_card = null
								SS.selection_targets = []
							elif SS.selecting_card == self:
								SS.selecting_card = null;
								SS.selection_targets = []

				elif GS.has_initiative() and card.get_canActivate():
					print_debug("Activating " + card.get_name())
					var activated_abilities = card.get_activateTargets()
					if activated_abilities.size() == 1:
						print_debug("Single Ability")
						SS.process_selections(activated_abilities[0].get_targets(), card, GS.gameSocket.activate_card, SS.selection_type.ACTIVATE, activated_abilities[0].get_id())
					else:
						print_debug("Multi Abilities, setting up popup")
						GS.popup_message = "Select and ability to activate."
						GS.ability_selection_popup = true
						for ability in activated_abilities:
							var c = GS.AbilityCardScene.instantiate()
							c.setup(card, ability)
							GS.popup_cards.append(c)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if card:
				print("Right click!")
				var parent = find_parent("GameBoard")
				if GS.bigger_popup:
					parent.remove_child(GS.bigger_popup)
				GS.bigger_popup = GS.CardScene.instantiate()
				GS.bigger_popup.setup(card)
				parent.add_child(GS.bigger_popup)
				GS.bigger_popup.z_index = z_index + 1
				GS.bigger_popup.set_scale(Vector2(2,2))
				GS.bigger_popup.set_position(Vector2(0,0))
				GS.bigger_popup.find_child("InternalContainer").display=true

		if event.is_released():
			if GS.bigger_popup:
				var parent = find_parent("GameBoard")
				parent.remove_child(GS.bigger_popup)


