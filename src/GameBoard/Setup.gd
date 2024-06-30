extends PanelContainer

func setup(card=null, targeting_ability=null):
	if card:
		set_name(card.get_id())
		set_unique_name_in_owner(true)
	find_child("InternalContainer").setup(card, targeting_ability)
