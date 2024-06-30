extends PanelContainer

var popup_setup = false
# Called when the node enters the scene tree for the first time.
func _ready():
	set_size(get_viewport_rect().size)
	set_visible(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !GS.popup_cards and popup_setup:
		find_child("Cards").clear()
		set_visible(false)
		GS.clear_popup()
		popup_setup = false
	elif GS.popup_cards and !popup_setup:
		find_child("PopupText").set_text(GS.popup_message)
		var child = find_child("Cards")
		if GS.ability_selection_popup:
			GS.popup_cards.map(func(c): child.add_child(c))
		else:
			find_child("Cards").populate(GS.popup_cards)
		popup_setup = true
		set_visible(true)


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and !SS.is_selecting():
			GS.clear_popup()
