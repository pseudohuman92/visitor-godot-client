extends Button

func _process(_delta):
	set_disabled(GS.is_waiting)
	match name:
		"Keep":
			set_visible(GS.gameState and GS.gameState.get_phase() == GS.Types.Phase.REDRAW)
		"Redraw":
			set_visible(GS.gameState and GS.gameState.get_phase() == GS.Types.Phase.REDRAW)
		"Pass":
			set_visible(GS.has_initiative() and not GS.is_selecting() and not GS.popup_cards)
		"Submit":
			set_visible(GS.is_selecting())
			set_disabled(GS.selection_info and \
			(GS.selected.size() < GS.selection_info.get_minTargets() \
			or GS.selected.size() > GS.selection_info.get_maxTargets()))
		"Cancel":
			set_visible((GS.is_selecting() and (GS.targeting_type == GS.targeting_for.PLAY or GS.targeting_type == GS.targeting_for.ACTIVATE)))
		"Close":
			set_visible(!GS.is_selecting() and GS.popup_cards)
		"All Attack":
			set_visible(GS.is_selecting() and \
			GS.gameState.get_phase() == GS.Types.Phase.ATTACK)

func _on_pressed():
	match name:
		"Keep":
			GS.gameSocket.keep()
		"Redraw":
			GS.gameSocket.redraw()
		"Pass":
			GS.gameSocket.pass_()
		"Submit":
			if GS.gameState.get_phase() == GS.Types.Phase.ATTACK:
				GS.gameSocket.select_attackers()
			elif GS.gameState.get_phase() == GS.Types.Phase.BLOCK:
				GS.gameSocket.select_blockers()
			elif GS.targeting_type == GS.targeting_for.PLAY:
				var card_id = GS.targeting_card.get_id()
				GS.targeting_type = GS.targeting_for.NONE
				GS.targeting_card = null
				GS.gameSocket.play_card(card_id)
			elif GS.targeting_type == GS.targeting_for.ACTIVATE:
				var card_id = GS.targeting_card.get_id()
				GS.targeting_type = GS.targeting_for.NONE
				GS.targeting_card = null
				GS.gameSocket.activate_card(card_id)
			else:
				GS.gameSocket.select_from()
			GS.popup_message = ""
			GS.popup_cards = []
			GS.ability_selection_popup = false
		"Cancel":
			GS.ability_selection_popup = false
			GS.selection_info = null
			GS.targeting_card = null
			GS.targeting_type = GS.targeting_for.NONE
			GS.selected = []
			GS.popup_cards = []
		"Close":
			GS.ability_selection_popup = false
			GS.popup_cards = []
		"All Attack":
			GS.selected = []
			for c in GS.gameState.get_player().get_play():
				if c.get_canAttack():
					GS.selected.append(c.get_id())

