extends Node

signal action_requested(action: String, payload: Variant)


func play_card(card_id: String) -> void:
	var targets: Array = []
	for value in SS.selected.values():
		targets.append(value)
	SS.clear_selection_data()
	action_requested.emit("play_card", {"card_id": card_id, "targets": targets})


func study_card(card_id: String) -> void:
	var knowledge: int = SS.selected_single[0] if not SS.selected_single.is_empty() else GS.Types.Knowledge.NONE
	SS.clear_selection_data()
	action_requested.emit("study_card", {"card_id": card_id, "knowledge": knowledge})


func select_attackers() -> void:
	var attackers := SS.selected_single.duplicate()
	SS.clear_selection_data()
	action_requested.emit("select_attackers", attackers)


func select_blockers() -> void:
	var assignments := []
	for pair in SS.selected.values():
		if pair is Array and pair.size() == 2:
			assignments.append({"blocker": pair[0].card.get_id(), "attacker": pair[1].card.get_id()})
	SS.clear_selection_data()
	action_requested.emit("select_blockers", assignments)


func pass_() -> void:
	action_requested.emit("pass", null)


func keep() -> void:
	action_requested.emit("keep", null)


func redraw() -> void:
	action_requested.emit("redraw", null)


func activate_card(card_id: String) -> void:
	action_requested.emit("activate_card", card_id)


func select_from() -> void:
	action_requested.emit("select_from", SS.selected_single.duplicate())
	SS.clear_selection_data()


func _process(_delta: float) -> void:
	pass


func close() -> void:
	pass
