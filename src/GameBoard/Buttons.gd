extends Button

func _process(_delta):
	set_disabled(GS.is_waiting)
	match name:
		"Keep":
			set_visible(GS.gameState and GS.gameState.get_phase() == GS.Types.Phase.REDRAW)
		"Redraw":
			set_visible(GS.gameState and GS.gameState.get_phase() == GS.Types.Phase.REDRAW)
		"Pass":
			set_visible(GS.has_initiative() and not SS.is_selecting() and not GS.popup_cards)
		"Submit":
			set_visible(SS.is_selecting())
			set_disabled(SS.selected_single.size() < SS.min_select \
			or (SS.max_select > -1 and SS.selected_single.size() > SS.max_select))
		"Cancel":
			set_visible((SS.is_selecting() and (SS.selecting_for == SS.selection_type.PLAY or SS.selecting_for == SS.selection_type.ACTIVATE)))
		"Close":
			set_visible(!SS.is_selecting() and GS.popup_cards)
		"All Attack":
			set_visible(SS.is_selecting() and \
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
			elif SS.selecting_for == SS.selection_type.PLAY or SS.selecting_for == SS.selection_type.ACTIVATE:
				SS.submit_selection()
			else:
				GS.gameSocket.select_from()
			GS.clear_popup()
		"Cancel":
			SS.clear_selection_data()
			GS.clear_popup()
		"All Attack":
			SS.selected_single = []
			for c in GS.gameState.get_player().get_play():
				if c.get_canAttack():
					SS.selected_single.append(c.get_id())

