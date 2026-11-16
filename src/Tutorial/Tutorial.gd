extends Control

const MAIN_THEME = preload("res://src/Themes/MainTheme.tres")
const TITLE_FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold-Tracked.tres")
const NAV_FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold-Navigation.tres")
const BODY_FONT = preload("res://assets/fonts/Barlow-Regular.ttf")
const ARROW_OVERLAY = preload("res://src/Tutorial/TutorialArrowOverlay.gd")

const INK := Color("#111719")
const PANEL := Color("#1d2526")
const PANEL_LIGHT := Color("#293234")
const PAPER := Color("#e7e2d8")
const MUTED := Color("#a9aaa5")
const BRASS := Color("#d3aa6c")
const RED := Color("#b53d3c")
const GREEN := Color("#9ad27b")
const BLUE := Color("#82bddb")

const CARD_LIBRARY := {
	"field_notes": {
		"name": "Field Notes", "type": "TOME", "cost": 0, "knowledge": "STUDY",
		"text": "Study this card to grow your resources, then choose a knowledge color.",
		"art": "res://assets/card-images/base2/Tactical Briefing.png", "attack": 0, "health": 0
	},
	"rooftop_scout": {
		"name": "Rooftop Scout", "type": "UNIT", "cost": 1, "knowledge": "RED",
		"text": "A low-cost unit. Its 1 attack can still finish a weakened rival.",
		"art": "res://assets/card-images/base2/Sentry.png", "attack": 1, "health": 2
	},
	"field_recruit": {
		"name": "Field Recruit", "type": "UNIT", "cost": 2, "knowledge": "RED",
		"text": "A steady 2/2 unit. Units stay in play and can attack on later turns.",
		"art": "res://assets/card-images/base2/Stormtrooper.png", "attack": 2, "health": 2
	},
	"rook_guard": {
		"name": "Rook Guard", "type": "UNIT", "cost": 2, "knowledge": "BLUE",
		"text": "A durable blocker. It can survive a small attacker and protect your health.",
		"art": "res://assets/card-images/base2/Shield Barrage.png", "attack": 2, "health": 3
	},
	"raider": {
		"name": "Ash Raider", "type": "UNIT", "cost": 2, "knowledge": "RED",
		"text": "An opposing 2/2 unit is attacking. Choose a legal blocker to stop it.",
		"art": "res://assets/card-images/base2/Blitz Robbers.png", "attack": 2, "health": 2
	},
	"ember_bolt": {
		"name": "Ember Bolt", "type": "SPELL", "cost": 2, "knowledge": "RED",
		"text": "Deal 3 damage to the opponent when this spell resolves.",
		"art": "res://assets/card-images/base2/Explosive Shot.png", "attack": 0, "health": 0
	},
	"ash_warden": {
		"name": "Ash Warden", "type": "UNIT", "cost": 2, "knowledge": "RED",
		"text": "When this enters play, its triggered ability deals 1 damage and draws a card.",
		"art": "res://assets/card-images/base2/Vampireling.png", "attack": 2, "health": 3
	},
	"duelist": {
		"name": "Street Duelist", "type": "UNIT", "cost": 1, "knowledge": "RED",
		"text": "A 2/2 attacker. The defender will block it in this exercise.",
		"art": "res://assets/card-images/base2/Sentry.png", "attack": 2, "health": 2
	},
	"bulwark": {
		"name": "Iron Bulwark", "type": "UNIT", "cost": 3, "knowledge": "BLUE",
		"text": "A 3/3 blocker. A combat trick can change how this fight ends.",
		"art": "res://assets/card-images/base2/Stormtrooper.png", "attack": 3, "health": 3
	},
	"rally": {
		"name": "Rallying Cry", "type": "FAST SPELL", "cost": 1, "knowledge": "RED",
		"text": "Give a unit +2 attack and prevent the next 2 damage this turn.",
		"art": "res://assets/card-images/base2/Shield Barrage.png", "attack": 0, "health": 0
	},
	"finisher": {
		"name": "Last Vanguard", "type": "UNIT", "cost": 3, "knowledge": "RED",
		"text": "A ready 2/3 attacker. With no blocker, it can deal lethal damage.",
		"art": "res://assets/card-images/base2/Blitz Robbers.png", "attack": 2, "health": 3
	},
	"drawn_signal": {
		"name": "Signal Flare", "type": "SPELL", "cost": 1, "knowledge": "BLUE",
		"text": "A card drawn by Ash Warden's triggered ability.",
		"art": "res://assets/card-images/base2/Puncturing Rounds.png", "attack": 0, "health": 0
	}
}

const LESSONS := [
	{
		"nav": "BOARD BASICS", "title": "Read the board at a glance", "setup": {"player_hand": ["rooftop_scout"], "opponent_hand": 3},
		"steps": [
			{"target": "opponent_info", "prompt": "Start with the opponent's status.", "body": "This panel shows the rival's health, energy, knowledge, and match clock. Bring their health to zero to win.", "hint": "Click the opponent's information panel.", "effect": "explain", "success": "Health is the match goal: protect yours and reduce theirs."},
			{"target": "opponent_hand", "prompt": "The opponent's hand is hidden.", "body": "You can see how many cards the rival holds, but their card faces stay private. Your own hand is visible at the bottom.", "hint": "Click the opponent hand row.", "effect": "explain", "success": "Hidden information keeps both players making decisions with incomplete knowledge."},
			{"target": "opponent_deck", "prompt": "Track the rival's deck and discard pile.", "body": "Deck and discard counts are public. Opponent cards in hand stay hidden, while their discarded cards are open information.", "hint": "Click the opponent deck counter.", "effect": "explain", "success": "You can track how many cards remain in the rival's deck."},
			{"target": "opponent_discard", "prompt": "The opponent's discard pile is public too.", "body": "Cards that resolve or leave play may end up here. Check the visible top card and count when planning around the rival's options.", "hint": "Click the opponent discard counter.", "effect": "explain", "success": "Discard piles can reveal which answers have already been used."},
			{"target": "opponent_zone", "prompt": "This is the opponent's battlefield.", "body": "Their units and assets appear on their side of the combat line. You can inspect public cards and follow their combat arrows.", "hint": "Click the opponent battlefield label.", "effect": "explain", "success": "Cards above the divider belong to the opponent."},
			{"target": "player_zone", "prompt": "Your battlefield is below the divider.", "body": "Units and assets you control stay here. Units can attack or block when the current phase and their card text allow it.", "hint": "Click your battlefield label.", "effect": "explain", "success": "The red separator makes both sides of combat easy to read."},
			{"target": "player_info", "prompt": "Check your resources before acting.", "body": "Energy pays the numeric cost. Knowledge icons are separate requirements. This simulated match also shows your health and remaining time.", "hint": "Click your information panel.", "effect": "explain", "success": "Plan around both the energy number and the knowledge symbols."},
			{"target": "player_deck", "prompt": "Cards drawn leave your deck.", "body": "The deck count changes as you draw. Studying sends a card from your hand back into the deck.", "hint": "Click your deck counter.", "effect": "explain", "success": "You can track how many cards remain to draw."},
			{"target": "player_discard", "prompt": "Your discard pile keeps used cards visible.", "body": "Resolved spells and defeated units commonly go here. Their top card and total count help you track what has happened.", "hint": "Click your discard counter.", "effect": "explain", "success": "You now know the main places cards move during a match."},
			{"target": "player_hand_area", "prompt": "Your hand is where decisions begin.", "body": "Select a card to inspect it. Depending on its type, you may play it, study it, or keep it for a later turn.", "hint": "Click the hand label above your cards.", "effect": "explain", "success": "Board tour complete. Next, trade a card for lasting resources."}
		]
	},
	{
		"nav": "STUDY A CARD", "title": "Study to build your resources", "setup": {"energy": 1, "max_energy": 1, "deck_count": 23, "player_hand": ["field_notes", "rooftop_scout"]},
		"steps": [
			{"target": "card:field_notes", "prompt": "Choose the card you want to study.", "body": "Studying is a slow action in a main phase. Select Field Notes in your hand; its preview explains the exchange.", "hint": "Select Field Notes in your hand.", "effect": "select_card", "card_id": "field_notes", "success": "The card is selected. The deck is the study destination."},
			{"target": "player_deck", "prompt": "Send the selected card to your deck.", "body": "A regular study shuffles the selected card back into your deck and increases both current and maximum energy by one.", "hint": "Click your deck to study Field Notes.", "effect": "study_card", "success": "Study resolved: your energy grew and Field Notes returned to the deck."},
			{"target": "knowledge_red", "prompt": "Choose the knowledge to gain.", "body": "This card offers red knowledge. Knowledge stays in your pool and helps satisfy colored card requirements.", "hint": "Choose the red knowledge icon.", "effect": "gain_red_knowledge", "success": "You now have one red knowledge for cards that require it."},
			{"target": "card:rooftop_scout", "prompt": "Use the new resources to read another card.", "body": "The Scout needs one energy and one red knowledge. Select it to inspect its cost and unit stats before playing.", "hint": "Select Rooftop Scout in your hand.", "effect": "select_card", "card_id": "rooftop_scout", "success": "Good. The number is its energy cost; the red mark is a separate requirement."}
		]
	},
	{
		"nav": "PLAY A CARD", "title": "Play a unit to the battlefield", "setup": {"energy": 3, "max_energy": 3, "red_knowledge": 1, "player_hand": ["field_recruit"]},
		"steps": [
			{"target": "card:field_recruit", "prompt": "Select the Field Recruit.", "body": "The Recruit costs 2 energy and one red knowledge. You have enough of both, so this play is legal.", "hint": "Select Field Recruit in your hand.", "effect": "select_card", "card_id": "field_recruit", "success": "Card selected. Play it from your hand."},
			{"target": "confirm_button", "action_text": "PLAY UNIT", "prompt": "Play the selected unit.", "body": "Playing a unit spends its cost and moves it from your hand to your battlefield. Units remain in play unless an effect removes them.", "hint": "Press PLAY UNIT.", "effect": "play_unit", "success": "The Recruit is in play. Its attack and health are shown on the card."},
			{"target": "unit:field_recruit", "prompt": "Inspect your new unit.", "body": "The left stat is attack; the right stat is health. The green edge marks the unit you just played for this lesson.", "hint": "Click the Field Recruit on your battlefield.", "effect": "explain", "success": "You have played a card and can read its stats on the board."}
		]
	},
	{
		"nav": "ATTACK", "title": "Declare attackers and deal damage", "setup": {"opponent_health": 6, "player_units": ["field_recruit"]},
		"steps": [
			{"target": "unit:field_recruit", "prompt": "Choose a unit to attack.", "body": "Only units allowed to attack in the current phase are selectable. Select the Recruit to mark it as an attacker.", "hint": "Select Field Recruit on your battlefield.", "effect": "select_attacker", "card_id": "field_recruit", "success": "Attacker selected. Confirm the attack to send it at the opponent."},
			{"target": "confirm_button", "action_text": "DECLARE ATTACK", "prompt": "Declare the attack.", "body": "With no blocker in this exercise, the Recruit deals its 2 attack directly to the opponent.", "hint": "Press DECLARE ATTACK.", "effect": "attack_opponent", "success": "The attack dealt 2 damage. Follow the health total on the rival's panel."},
			{"target": "opponent_info", "prompt": "Check the result of combat.", "body": "Unblocked attackers can damage the defending player. A blocker would have changed this exchange.", "hint": "Click the opponent's updated health panel.", "effect": "explain", "success": "Attackers are chosen by the attacking player; blockers are chosen by the defender."}
		]
	},
	{
		"nav": "BLOCK", "title": "Block to protect your health", "setup": {"opponent_units": ["raider"], "player_units": ["rook_guard"], "attacking_unit": "raider"},
		"steps": [
			{"target": "unit:rook_guard", "prompt": "Choose your blocker.", "body": "The Ash Raider is attacking. Select Rook Guard; blockers must be ready and allowed by the rules.", "hint": "Select Rook Guard on your battlefield.", "effect": "select_blocker", "card_id": "rook_guard", "success": "Blocker selected. Now choose which attacker it will stop."},
			{"target": "unit:raider", "prompt": "Assign the blocker to the Raider.", "body": "The defending player chooses which of their units blocks each attacker. The arrow will show your assignment.", "hint": "Click the attacking Ash Raider.", "effect": "assign_block", "success": "Block assigned. Both units will deal combat damage to each other."},
			{"target": "confirm_button", "action_text": "RESOLVE COMBAT", "prompt": "Resolve the block.", "body": "Rook Guard deals 2 damage to the 2-health Raider. The Raider deals 2 damage to the Guard, which survives with 1 health.", "hint": "Press RESOLVE COMBAT.", "effect": "resolve_block", "success": "The Raider was defeated and the Guard protected your health."},
			{"target": "unit:rook_guard", "prompt": "Inspect the survivor.", "body": "Damage reduced the Guard's remaining health. If damage had met or exceeded its health, it would have been defeated too.", "hint": "Click the damaged Rook Guard.", "effect": "explain", "success": "Blocking can trade units or preserve a valuable defender, depending on stats and abilities."}
		]
	},
	{
		"nav": "SPELLS & STACK", "title": "Cast a spell, then resolve it", "setup": {"energy": 2, "max_energy": 2, "red_knowledge": 1, "opponent_health": 6, "player_hand": ["ember_bolt"]},
		"steps": [
			{"target": "card:ember_bolt", "prompt": "Select Ember Bolt.", "body": "This spell costs 2 energy and one red knowledge. Unlike a unit, a resolved spell goes to the discard pile.", "hint": "Select Ember Bolt in your hand.", "effect": "select_card", "card_id": "ember_bolt", "success": "Spell selected. Choose its target."},
			{"target": "opponent_info", "prompt": "Choose the opponent as the target.", "body": "Targeted effects ask for a legal target before they are placed on the stack.", "hint": "Click the opponent's information panel.", "effect": "target_opponent", "success": "Target chosen. Now cast the spell."},
			{"target": "confirm_button", "action_text": "CAST EMBER BOLT", "prompt": "Put Ember Bolt on the stack.", "body": "Casting spends the cost and puts the spell on the stack. Players get a response window before it resolves.", "hint": "Press CAST EMBER BOLT.", "effect": "cast_spell", "success": "Ember Bolt is pending on the stack. It has not dealt damage yet."},
			{"target": "stack_item", "prompt": "Inspect the pending effect.", "body": "The stack shows effects waiting to resolve. A fast spell or ability could be played here before this item resolves.", "hint": "Click Ember Bolt in the stack area.", "effect": "explain", "success": "You can respond while an item is pending."},
			{"target": "resolve_button", "action_text": "RESOLVE TOP", "prompt": "Resolve the top item.", "body": "In this exercise, both players pass. Ember Bolt resolves, deals 3 damage, and moves to your discard pile.", "hint": "Press RESOLVE TOP.", "effect": "resolve_spell", "success": "The spell resolved. The opponent's health changed and the card reached your discard."}
		]
	},
	{
		"nav": "TRIGGERED ABILITIES", "title": "A card can trigger an ability", "setup": {"energy": 2, "max_energy": 2, "red_knowledge": 1, "opponent_health": 8, "player_hand": ["ash_warden"]},
		"steps": [
			{"target": "card:ash_warden", "prompt": "Select Ash Warden.", "body": "Its text begins with “When this enters play”. That wording describes a triggered ability, which happens automatically when its event occurs.", "hint": "Select Ash Warden in your hand.", "effect": "select_card", "card_id": "ash_warden", "success": "The Warden is selected. Playing it will cause its ability to trigger."},
			{"target": "confirm_button", "action_text": "PLAY ASH WARDEN", "prompt": "Play the Warden and create its trigger.", "body": "The unit enters play. Its triggered ability is then put on the stack as a separate effect.", "hint": "Press PLAY ASH WARDEN.", "effect": "play_trigger", "success": "Ash Whispers triggered automatically and is waiting on the stack."},
			{"target": "stack_item", "prompt": "Read the triggered ability on the stack.", "body": "The ability is independent of its source now. It will still resolve even if the Warden leaves play.", "hint": "Click Ash Whispers in the stack area.", "effect": "explain", "success": "Triggered abilities use the same response and resolution flow as spells."},
			{"target": "resolve_button", "action_text": "RESOLVE TRIGGER", "prompt": "Resolve Ash Whispers.", "body": "The simulated trigger deals 1 damage to the rival and draws a card for you.", "hint": "Press RESOLVE TRIGGER.", "effect": "resolve_trigger", "success": "The trigger resolved: the rival lost health and a card entered your hand."}
		]
	},
	{
		"nav": "COMBAT TRICKS", "title": "Respond in combat with a trick", "setup": {"energy": 1, "max_energy": 1, "red_knowledge": 1, "player_hand": ["rally"], "player_units": ["duelist"], "opponent_units": ["bulwark"]},
		"steps": [
			{"target": "unit:duelist", "prompt": "Select Street Duelist as your attacker.", "body": "The combat trick is useful after blockers are assigned. Start by declaring an attack with your unit.", "hint": "Select Street Duelist.", "effect": "select_trick_attacker", "card_id": "duelist", "success": "Attacker selected. Declare the attack."},
			{"target": "confirm_button", "action_text": "DECLARE ATTACK", "prompt": "Declare attackers.", "body": "Iron Bulwark blocks the Duelist. The game now gives you a combat response window before damage.", "hint": "Press DECLARE ATTACK.", "effect": "declare_trick_attack", "success": "The Bulwark is blocking. You can respond before combat damage."},
			{"target": "card:rally", "prompt": "Choose Rallying Cry during the response window.", "body": "Fast spells can be played in response to combat. This one boosts attack and prevents damage for the turn.", "hint": "Select Rallying Cry in your hand.", "effect": "select_card", "card_id": "rally", "success": "Rallying Cry selected. Choose the unit it will protect."},
			{"target": "unit:duelist", "prompt": "Target your blocked attacker.", "body": "The Duelist is a legal target for the trick. The arrow points from the effect to its target.", "hint": "Click Street Duelist.", "effect": "target_trick_unit", "success": "Target set. Cast the trick onto the stack."},
			{"target": "confirm_button", "action_text": "CAST RALLYING CRY", "prompt": "Cast Rallying Cry before damage.", "body": "The trick is now above the combat damage event. Resolve it first, then combat continues with the changed stats.", "hint": "Press CAST RALLYING CRY.", "effect": "cast_trick", "success": "Rallying Cry is pending. Resolve the top item."},
			{"target": "stack_item", "prompt": "Check the order on the stack.", "body": "The combat trick resolves before damage. If both players pass, it changes the Duelist's stats and shields it.", "hint": "Click Rallying Cry in the stack area.", "effect": "explain", "success": "Order matters: the trick resolves before combat damage."},
			{"target": "resolve_button", "action_text": "RESOLVE TRICK", "prompt": "Resolve the combat trick.", "body": "The Duelist gets +2 attack and a shield that prevents 2 damage this turn.", "hint": "Press RESOLVE TRICK.", "effect": "resolve_trick", "success": "The Duelist is now stronger and protected. Resolve combat."},
			{"target": "resolve_combat_button", "action_text": "RESOLVE COMBAT", "prompt": "Finish combat with the new stats.", "body": "The 4-attack Duelist defeats the 3-health Bulwark. Its shield prevents 2 of the 3 incoming damage, so it survives with 1 health.", "hint": "Press RESOLVE COMBAT.", "effect": "resolve_trick_combat", "success": "The trick changed the combat outcome: your unit survived and defeated its blocker."}
		]
	},
	{
		"nav": "WIN THE GAME", "title": "Put the lessons together", "setup": {"opponent_health": 2, "player_units": ["finisher"]},
		"steps": [
			{"target": "unit:finisher", "prompt": "Choose your ready attacker.", "body": "The opponent has 2 health and no blocker. Your Last Vanguard can deal 2 damage, exactly enough to win.", "hint": "Select Last Vanguard.", "effect": "select_attacker", "card_id": "finisher", "success": "The attack is ready. Declare it to end the match."},
			{"target": "confirm_button", "action_text": "DECLARE LETHAL ATTACK", "prompt": "Declare the final attack.", "body": "The unblocked unit deals its attack directly to the rival. The client simulation will show the match ending at zero health.", "hint": "Press DECLARE LETHAL ATTACK.", "effect": "final_attack", "success": "Lethal damage! The opponent has been defeated."},
			{"target": "opponent_info", "prompt": "Confirm the match result.", "body": "You have studied a card, built resources, played units and spells, used combat, resolved a trigger, and changed a block with a trick.", "hint": "Click the defeated opponent panel.", "effect": "explain", "success": "Tutorial complete. You are ready to try a real match."}
		]
	}
]

var _lesson_index := 0
var _step_index := 0
var _lesson_complete := false
var _game_won := false
var _completed_lessons: Array[bool] = []
var _setup_data: Dictionary = {}
var _player_hand: Array = []
var _player_units: Array = []
var _player_discard: Array = []
var _opponent_units: Array = []
var _opponent_discard: Array = []
var _stack: Array = []
var _energy := 0
var _max_energy := 0
var _red_knowledge := 0
var _blue_knowledge := 0
var _player_health := 20
var _opponent_health := 20
var _deck_count := 24
var _opponent_deck_count := 24
var _opponent_hand_count := 3
var _selected_card_id := ""
var _selected_target_id := ""
var _attacking_unit_id := ""
var _blocking_unit_id := ""
var _assigned_blocker_id := ""
var _combat_routes: Array = []
var _nudge_text := ""
var _coach_feedback := ""

var _target_controls: Dictionary = {}
var _card_panels: Dictionary = {}
var _arrow_overlay
var _coach_panel: Control
var _course_list: VBoxContainer
var _course_buttons: Array[Button] = []
var _chapter_label: Label
var _coach_step: Label
var _coach_title: Label
var _coach_body: Label
var _coach_hint: Label
var _coach_feedback_label: Label
var _selected_card_panel: PanelContainer
var _selected_card_title: Label
var _selected_card_details: Label
var _restart_button: Button
var _next_button: Button
var _progress_label: Label

var _opponent_info_button: Button
var _opponent_hand_button: Button
var _opponent_zone_button: Button
var _player_zone_button: Button
var _player_info_button: Button
var _player_deck_button: Button
var _player_discard_button: Button
var _opponent_deck_button: Button
var _opponent_discard_button: Button
var _player_hand_button: Button
var _knowledge_red_button: Button
var _knowledge_label: Label
var _opponent_units_row: HBoxContainer
var _player_units_row: HBoxContainer
var _player_hand_row: HBoxContainer
var _stack_button: Button
var _action_button: Button
var _phase_label: Label
var _result_banner: Label


func _ready() -> void:
	theme = MAIN_THEME
	_completed_lessons.resize(LESSONS.size())
	_completed_lessons.fill(false)
	_build_interface()
	_start_lesson(0)
	get_viewport().size_changed.connect(_on_viewport_resized)


func _process(_delta: float) -> void:
	_refresh_arrow_positions()


func _build_interface() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/backgrounds/omen_board_background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(background)
	add_child(background)

	var veil := ColorRect.new()
	veil.color = Color(0.025, 0.031, 0.035, 0.56)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(veil)
	add_child(veil)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_set_full_rect(margin)
	add_child(margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 14)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main)
	_build_header(main)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(columns)
	_build_course_panel(columns)
	_build_board_panel(columns)
	_build_coach_panel(columns)

	_arrow_overlay = ARROW_OVERLAY.new()
	_arrow_overlay.name = "TutorialArrowOverlay"
	_arrow_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arrow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow_overlay.z_index = 100
	add_child(_arrow_overlay)


func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 70
	header.add_theme_constant_override("separation", 18)
	parent.add_child(header)

	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 0)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var title := _make_label("LEARN TO PLAY", 30, TITLE_FONT, PAPER)
	brand.add_child(title)
	var note := _make_label("OFFLINE FIELD TRAINING  •  SIMULATED MATCHES", 15, NAV_FONT, MUTED)
	brand.add_child(note)

	_chapter_label = _make_label("PART 01 / 09", 20, NAV_FONT, BRASS)
	_chapter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_chapter_label)

	var exit_button := _make_button("MAIN MENU", false)
	exit_button.custom_minimum_size = Vector2(170, 46)
	exit_button.pressed.connect(_return_to_menu)
	header.add_child(exit_button)


func _build_course_panel(parent: HBoxContainer) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size.x = 256
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(_make_label("COURSE", 22, TITLE_FONT, PAPER))
	var intro := _make_label("Nine short parts, from board basics to a lethal finish.", 15, BODY_FONT, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)

	_course_list = VBoxContainer.new()
	_course_list.add_theme_constant_override("separation", 5)
	content.add_child(_course_list)
	for index in range(LESSONS.size()):
		var button := _make_button("%02d   %s" % [index + 1, LESSONS[index]["nav"]], false)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 43
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_lesson.bind(index))
		_course_list.add_child(button)
		_course_buttons.append(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	_progress_label = _make_label("0 / 9 PARTS COMPLETE", 15, NAV_FONT, GREEN)
	content.add_child(_progress_label)
	var local_note := _make_label("All effects in this course run locally in the client.", 14, BODY_FONT, MUTED)
	local_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(local_note)


func _build_board_panel(parent: HBoxContainer) -> void:
	var frame := _make_panel()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)

	var board := VBoxContainer.new()
	board.add_theme_constant_override("separation", 8)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(board)

	var top_line := HBoxContainer.new()
	top_line.add_theme_constant_override("separation", 12)
	board.add_child(top_line)
	_phase_label = _make_label("PRACTICE ARENA", 17, NAV_FONT, BRASS)
	_phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_line.add_child(_phase_label)
	var simulated := _make_label("CLIENT SIMULATION", 13, NAV_FONT, MUTED)
	top_line.add_child(simulated)

	_opponent_info_button = _make_button("RIVAL   ♥ 20     ENERGY  1 / 1     KNOWLEDGE  —     TIME 20:00", false)
	_opponent_info_button.custom_minimum_size.y = 50
	_opponent_info_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opponent_info_button.pressed.connect(_on_target_pressed.bind("opponent_info"))
	board.add_child(_opponent_info_button)
	_register_static_target("opponent_info", _opponent_info_button)

	_opponent_hand_button = _make_button("OPPONENT HAND     ▰  ▰  ▰", false)
	_opponent_hand_button.custom_minimum_size.y = 42
	_opponent_hand_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opponent_hand_button.pressed.connect(_on_target_pressed.bind("opponent_hand"))
	board.add_child(_opponent_hand_button)
	_register_static_target("opponent_hand", _opponent_hand_button)
	var opponent_resources := HBoxContainer.new()
	opponent_resources.add_theme_constant_override("separation", 7)
	opponent_resources.custom_minimum_size.y = 34
	board.add_child(opponent_resources)
	_opponent_deck_button = _make_button("RIVAL DECK 24", false)
	_opponent_deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opponent_deck_button.pressed.connect(_on_target_pressed.bind("opponent_deck"))
	opponent_resources.add_child(_opponent_deck_button)
	_register_static_target("opponent_deck", _opponent_deck_button)
	_opponent_discard_button = _make_button("RIVAL DISCARD 0", false)
	_opponent_discard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opponent_discard_button.pressed.connect(_on_target_pressed.bind("opponent_discard"))
	opponent_resources.add_child(_opponent_discard_button)
	_register_static_target("opponent_discard", _opponent_discard_button)

	var opponent_zone := _make_zone_panel("OPPONENT BATTLEFIELD", 142)
	board.add_child(opponent_zone.panel)
	_opponent_zone_button = opponent_zone.heading
	_opponent_units_row = opponent_zone.row
	_opponent_zone_button.pressed.connect(_on_target_pressed.bind("opponent_zone"))
	_register_static_target("opponent_zone", _opponent_zone_button)

	var divider := HBoxContainer.new()
	divider.add_theme_constant_override("separation", 10)
	divider.custom_minimum_size.y = 22
	board.add_child(divider)
	_add_rule(divider)
	divider.add_child(_make_label("COMBAT LINE", 13, NAV_FONT, RED))
	_add_rule(divider)

	var player_zone := _make_zone_panel("YOUR BATTLEFIELD", 142)
	board.add_child(player_zone.panel)
	_player_zone_button = player_zone.heading
	_player_units_row = player_zone.row
	_player_zone_button.pressed.connect(_on_target_pressed.bind("player_zone"))
	_register_static_target("player_zone", _player_zone_button)

	_player_info_button = _make_button("YOU   ♥ 20     ENERGY  1 / 1     KNOWLEDGE  —     TIME 20:00", false)
	_player_info_button.custom_minimum_size.y = 46
	_player_info_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_info_button.pressed.connect(_on_target_pressed.bind("player_info"))
	board.add_child(_player_info_button)
	_register_static_target("player_info", _player_info_button)

	var resources := HBoxContainer.new()
	resources.add_theme_constant_override("separation", 7)
	resources.custom_minimum_size.y = 38
	board.add_child(resources)
	_player_deck_button = _make_button("DECK 24", false)
	_player_deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_deck_button.pressed.connect(_on_target_pressed.bind("player_deck"))
	resources.add_child(_player_deck_button)
	_register_static_target("player_deck", _player_deck_button)
	_player_discard_button = _make_button("DISCARD 0", false)
	_player_discard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_discard_button.pressed.connect(_on_target_pressed.bind("player_discard"))
	resources.add_child(_player_discard_button)
	_register_static_target("player_discard", _player_discard_button)
	_knowledge_red_button = _make_button("RED KNOWLEDGE  0", false)
	_knowledge_red_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_knowledge_red_button.pressed.connect(_on_target_pressed.bind("knowledge_red"))
	resources.add_child(_knowledge_red_button)
	_register_static_target("knowledge_red", _knowledge_red_button)
	_knowledge_label = _make_label("BLUE 0", 15, NAV_FONT, BLUE)
	_knowledge_label.custom_minimum_size.x = 70
	_knowledge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resources.add_child(_knowledge_label)

	var hand_panel := _make_zone_panel("YOUR HAND  •  SELECT A CARD TO INSPECT IT", 178)
	board.add_child(hand_panel.panel)
	_player_hand_button = hand_panel.heading
	_player_hand_row = hand_panel.row
	_player_hand_button.pressed.connect(_on_target_pressed.bind("player_hand_area"))
	_register_static_target("player_hand_area", _player_hand_button)

	_stack_button = _make_button("STACK EMPTY", false)
	_stack_button.custom_minimum_size.y = 38
	_stack_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stack_button.pressed.connect(_on_target_pressed.bind("stack_item"))
	board.add_child(_stack_button)
	_register_static_target("stack_item", _stack_button)

	_action_button = _make_button("FOLLOW THE HIGHLIGHT", true)
	_action_button.custom_minimum_size.y = 46
	_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_button.pressed.connect(_on_action_button_pressed)
	board.add_child(_action_button)

	_result_banner = _make_label("", 20, TITLE_FONT, GREEN)
	_result_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_banner.visible = false
	board.add_child(_result_banner)


func _build_coach_panel(parent: HBoxContainer) -> void:
	_coach_panel = _make_panel()
	_coach_panel.custom_minimum_size.x = 334
	_coach_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_coach_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	_coach_panel.add_child(content)
	content.add_child(_make_label("FIELD GUIDE", 21, TITLE_FONT, BRASS))
	_coach_step = _make_label("STEP 01 / 01", 15, NAV_FONT, RED)
	content.add_child(_coach_step)
	_coach_title = _make_label("Welcome", 25, TITLE_FONT, PAPER)
	_coach_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_coach_title)
	_coach_body = _make_label("Follow the highlighted prompt and the arrow to explore the board.", 17, BODY_FONT, PAPER)
	_coach_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coach_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_child(_coach_body)

	var prompt_panel := _make_panel()
	prompt_panel.add_theme_stylebox_override("panel", _make_box(PANEL_LIGHT, BRASS, 1, 10))
	content.add_child(prompt_panel)
	var prompt_content := VBoxContainer.new()
	prompt_content.add_theme_constant_override("separation", 5)
	prompt_panel.add_child(prompt_content)
	prompt_content.add_child(_make_label("YOUR NEXT MOVE", 14, NAV_FONT, BRASS))
	_coach_hint = _make_label("Follow the gold arrow.", 16, BODY_FONT, PAPER)
	_coach_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_content.add_child(_coach_hint)

	_selected_card_panel = _make_panel()
	_selected_card_panel.visible = false
	content.add_child(_selected_card_panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 5)
	_selected_card_panel.add_child(details)
	_selected_card_title = _make_label("", 17, NAV_FONT, BRASS)
	_selected_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_selected_card_title)
	_selected_card_details = _make_label("", 14, BODY_FONT, PAPER)
	_selected_card_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_selected_card_details)

	_coach_feedback_label = _make_label("", 15, BODY_FONT, GREEN)
	_coach_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_coach_feedback_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	_restart_button = _make_button("RESTART THIS PART", false)
	_restart_button.custom_minimum_size.y = 42
	_restart_button.pressed.connect(_restart_lesson)
	content.add_child(_restart_button)
	_next_button = _make_button("NEXT PART", true)
	_next_button.custom_minimum_size.y = 46
	_next_button.pressed.connect(_next_lesson)
	content.add_child(_next_button)


func _make_zone_panel(title: String, min_height: float) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = min_height
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.075, 0.08, 0.78), Color("#647071"), 1, 6))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	panel.add_child(content)
	var heading := _make_button(title, false)
	heading.custom_minimum_size.y = 30
	heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	return {"panel": panel, "heading": heading, "row": row}


func _add_rule(parent: HBoxContainer) -> void:
	var line := ColorRect.new()
	line.color = RED
	line.custom_minimum_size.y = 2
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


func _start_lesson(index: int) -> void:
	_lesson_index = clampi(index, 0, LESSONS.size() - 1)
	_step_index = 0
	_lesson_complete = false
	_game_won = false
	_selected_card_id = ""
	_selected_target_id = ""
	_attacking_unit_id = ""
	_blocking_unit_id = ""
	_assigned_blocker_id = ""
	_combat_routes.clear()
	_nudge_text = ""
	_coach_feedback = ""
	_setup_data = LESSONS[_lesson_index].get("setup", {})
	_player_hand = _instantiate_cards(_setup_data.get("player_hand", []))
	_player_units = _instantiate_cards(_setup_data.get("player_units", []))
	_player_discard.clear()
	_opponent_units = _instantiate_cards(_setup_data.get("opponent_units", []))
	_opponent_discard.clear()
	_stack.clear()
	_energy = _setup_data.get("energy", 1)
	_max_energy = _setup_data.get("max_energy", 1)
	_red_knowledge = _setup_data.get("red_knowledge", 0)
	_blue_knowledge = _setup_data.get("blue_knowledge", 0)
	_player_health = _setup_data.get("player_health", 20)
	_opponent_health = _setup_data.get("opponent_health", 20)
	_deck_count = _setup_data.get("deck_count", 24)
	_opponent_deck_count = _setup_data.get("opponent_deck_count", 24)
	_opponent_hand_count = _setup_data.get("opponent_hand", 3)
	if not str(_setup_data.get("attacking_unit", "")).is_empty():
		var attacker := _find_card(_setup_data.attacking_unit)
		if not attacker.is_empty():
			attacker["is_attacking"] = true
			_attacking_unit_id = _setup_data.attacking_unit
			_combat_routes.append({"from": "unit:" + _setup_data.attacking_unit, "to": "player_info"})
	_refresh_view()


func _instantiate_cards(ids: Array) -> Array:
	var result: Array = []
	for card_id in ids:
		if CARD_LIBRARY.has(card_id):
			var card: Dictionary = CARD_LIBRARY[card_id].duplicate(true)
			card["card_id"] = card_id
			card["shield"] = 0
			result.append(card)
	return result


func _register_static_target(target_id: String, control: Control) -> void:
	_target_controls[target_id] = control


func _refresh_view() -> void:
	for target_id in _target_controls.keys().duplicate():
		if str(target_id).begins_with("card:") or str(target_id).begins_with("unit:"):
			_target_controls.erase(target_id)
	_card_panels.clear()
	_render_card_row(_opponent_units_row, _opponent_units, "unit:")
	_render_card_row(_player_units_row, _player_units, "unit:")
	_render_card_row(_player_hand_row, _player_hand, "card:")

	var opponent_energy := _setup_data.get("opponent_energy", 1)
	var opponent_max_energy := _setup_data.get("opponent_max_energy", 1)
	var opponent_knowledge := _setup_data.get("opponent_knowledge", "—")
	var opponent_name := "DEFEATED" if _game_won else "RIVAL"
	_opponent_info_button.text = "%s    ♥ %d    ENERGY  %d / %d    KNOWLEDGE  %s    TIME 20:00" % [opponent_name, _opponent_health, opponent_energy, opponent_max_energy, opponent_knowledge]
	_player_info_button.text = "YOU    ♥ %d    ENERGY  %d / %d    KNOWLEDGE  %s    TIME 20:00" % [_player_health, _energy, _max_energy, _knowledge_summary()]
	_opponent_hand_button.text = "OPPONENT HAND     %s" % _card_back_glyphs(_opponent_hand_count)
	_player_hand_button.text = "YOUR HAND  •  SELECT A CARD TO INSPECT IT  (%d)" % _player_hand.size()
	_player_deck_button.text = "DECK  %d" % _deck_count
	_player_discard_button.text = "DISCARD  %d" % _player_discard.size()
	_opponent_deck_button.text = "RIVAL DECK  %d" % _opponent_deck_count
	_opponent_discard_button.text = "RIVAL DISCARD  %d" % _opponent_discard.size()
	_knowledge_red_button.text = "RED KNOWLEDGE  %d" % _red_knowledge
	_stack_button.text = _stack_display_text()
	_stack_button.disabled = _stack.is_empty()
	_result_banner.visible = _game_won
	_result_banner.text = "VICTORY  •  OPPONENT DEFEATED" if _game_won else ""
	_phase_label.text = "PART %02d  •  %s" % [_lesson_index + 1, LESSONS[_lesson_index]["nav"]]

	for action_target in ["confirm_button", "resolve_button", "resolve_combat_button"]:
		_target_controls.erase(action_target)
	var step := _current_step()
	var current_target := str(step.get("target", ""))
	var action_targets := ["confirm_button", "resolve_button", "resolve_combat_button"]
	var is_action_step := action_targets.has(current_target)
	_action_button.disabled = not is_action_step
	_action_button.text = str(step.get("action_text", "FOLLOW THE HIGHLIGHT")) if is_action_step else "FOLLOW THE HIGHLIGHT"
	if is_action_step:
		_target_controls[current_target] = _action_button

	_refresh_coach()
	_refresh_highlight()
	_refresh_course_nav()
	_refresh_arrow_positions()


func _render_card_row(row: HBoxContainer, cards: Array, target_prefix: String) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	if cards.is_empty():
		var empty := _make_label("No cards here", 15, BODY_FONT, MUTED)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(empty)
		return
	for card in cards:
		var target_id := target_prefix + str(card.card_id)
		var card_view := _make_card_view(card, target_id)
		row.add_child(card_view)
		_target_controls[target_id] = card_view


func _make_card_view(card: Dictionary, target_id: String) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(126, 164)
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var face := PanelContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.add_theme_stylebox_override("panel", _card_style(false, false))
	root.add_child(face)
	_card_panels[target_id] = face
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	face.add_child(content)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(0, 68)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(card.get("art", "")):
		art.texture = load(card.art)
	content.add_child(art)
	var name := _make_label(str(card.get("name", "Card")), 16, NAV_FONT, PAPER)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.y = 32
	content.add_child(name)
	var cost := _make_label("%d ENERGY  •  %s" % [int(card.get("cost", 0)), str(card.get("knowledge", "—"))], 12, NAV_FONT, BRASS)
	cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(cost)
	if card.get("attack", 0) > 0:
		var stats := _make_label("%d  /  %d" % [card.attack, card.health], 14, NAV_FONT, GREEN)
		content.add_child(stats)
	else:
		var type_label := _make_label(str(card.get("type", "CARD")), 12, NAV_FONT, BLUE)
		content.add_child(type_label)

	var hit := Button.new()
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_state in ["normal", "hover", "pressed", "focus", "disabled"]:
		hit.add_theme_stylebox_override(style_state, StyleBoxEmpty.new())
	hit.pressed.connect(_on_target_pressed.bind(target_id))
	root.add_child(hit)
	return root


func _card_style(focused: bool, selected: bool) -> StyleBoxFlat:
	var border := BRASS if focused else (GREEN if selected else Color("#777e79"))
	var box := _make_box(Color("#202729"), border, 3 if focused or selected else 1, 5)
	return box


func _refresh_coach() -> void:
	var lesson: Dictionary = LESSONS[_lesson_index]
	_chapter_label.text = "PART %02d / %02d" % [_lesson_index + 1, LESSONS.size()]
	_selected_card_panel.visible = not _selected_card_id.is_empty()
	var selected := _find_card(_selected_card_id)
	if selected.is_empty():
		_selected_card_panel.visible = false
	else:
		_selected_card_title.text = "%s  •  %s" % [selected.get("name", "Card"), selected.get("type", "")]
		var stats := ""
		if selected.get("attack", 0) > 0:
			stats = "\nStats: %d attack / %d health" % [selected.attack, selected.health]
		_selected_card_details.text = "Cost: %d energy + %s knowledge\n%s%s" % [selected.get("cost", 0), str(selected.get("knowledge", "none")).to_lower(), selected.get("text", ""), stats]

	if _lesson_complete:
		_coach_step.text = "PART %02d COMPLETE" % (_lesson_index + 1)
		_coach_title.text = "Lesson complete"
		_coach_body.text = "You finished %s. " % lesson["title"] + str(lesson.get("recap", "The next part builds on these skills. Use Restart This Part to practice again."))
		_coach_hint.text = "Continue to the next part or replay this one."
		_coach_feedback_label.text = "Course progress: %d of %d parts complete." % [_completed_count(), LESSONS.size()]
		_next_button.visible = true
		_next_button.text = "RESTART COURSE" if _lesson_index == LESSONS.size() - 1 else "NEXT PART"
		return

	var steps: Array = lesson.steps
	var step: Dictionary = steps[_step_index]
	_coach_step.text = "STEP %02d / %02d" % [_step_index + 1, steps.size()]
	_coach_title.text = step.prompt
	_coach_body.text = step.body
	_coach_hint.text = step.hint
	_coach_feedback_label.text = _nudge_text if not _nudge_text.is_empty() else _coach_feedback
	_coach_feedback_label.add_theme_color_override("font_color", Color("#e5a09a") if not _nudge_text.is_empty() else GREEN)
	_next_button.visible = false


func _refresh_highlight() -> void:
	var expected := str(_current_step().get("target", ""))
	for target_id in _target_controls:
		var control = _target_controls[target_id]
		if not is_instance_valid(control):
			continue
		if _card_panels.has(target_id):
			var card := _find_card(str(target_id).trim_prefix("card:").trim_prefix("unit:"))
			var is_selected := card.get("card_id", "") == _selected_card_id
			_card_panels[target_id].add_theme_stylebox_override("panel", _card_style(target_id == expected, is_selected))
		else:
			control.modulate = Color(1.18, 1.11, 0.87, 1.0) if target_id == expected else Color.WHITE


func _refresh_course_nav() -> void:
	var complete_count := _completed_count()
	_progress_label.text = "%d / %d PARTS COMPLETE" % [complete_count, LESSONS.size()]
	for index in range(_course_buttons.size()):
		var button := _course_buttons[index]
		var mark := "  ✓" if _completed_lessons[index] else ""
		button.text = "%02d   %s%s" % [index + 1, LESSONS[index]["nav"], mark]
		button.modulate = Color(1.15, 1.08, 0.85, 1.0) if index == _lesson_index else (Color(0.92, 1.0, 0.83, 1.0) if _completed_lessons[index] else Color.WHITE)


func _refresh_arrow_positions() -> void:
	if not is_instance_valid(_arrow_overlay):
		return
	var current_step := _current_step()
	var target_id := str(current_step.get("target", ""))
	var target: Control = _target_controls.get(target_id)
	var active := is_instance_valid(target) and not _lesson_complete
	var start := Vector2.ZERO
	var finish := Vector2.ZERO
	if active:
		var from_global := _coach_panel.get_global_rect().position + Vector2(0, _coach_panel.size.y * 0.5)
		var to_global := target.get_global_rect().get_center()
		start = _arrow_overlay.get_global_transform_with_canvas().affine_inverse() * from_global
		finish = _arrow_overlay.get_global_transform_with_canvas().affine_inverse() * to_global
	var routes: Array = []
	for route in _combat_routes:
		var source: Control = _target_controls.get(route.get("from", ""))
		var destination: Control = _target_controls.get(route.get("to", ""))
		if is_instance_valid(source) and is_instance_valid(destination):
			var source_point := _arrow_overlay.get_global_transform_with_canvas().affine_inverse() * source.get_global_rect().get_center()
			var destination_point := _arrow_overlay.get_global_transform_with_canvas().affine_inverse() * destination.get_global_rect().get_center()
			routes.append({"from": source_point, "to": destination_point})
	_arrow_overlay.set_arrows(start, finish, active, routes)


func _on_viewport_resized() -> void:
	call_deferred("_refresh_arrow_positions")


func _on_target_pressed(target_id: String) -> void:
	if _lesson_complete:
		return
	var step := _current_step()
	if target_id != str(step.get("target", "")):
		_nudge_text = "For this step, %s" % str(step.get("hint", "follow the highlighted target.")).to_lower()
		_coach_feedback_label.text = _nudge_text
		_coach_feedback_label.add_theme_color_override("font_color", Color("#e5a09a"))
		return
	_nudge_text = ""
	_apply_effect(str(step.get("effect", "explain")), step, target_id)
	_coach_feedback = str(step.get("success", "Good move."))
	_step_index += 1
	if _step_index >= LESSONS[_lesson_index].steps.size():
		_finish_lesson()
	_refresh_view()


func _on_action_button_pressed() -> void:
	if _action_button.disabled or _lesson_complete:
		return
	var target_id := str(_current_step().get("target", ""))
	_on_target_pressed(target_id)


func _apply_effect(effect: String, step: Dictionary, target_id: String) -> void:
	match effect:
		"explain":
			var card_id := _card_id_from_target(target_id)
			if not card_id.is_empty():
				_selected_card_id = card_id
		"select_card":
			_selected_card_id = str(step.get("card_id", ""))
		"study_card":
			var studied := _take_from(_player_hand, _selected_card_id)
			if not studied.is_empty():
				_player_hand.erase(studied)
				_deck_count += 1
				_max_energy += 1
				_energy += 1
				_selected_card_id = ""
		"gain_red_knowledge":
			_red_knowledge += 1
		"play_unit":
			_play_selected_unit()
		"select_attacker":
			_selected_card_id = str(step.get("card_id", ""))
			_attacking_unit_id = _selected_card_id
		"attack_opponent":
			var attacker := _find_card(_attacking_unit_id)
			if not attacker.is_empty():
				attacker["exhausted"] = true
				_opponent_health = maxi(0, _opponent_health - int(attacker.get("attack", 0)))
				_combat_routes = [{"from": "unit:" + _attacking_unit_id, "to": "opponent_info"}]
		"select_blocker":
			_blocking_unit_id = str(step.get("card_id", ""))
			_selected_card_id = _blocking_unit_id
		"assign_block":
			_assigned_blocker_id = _blocking_unit_id
			_combat_routes = [{"from": "unit:" + _assigned_blocker_id, "to": "unit:" + _attacking_unit_id}]
		"resolve_block":
			_resolve_block()
		"target_opponent":
			_selected_target_id = "opponent_info"
		"cast_spell":
			_cast_selected_card("spell", "Ember Bolt", "Deal 3 damage to the opponent.")
		"resolve_spell":
			_resolve_spell()
		"play_trigger":
			_play_trigger_unit()
		"resolve_trigger":
			_resolve_trigger()
		"select_trick_attacker":
			_selected_card_id = str(step.get("card_id", ""))
			_attacking_unit_id = _selected_card_id
		"declare_trick_attack":
			var attacker := _find_card(_attacking_unit_id)
			if not attacker.is_empty():
				attacker["exhausted"] = true
			_attacking_unit_id = "duelist"
			_assigned_blocker_id = "bulwark"
			_combat_routes = [{"from": "unit:bulwark", "to": "unit:duelist"}]
		"target_trick_unit":
			_selected_target_id = _card_id_from_target(target_id)
		"cast_trick":
			_cast_selected_card("trick", "Rallying Cry", "Give Street Duelist +2 attack and prevent the next 2 damage.")
		"resolve_trick":
			_resolve_trick()
		"resolve_trick_combat":
			_resolve_trick_combat()
		"final_attack":
			var finisher := _find_card(_attacking_unit_id)
			if not finisher.is_empty():
				finisher["exhausted"] = true
				_opponent_health = maxi(0, _opponent_health - int(finisher.get("attack", 0)))
				_combat_routes = [{"from": "unit:" + _attacking_unit_id, "to": "opponent_info"}]
				_game_won = _opponent_health == 0


func _play_selected_unit() -> void:
	var card := _take_from(_player_hand, _selected_card_id)
	if card.is_empty():
		return
	_energy = maxi(0, _energy - int(card.get("cost", 0)))
	card["ready"] = false
	_player_units.append(card)
	_selected_card_id = ""


func _resolve_block() -> void:
	var attacker := _take_from(_opponent_units, _attacking_unit_id)
	var blocker := _find_card(_assigned_blocker_id)
	if attacker.is_empty() or blocker.is_empty():
		return
	var remaining_health := int(blocker.get("health", 0)) - int(attacker.get("attack", 0))
	_opponent_discard.append(attacker)
	if int(attacker.get("attack", 0)) >= int(blocker.get("health", 0)):
		var defeated_blocker := _take_from(_player_units, _assigned_blocker_id)
		if not defeated_blocker.is_empty():
			_player_discard.append(defeated_blocker)
	else:
		blocker["health"] = remaining_health
	_opponent_units.erase(attacker)
	_attacking_unit_id = ""
	_assigned_blocker_id = ""
	_combat_routes.clear()


func _cast_selected_card(kind: String, effect_name: String, effect_text: String) -> void:
	var card := _take_from(_player_hand, _selected_card_id)
	if card.is_empty():
		return
	_energy = maxi(0, _energy - int(card.get("cost", 0)))
	card["kind"] = kind
	card["effect_name"] = effect_name
	card["effect_text"] = effect_text
	card["card_id"] = str(card.get("card_id", _selected_card_id))
	_stack.append(card)
	_selected_card_id = ""


func _resolve_spell() -> void:
	if _stack.is_empty():
		return
	var spell: Dictionary = _stack.pop_back()
	_opponent_health = maxi(0, _opponent_health - 3)
	_player_discard.append(spell)
	_combat_routes = [{"from": "stack_item", "to": "opponent_info"}]


func _play_trigger_unit() -> void:
	var card := _take_from(_player_hand, _selected_card_id)
	if card.is_empty():
		return
	_energy = maxi(0, _energy - int(card.get("cost", 0)))
	_player_units.append(card)
	_stack.append({"card_id": "ash_trigger", "name": "ASH WHISPERS", "type": "TRIGGER", "cost": 0, "knowledge": "—", "text": "Deal 1 damage to the opponent and draw a card.", "kind": "trigger", "effect_name": "ASH WHISPERS"})
	_selected_card_id = ""
	_combat_routes = [{"from": "unit:ash_warden", "to": "stack_item"}]


func _resolve_trigger() -> void:
	if _stack.is_empty():
		return
	_stack.pop_back()
	_opponent_health = maxi(0, _opponent_health - 1)
	if _deck_count > 0:
		_deck_count -= 1
		_player_hand.append(_make_card("drawn_signal"))
	_combat_routes.clear()


func _resolve_trick() -> void:
	if _stack.is_empty():
		return
	var trick: Dictionary = _stack.pop_back()
	var target := _find_card(_selected_target_id)
	if not target.is_empty():
		target["attack"] = int(target.get("attack", 0)) + 2
		target["shield"] = int(target.get("shield", 0)) + 2
		_selected_card_id = str(target.card_id)
	_player_discard.append(trick)
	_combat_routes = [{"from": "unit:" + _selected_card_id, "to": "unit:" + _assigned_blocker_id}]


func _resolve_trick_combat() -> void:
	var attacker := _find_card(_attacking_unit_id)
	var blocker := _take_from(_opponent_units, _assigned_blocker_id)
	if attacker.is_empty() or blocker.is_empty():
		return
	var blocker_health := int(blocker.get("health", 0)) - int(attacker.get("attack", 0))
	var incoming := maxi(0, int(blocker.get("attack", 0)) - int(attacker.get("shield", 0)))
	var attacker_health := int(attacker.get("health", 0)) - incoming
	if blocker_health <= 0:
		_opponent_discard.append(blocker)
	else:
		blocker["health"] = blocker_health
		_opponent_units.append(blocker)
	if attacker_health <= 0:
		var defeated_attacker := _take_from(_player_units, _attacking_unit_id)
		if not defeated_attacker.is_empty():
			_player_discard.append(defeated_attacker)
	else:
		attacker["health"] = attacker_health
		attacker["shield"] = 0
	_attacking_unit_id = ""
	_assigned_blocker_id = ""
	_combat_routes.clear()


func _finish_lesson() -> void:
	_lesson_complete = true
	_completed_lessons[_lesson_index] = true
	if _lesson_index == LESSONS.size() - 1 and _game_won:
		_coach_feedback = "Victory recorded in this local tutorial simulation."


func _current_step() -> Dictionary:
	if _lesson_complete:
		return {}
	var steps: Array = LESSONS[_lesson_index].steps
	if _step_index < 0 or _step_index >= steps.size():
		return {}
	return steps[_step_index]


func _find_card(card_id: String) -> Dictionary:
	if card_id.is_empty():
		return {}
	for group in [_player_hand, _player_units, _player_discard, _opponent_units, _opponent_discard, _stack]:
		for card in group:
			if str(card.get("card_id", "")) == card_id:
				return card
	return {}


func _take_from(cards: Array, card_id: String) -> Dictionary:
	for index in range(cards.size()):
		if str(cards[index].get("card_id", "")) == card_id:
			return cards.pop_at(index)
	return {}


func _make_card(card_id: String) -> Dictionary:
	if not CARD_LIBRARY.has(card_id):
		return {}
	var card: Dictionary = CARD_LIBRARY[card_id].duplicate(true)
	card["card_id"] = card_id
	card["shield"] = 0
	return card


func _card_id_from_target(target_id: String) -> String:
	if target_id.begins_with("card:") or target_id.begins_with("unit:"):
		return target_id.split(":", false, 1)[1]
	return ""


func _knowledge_summary() -> String:
	var parts: Array[String] = []
	if _red_knowledge > 0:
		parts.append("RED %d" % _red_knowledge)
	if _blue_knowledge > 0:
		parts.append("BLUE %d" % _blue_knowledge)
	return " / ".join(parts) if not parts.is_empty() else "—"


func _card_back_glyphs(count: int) -> String:
	var glyphs := ""
	for _index in range(mini(count, 5)):
		glyphs += "▰  "
	return glyphs.strip_edges()


func _stack_display_text() -> String:
	if _stack.is_empty():
		return "STACK EMPTY"
	var top: Dictionary = _stack.back()
	return "ON THE STACK  •  %s" % str(top.get("effect_name", top.get("name", "Pending effect")))


func _completed_count() -> int:
	var result := 0
	for completed in _completed_lessons:
		if completed:
			result += 1
	return result


func _restart_lesson() -> void:
	_start_lesson(_lesson_index)


func _select_lesson(index: int) -> void:
	_start_lesson(index)


func _next_lesson() -> void:
	if _lesson_index == LESSONS.size() - 1:
		_start_lesson(0)
	else:
		_start_lesson(_lesson_index + 1)


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://src/MainMenu/MainMenu.tscn")


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.075, 0.08, 0.95), Color("#535d5d"), 1, 7))
	return panel


func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", NAV_FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _make_box(RED if primary else PANEL_LIGHT, BRASS if primary else Color("#697270"), 1, 5))
	button.add_theme_stylebox_override("hover", _make_box(Color("#9e3736") if primary else Color("#384345"), BRASS, 2, 5))
	button.add_theme_stylebox_override("pressed", _make_box(Color("#722827") if primary else Color("#242d2f"), BRASS, 2, 5))
	button.add_theme_stylebox_override("focus", _make_box(Color(0, 0, 0, 0), BRASS, 2, 5))
	return button


func _make_label(text: String, size: int, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_box(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("ui_cancel"):
		_return_to_menu()
