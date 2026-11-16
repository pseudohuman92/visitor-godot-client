extends RichTextLabel

var _source_text := ""
var _card_name := ""
var _icon_size := 0

func set_text_custom(text, name):
	_source_text = text
	_card_name = name
	_refresh_text()

func set_icon_size(size):
	var next_size = maxi(1, size)
	if next_size == _icon_size:
		return
	_icon_size = next_size
	_refresh_text()

func _refresh_text():
	if _source_text.is_empty():
		return
	var t = _source_text.replacen("{~}", _card_name)
	var icon_size = _icon_size if _icon_size > 0 else get_theme_font_size("normal_font_size")
	for ent in CS.text_icons.keys():
		t = t.replacen(ent, "[img="+str(icon_size)+"]"+CS.text_icons[ent]+"[/img]")
	set_text(t)
