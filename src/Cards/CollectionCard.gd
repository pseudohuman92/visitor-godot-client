extends Control

var card
var _hover = false
var _hover_lift
var _deferred_hover_exit = false

func _ready():
	var visual = find_child("InternalContainer")
	_set_mouse_filter_pass_through(visual)
	_hover_lift = preload("res://src/Cards/HoverLift.gd").new(visual)
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

func _set_mouse_filter_pass_through(node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_set_mouse_filter_pass_through(child)

func _process(delta):
	if _deferred_hover_exit and not _pointer_in_card():
		_end_hover()
	if _hover_lift != null:
		_hover_lift.update(delta, _hover and not GS.is_dragging)

func setup(card=null):
	CS.setup_card(self, card)

func _pointer_in_card():
	var point = get_global_mouse_position()
	return get_global_rect().has_point(point) or find_child("InternalContainer").get_global_rect().has_point(point)

func _on_mouse_entered():
	_deferred_hover_exit = false
	_hover = true

func _on_mouse_exited():
	if _pointer_in_card():
		_deferred_hover_exit = true
		return
	_end_hover()

func _end_hover():
	_deferred_hover_exit = false
	_hover = false

func _on_gui_input(event):
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GS.decklist.count(card) < 3:
			GS.decklist.append(card)
			GS.decklist.sort_custom(CS.compare_cost_name_cardP)
			GS.decklist_changed = true
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and card:
		GS.show_card_preview(card, true)
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		GS.close_bigger_popup()
