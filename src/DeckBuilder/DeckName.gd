extends LineEdit

func _ready():
	set_text(GS.deck_name)
	set_caret_column(GS.deck_name.length())


func _on_text_changed(new_text):
	GS.deck_name = new_text

func update():
	set_text(GS.deck_name)
	set_caret_column(GS.deck_name.length())
