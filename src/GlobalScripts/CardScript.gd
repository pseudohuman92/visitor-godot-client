extends Node

const text_icons = {
	"{B}": "res://assets/card-components/knowledge-B.png",
	"{G}": "res://assets/card-components/knowledge-G.png",
	"{P}": "res://assets/card-components/knowledge-P.png",
	"{R}": "res://assets/card-components/knowledge-R.png",
	"{Y}": "res://assets/card-components/knowledge-Y.png",
#	"{Use}": "res://assets/card-components/use-icon-black.png",
	"{damage}": "res://assets/card-components/attack-white.png",
	"{shield}": "res://assets/card-components/shield-white.png",
	"{0}": "res://assets/card-components/numbers/energy-0.png",
	"{1}": "res://assets/card-components/numbers/energy-1.png",
	"{2}": "res://assets/card-components/numbers/energy-2.png",
	"{3}": "res://assets/card-components/numbers/energy-3.png",
	"{4}": "res://assets/card-components/numbers/energy-4.png",
	"{5}": "res://assets/card-components/numbers/energy-5.png",
	"{6}": "res://assets/card-components/numbers/energy-6.png",
	"{7}": "res://assets/card-components/numbers/energy-7.png",
	"{8}": "res://assets/card-components/numbers/energy-8.png",
	"{9}": "res://assets/card-components/numbers/energy-9.png",
	"{X}": "res://assets/card-components/numbers/energy-X.png",
}

const combat_ability_hints = {
	"Evasive": "Can only be blocked by evasive units.",
	"Blitz": "Can attack and use abilities the turn its played.",
	"Vigilance": "Attacking doesn't exhaust it.",
	"Deadly": "Damage it deals kills the target.",
	"Drain": "Gains life equal to the damage dealt.",
	"Decay": "Loses 1 attack, 1 health, and 1 max health at the start of your turn.",
	"Trample": "Deals excess combat damage to the player",
	"Deploying": "Can't attack.",
	"Defender": "Can't attack.",
}

func get_card_image(set_name, card_name):
	return load("res://assets/card-images/"+set_name+"/"+card_name+".png")

func get_type_icon(type):
	return load ("res://assets/card-components/"+type+".png")

func get_placeholder_image(type):
	return load("res://assets/card-images/placeholders/"+type+".png")

func to_knowledge_string(knowledge):
	match knowledge:
		GS.Types.Knowledge.BLUE:
			return "B"
		GS.Types.Knowledge.GREEN:
			return "G"
		GS.Types.Knowledge.RED:
			return "R"
		GS.Types.Knowledge.PURPLE:
			return "P"
		GS.Types.Knowledge.YELLOW:
			return "Y"
	return ""

func to_knowledge_color(knowledge):
	if knowledge:
		match knowledge[0].get_knowledge():
			GS.Types.Knowledge.BLUE:
				return Color.NAVY_BLUE
			GS.Types.Knowledge.GREEN:
				return Color.DARK_GREEN
			GS.Types.Knowledge.RED:
				return Color.DARK_RED
			GS.Types.Knowledge.PURPLE:
				return Color.REBECCA_PURPLE
			GS.Types.Knowledge.YELLOW:
				return Color.DARK_GOLDENROD
	return Color.DIM_GRAY

func to_knowledge_type(knowledge):
	match knowledge:
		"B":
			return GS.Types.Knowledge.BLUE
		"G":
			return GS.Types.Knowledge.GREEN
		"R":
			return GS.Types.Knowledge.RED
		"P":
			return GS.Types.Knowledge.PURPLE
		"Y":
			return GS.Types.Knowledge.YELLOW
	return GS.Types.Knowledge.NONE

func to_knowledge_string_with_count(knowledge):
	var s = ""
	for knw in knowledge:
		for i in knw.get_count():
			s += to_knowledge_string(knw.get_knowledge())
	return s

func to_knowledge_string_no_count(knowledge):
	var s = ""
	for knw in knowledge:
		s += to_knowledge_string(knw.get_knowledge())
	return s

func to_array_string(arr, sep = " "):
	var res = ""
	for s in arr:
		res += str(s) + sep
	return res

func position_in_bounds(size, pos):
		return Vector2(min(max(0, pos.x), 1820-size.x), min(max(0, pos.y), 930-size.y))

func compare_cost_name_cardP(a, b):
	var a_c = a.get_cost()
	var a_n = a.get_name()
	var b_c = b.get_cost()
	var b_n = b.get_name()
	match a_c.casecmp_to(b_c):
		-1: return true
		0:
			match a_n.casecmp_to(b_n):
				-1: return true
				0: return false
				1: return false
		1: return false

func compare_color_cost_name_cardP(a, b):
	var a_c = a.get_knowledgeCost()
	var b_c = b.get_knowledgeCost()
	match to_knowledge_string_no_count(a_c).casecmp_to(to_knowledge_string_no_count(b_c)):
		-1: return true
		0: return compare_cost_name_cardP(a, b)
		1: return false

func change_stylebox_override(field, node, fun):
		var image_box = node.get_theme_stylebox(field).duplicate()
		fun.call(image_box)
		node.add_theme_stylebox_override(field, image_box)

func load_card_image_and_type(c):
	change_stylebox_override("panel", c.find_child("CardImage"),
	func(image_box):
		var image = get_card_image(c.card.get_set(),c.card.get_name())
		var type
		if c.card.get_types()[0] == "Spell" and c.card.get_subtypes():
			type = c.card.get_subtypes()[0]
		else:
			type = c.card.get_types()[0]
		if image:
			image_box.set_texture(image)
		else:
			image_box.set_texture(get_placeholder_image(type))
			image_box.set_modulate(Color.GRAY)
		c.find_child("TypeIcon").set_texture(get_type_icon(type)))


func setup_card(n, card=null):
	if card:
		n.card = card
		CS.load_card_image_and_type(n)
		n.find_child("CostArea").update(card.get_cost(), card.get_knowledgeCost())
		n.find_child("Name").set_text(card.get_name())
		n.find_child("DepletePanel").set_visible(card.get_depleted())
		CS.change_stylebox_override("normal", n.find_child("Name"), func(b): b.set_modulate(to_knowledge_color(card.get_knowledgeCost())))
		var ability_text = ""
		var combat = card.get_combat()
		if combat:
			n.find_child("Stats").set_visible(true)
			var stats_text = ""
			if combat.get_attack():
				n.find_child("Attack").set_text(str(combat.get_attack()))
			else:
				n.find_child("Attack").set_text("0")
			if combat.get_shield():
				n.find_child("Shield").set_text(str(combat.get_shield()))
			else:
				n.find_child("Shield").set_visible(false)
			if combat.get_health():
				n.find_child("Health").set_text(str(combat.get_health()))
			else:
				n.find_child("Health").set_text("0")
			if combat.get_deploying() and !(combat.get_combatAbilities() and combat.get_combatAbilities().has("Blitz")):
				ability_text += "Can't Attack\n"
			if combat.get_combatAbilities():
				var abilities = combat.get_combatAbilities().map(func(s): return "[hint="+combat_ability_hints[s]+"]"+s+"[/hint]")
				ability_text += to_array_string(abilities, ", ") + "\n"
		else:
			n.find_child("Stats").set_visible(false)
		ability_text += card.get_description()
		if n.find_child("Ability"):
			if ability_text != "":
				n.find_child("AbilityPanel").set_visible(true)
				n.find_child("Ability").set_text_custom(ability_text, card.get_name())
				CS.change_stylebox_override("panel", n.find_child("AbilityPanel"), func(b): b.set_bg_color(to_knowledge_color(card.get_knowledgeCost())-Color(0,0,0,0.4)))
			else:
				n.find_child("AbilityPanel").set_visible(false)
	else:
		CS.change_stylebox_override("panel", n.find_child("CardImage"), func(i): i.set_texture(load(GS.card_back_path)))
		n.find_child("Contents").set_visible(false)

func sanitize_card_name(name):
	return name.replace(" ","").replace(".","").replace("-","")


