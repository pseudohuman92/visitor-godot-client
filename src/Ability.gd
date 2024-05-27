extends RichTextLabel

func set_text_custom(text, name):
	var t = text.replacen("{~}", name)
	for ent in GS.text_icons.keys():
		t = t.replacen(ent, "[img="+str(theme.get_font_size("",""))+"]"+GS.text_icons[ent]+"[/img]")
	set_text(t)
