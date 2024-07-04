extends Container

func setup(card=null, square=false, targeting_ability=null):
	if square:
		set_custom_minimum_size(Vector2(O.screen_size.y * O.square_card_height, O.screen_size.y * O.square_card_height))
	else:
		set_custom_minimum_size(Vector2(O.screen_size.y * O.card_height * O.card_aspect_ratio, O.screen_size.y * O.card_height))
	if card:
		set_name(card.get_id())
		set_unique_name_in_owner(true)
	find_child("InternalContainer").setup(card, targeting_ability)

