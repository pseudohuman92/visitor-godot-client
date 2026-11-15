extends PanelContainer

var popup_setup = false
var displayed_cards = []
var displayed_message = ""

func _ready():
	set_size(get_viewport_rect().size)
	hide()

func _process(_delta):
	if GS.popup_cards.is_empty():
		if popup_setup:
			find_child("Cards").clear()
		popup_setup = false
		displayed_cards.clear()
		displayed_message = ""
		hide()
	elif not popup_setup or displayed_cards != GS.popup_cards:
		var cards = find_child("Cards")
		cards.clear()
		find_child("PopupText").text = GS.popup_message
		if GS.ability_selection_popup:
			for entry in GS.popup_cards:
				cards.add_child(entry)
		else:
			cards.populate(GS.popup_cards)
		displayed_cards = GS.popup_cards.duplicate()
		displayed_message = GS.popup_message
		popup_setup = true
		show()
	if popup_setup:
		find_child("PopupText").text = GS.popup_message

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not SS.is_selecting():
		GS.clear_popup()
