extends Control

var card
var _hover = false
var _hover_lift
var _deferred_hover_exit = false

func _ready():
	var visual = find_child("InternalContainer")
	_hover_lift = preload("res://src/Cards/HoverLift.gd").new(visual)
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

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

func _set_border(color):
	var visual = find_child("InternalContainer")
	var border = visual.get_theme_stylebox("panel").duplicate()
	border.border_color = color
	visual.add_theme_stylebox_override("panel", border)

func _on_mouse_entered():
	_deferred_hover_exit = false
	_hover = true
	_set_border(Color.GOLDENROD)

func _on_mouse_exited():
	if _pointer_in_card():
		_deferred_hover_exit = true
		return
	_end_hover()

func _end_hover():
	_deferred_hover_exit = false
	_hover = false
	_set_border(Color.WHITE_SMOKE)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if GS.decklist.count(card) < 3:
				GS.decklist.append(card)
				GS.decklist.sort_custom(CS.compare_cost_name_cardP)
				GS.decklist_changed = true
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if card:
				var parent = find_parent("DeckBuilder")
				if is_instance_valid(GS.bigger_popup):
					GS.close_bigger_popup()
				GS.bigger_popup = GS.CollectionCardScene.instantiate()
				GS.bigger_popup.setup(card)
				parent.add_child(GS.bigger_popup)
				GS.bigger_popup.z_index = z_index + 1
				GS.bigger_popup.set_scale(Vector2(2,2))
				GS.bigger_popup.set_position(Vector2(0,0))

		if event.is_released():
			if is_instance_valid(GS.bigger_popup):
				var parent = find_parent("DeckBuilder")
				GS.close_bigger_popup()
