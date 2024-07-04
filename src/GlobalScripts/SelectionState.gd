extends Node

enum selection_type {PLAY, ACTIVATE, KNOWLEDGE, NONE}
var select_from_type
var selecting_card
var selecting_for = selection_type.NONE
var selection_id = ""
var selection_ability_id = ""
var selection_targets = []
var min_select = 0
var max_select = -1
var selection_message = ""
var selections = []
var callback
var selected_single = []
var selected = {}

var selectingX = false

func unpack_selection(selection_options):
	selection_id = selection_options.get_id()
	min_select = selection_options.get_minTargets()
	max_select = selection_options.get_maxTargets()
	selection_targets = selection_options.get_possibleTargets()
	selection_message = selection_options.get_targetMessage()
	selected_single = []
	if max_select > 0 and selection_options.get_targetingZone() == GS.Types.SelectFromType.DISCARD_PILE:
		GS.ability_selection_popup = false
		GS.popup_message = selection_message
		selection_message = ""
		var player = false
		for c in GS.gameState.get_player().get_discardPile():
			if selection_targets.has(c.get_id()):
				player = true
		if player:
			print("Selecting from player discard")
			GS.popup_cards = GS.gameState.get_player().get_discardPile()
		else:
			print("Selecting from opponent discard")
			GS.popup_cards = GS.gameState.get_opponent().get_discardPile()

func clear_selection_data():
	select_from_type = null
	selecting_card = null
	selecting_for = selection_type.NONE
	selection_id = ""
	selection_ability_id = ""
	selection_targets = []
	min_select = 0
	max_select = -1
	selection_message = ""
	selections = []
	callback = null
	selected_single = []
	selected = {}

func is_selecting():
	return selection_targets or \
	(GS.gameState and GS.gameState.get_activePlayer() == GS.playerId and \
	(GS.gameState.get_phase() == GS.Types.Phase.ATTACK or \
		GS.gameState.get_phase() == GS.Types.Phase.BLOCK))


func process_selections(selections, card, callback, selecting_type, ability_id = ""):
	SS.selections = selections.duplicate()
	SS.selecting_for = selecting_type
	SS.selecting_card = card
	SS.callback = callback
	SS.selection_ability_id = ability_id
	print_debug("Process selections " + str(selections.size()))
	process_selection(SS.selections.pop_front())

func submit_selection():
	SS.selected[SS.selection_id] = {"selection_id" = SS.selection_id, "selected" = selected_single.duplicate()}
	process_selection(SS.selections.pop_front())

func process_selection(selection):
	print_debug("Process selection")
	if selection:
		unpack_selection(selection)
		if max_select <= 0:
			process_selection(SS.selections.pop_front())
		elif min_select == selection_targets.size():
			SS.selected[SS.selection_id] = {"selection_id" = SS.selection_id, "selected" = selection_targets.duplicate()}
			process_selection(SS.selections.pop_front())
	else:
		if selecting_card:
			callback.call(selecting_card.get_id())
		else:
			callback.call()

func check_smart_select():
	if O.smart_select \
	and GS.gameState.get_phase() != GS.Types.Phase.ATTACK \
	and SS.selected_single.size() == SS.max_select:
		SS.submit_selection()

func print_selection_state():
	print("=== Selection State ===")
	print("selection id: " + selection_id)
	print("selection ability id: " + selection_ability_id)
	print("min select: " + str(min_select))
	print("max select: " + str(max_select))
	print("selection_targets: " + CS.to_array_string(selection_targets))
	print("selected_single: " + CS.to_array_string(selected_single))
	print("selected: " + CS.to_array_string(selected))
	print("=======================")
