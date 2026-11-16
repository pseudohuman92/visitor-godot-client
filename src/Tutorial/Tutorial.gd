extends Control

const MAIN_THEME = preload("res://src/Themes/MainTheme.tres")
const PANEL_STYLE = preload("res://assets/ui/styles/panel_standard.tres")
const GHOST_DEFAULT = preload("res://assets/ui/styles/button_ghost_default.tres")
const GHOST_HOVER = preload("res://assets/ui/styles/button_ghost_hover.tres")
const GHOST_PRESSED = preload("res://assets/ui/styles/button_ghost_pressed.tres")
const SECONDARY_DEFAULT = preload("res://assets/ui/styles/button_secondary_default.tres")
const SECONDARY_HOVER = preload("res://assets/ui/styles/button_secondary_hover.tres")
const SECONDARY_PRESSED = preload("res://assets/ui/styles/button_secondary_pressed.tres")
const NAV_FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold-Navigation.tres")
const TITLE_FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold-Tracked.tres")
const BODY_FONT = preload("res://assets/fonts/Barlow-Regular.ttf")
const SCREENSHOT_BOARD = preload("res://assets/tutorial/screenshots/01-board-overview.jpg")
const SCREENSHOT_OPENING_HAND = preload("res://assets/tutorial/screenshots/02-opening-hand.jpg")
const SCREENSHOT_CARD_ANATOMY = preload("res://assets/tutorial/screenshots/03-card-anatomy.jpg")
const SCREENSHOT_STUDY = preload("res://assets/tutorial/screenshots/04-study.jpg")
const SCREENSHOT_TURN_ORDER = preload("res://assets/tutorial/screenshots/05-turn-order.jpg")
const SCREENSHOT_STACK_RESPONSE = preload("res://assets/tutorial/screenshots/06-stack-response.jpg")
const SCREENSHOT_COMBAT = preload("res://assets/tutorial/screenshots/07-combat.jpg")
const ACCENT := Color("#b53d3c")
const TEXT := Color("#e8e5df")
const MUTED := Color("#a9aaa5")
const GREEN := Color("#9ad27b")

const LESSONS = [
	{
		"nav": "THE BOARD",
		"title": "Know the board. Know the goal.",
		"subtitle": "Reduce your opponent's health to zero.",
		"body": "Both players begin at 30 health. Damage and card effects change that total; when a player's health reaches zero, that player loses.\n\nYour hand is along the bottom. Units and assets stay in the central play area. Your deck, discard pile, health, energy, and knowledge are grouped at the right. The red divider separates your side from your opponent's.",
		"screenshot": SCREENSHOT_BOARD,
		"question": "",
		"answers": [],
		"correct": -1,
		"success": ""
	},
	{
		"nav": "OPENING HAND",
		"title": "Choose your opening hand.",
		"subtitle": "Keep a hand you can use, or redraw for fewer cards.",
		"body": "You start with five cards. If the hand does not fit your plan, choose Redraw: those cards are shuffled back into your deck and you draw one fewer. Choose Keep when you are ready to begin.\n\nA balanced hand usually has cards you can afford, plus a card you can study to build your resources.",
		"screenshot": SCREENSHOT_OPENING_HAND,
		"question": "",
		"answers": [],
		"correct": -1,
		"success": ""
	},
	{
		"nav": "READ A CARD",
		"title": "Read the cost before you play.",
		"subtitle": "Energy and knowledge are separate requirements.",
		"body": "The number in a card's cost is the energy you spend. Colored knowledge icons show the knowledge you must have in your pool. You need to meet both requirements to play the card.\n\nUnits have attack and health and usually remain on the board. Spells often resolve and go to the discard pile. The card's text explains its effect. Hover keywords for a reminder, or right-click a card to inspect it larger.",
		"screenshot": SCREENSHOT_CARD_ANATOMY,
		"question": "A card costs 2 and shows one red knowledge icon. What do you need?",
		"answers": ["2 energy and 1 red knowledge", "2 red knowledge only", "Any 2 knowledge"],
		"correct": 0,
		"success": "Correct. Energy pays the number; your knowledge pool pays the colored requirement."
	},
	{
		"nav": "STUDY",
		"title": "Study to grow your resources.",
		"subtitle": "You get one regular study each turn.",
		"body": "Drag an eligible card from your hand onto your deck to study it. A regular study normally shuffles that card back into your deck, adds one to your maximum and current energy, and adds one knowledge of a type shown on the card. Some special cards have different study effects.\n\nThe green border around your deck means a card in your hand can be studied now. If the card offers more than one knowledge type, choose the one you need.",
		"screenshot": SCREENSHOT_STUDY,
		"question": "What does a regular study usually give you?",
		"answers": ["One energy, one max energy, and one offered knowledge", "Two cards drawn", "A free play of that card"],
		"correct": 0,
		"success": "That's it. Studying trades a card from hand for lasting resource growth."
	},
	{
		"nav": "TURN ORDER",
		"title": "Take your turn in phases.",
		"subtitle": "The phase label shows what actions are available.",
		"body": "At the start of your turn, the game draws cards, refreshes your energy to its maximum, and restores your study. In Main Before and Main After you can take slow actions, including studying.\n\nThe middle of the turn is combat: declare attackers, allow responses, let the defender assign blockers, then allow another response window. Fast cards and abilities can be used in the windows shown by the game. Eligible actions are highlighted on the board.",
		"screenshot": SCREENSHOT_TURN_ORDER,
		"question": "When can you take a slow action such as studying?",
		"answers": ["Main Before or Main After", "Only during combat", "Any time, including the opponent's turn"],
		"correct": 0,
		"success": "Correct. Slow actions need an empty stack during one of your main phases."
	},
	{
		"nav": "STACK & RESPONSE",
		"title": "Respond before effects resolve.",
		"subtitle": "Priority passes between players while an effect is pending.",
		"body": "Playing a card or activating an ability can put an effect on the stack. The other player gets a chance to respond with a fast card or ability. When both players pass in succession, the top item on the stack resolves. If the stack is empty, passing advances the phase instead.\n\nA targeted card asks you to choose a legal target before it is sent. Read the target prompt and follow its highlights.",
		"screenshot": SCREENSHOT_STACK_RESPONSE,
		"question": "The stack is not empty. Both players pass in succession. What happens?",
		"answers": ["The top stack item resolves", "The match ends", "The stack is discarded"],
		"correct": 0,
		"success": "Correct. After it resolves, players may receive priority again."
	},
	{
		"nav": "COMBAT",
		"title": "Attack, block, and learn from the exchange.",
		"subtitle": "Choose attackers; the defending player chooses legal blockers.",
		"body": "In the Attack phase, select the units you want to send. Only units that are allowed to attack will be selectable; newly played units and card abilities can change that. After responses, the opponent assigns eligible blockers to attackers.\n\nCombat damage uses each unit's attack against the other unit's health. If an attacker is unblocked, it can damage the defending player. Shields and abilities can change the result, so check the card text and combat arrows before submitting.",
		"screenshot": SCREENSHOT_COMBAT,
		"question": "Who chooses which units block an attack?",
		"answers": ["The defending player", "The attacking player", "The game always chooses"],
		"correct": 0,
		"success": "Right. The defender chooses among the blockers the rules allow."
	}
]

var _current_lesson := 0
var _lesson_buttons: Array[Button] = []
var _answer_buttons: Array[Button] = []
var _answered_current := false

var _lesson_count: Label
var _title: Label
var _subtitle: Label
var _body: Label
var _lesson_screenshot: TextureRect
var _quiz_panel: PanelContainer
var _question: Label
var _answers: VBoxContainer
var _feedback: Label
var _progress: ProgressBar
var _progress_label: Label
var _previous: Button
var _next: Button
var _practice: Button

func _ready() -> void:
	theme = MAIN_THEME
	_build_screen()
	_show_lesson(0)

func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/backgrounds/wp10493985-grunge-texture-wallpapers.jpg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(background)
	add_child(background)
	move_child(background, 0)

	var veil := ColorRect.new()
	veil.color = Color(0.025, 0.031, 0.035, 0.7)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(veil)
	add_child(veil)
	move_child(veil, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	_set_full_rect(margin)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(layout)

	_build_header(layout)
	var separator := ColorRect.new()
	separator.color = ACCENT
	separator.custom_minimum_size.y = 3
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(separator)
	_build_lessons(layout)

func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 84
	header.add_theme_constant_override("separation", 24)
	parent.add_child(header)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/omen_components/logo/omen_nav_logo.png")
	logo.custom_minimum_size = Vector2(210, 72)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(logo)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(heading)

	var heading_title := Label.new()
	heading_title.text = "LEARN TO PLAY"
	_set_label_style(heading_title, 32, TITLE_FONT, TEXT)
	heading.add_child(heading_title)

	var heading_note := Label.new()
	heading_note.text = "VISITOR FIELD MANUAL  •  THE ESSENTIALS"
	_set_label_style(heading_note, 16, NAV_FONT, MUTED)
	heading.add_child(heading_note)

	var menu_button := _make_button("MAIN MENU", false)
	menu_button.custom_minimum_size = Vector2(190, 54)
	menu_button.pressed.connect(_return_to_menu)
	header.add_child(menu_button)

func _build_lessons(parent: VBoxContainer) -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(columns)

	var nav_panel := _make_panel()
	nav_panel.custom_minimum_size.x = 332
	nav_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(nav_panel)

	var nav_content := VBoxContainer.new()
	nav_content.add_theme_constant_override("separation", 10)
	nav_panel.add_child(nav_content)

	var nav_heading := Label.new()
	nav_heading.text = "LESSONS"
	_set_label_style(nav_heading, 22, TITLE_FONT, TEXT)
	nav_content.add_child(nav_heading)

	var nav_hint := Label.new()
	nav_hint.text = "Move through the basics at your own pace."
	nav_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_style(nav_hint, 16, BODY_FONT, MUTED)
	nav_content.add_child(nav_hint)

	var nav_list := VBoxContainer.new()
	nav_list.add_theme_constant_override("separation", 6)
	nav_content.add_child(nav_list)
	for i in range(LESSONS.size()):
		var lesson_button := Button.new()
		lesson_button.text = "%02d   %s" % [i + 1, LESSONS[i]["nav"]]
		lesson_button.toggle_mode = true
		lesson_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		lesson_button.custom_minimum_size.y = 48
		lesson_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lesson_button.add_theme_stylebox_override("normal", GHOST_DEFAULT)
		lesson_button.add_theme_stylebox_override("hover", GHOST_HOVER)
		lesson_button.add_theme_stylebox_override("pressed", GHOST_PRESSED)
		lesson_button.add_theme_stylebox_override("focus", GHOST_PRESSED)
		lesson_button.add_theme_font_override("font", NAV_FONT)
		lesson_button.add_theme_font_size_override("font_size", 18)
		lesson_button.pressed.connect(_select_lesson.bind(i))
		nav_list.add_child(lesson_button)
		_lesson_buttons.append(lesson_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_content.add_child(spacer)

	var nav_footer := Label.new()
	nav_footer.text = "Tip: green highlights show actions that are legal now."
	nav_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_style(nav_footer, 16, BODY_FONT, Color("#b9c89e"))
	nav_content.add_child(nav_footer)

	var lesson_panel := _make_panel()
	lesson_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(lesson_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson_panel.add_child(content)

	var heading_row := HBoxContainer.new()
	content.add_child(heading_row)
	_lesson_count = Label.new()
	_lesson_count.custom_minimum_size.x = 140
	_set_label_style(_lesson_count, 16, NAV_FONT, ACCENT)
	heading_row.add_child(_lesson_count)
	var row_spacer := Control.new()
	row_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(row_spacer)
	var row_note := Label.new()
	row_note.text = "SELF-PACED • ANSWER CHECKS ARE OPTIONAL"
	_set_label_style(row_note, 14, NAV_FONT, MUTED)
	heading_row.add_child(row_note)

	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_style(_title, 34, TITLE_FONT, TEXT)
	content.add_child(_title)

	_subtitle = Label.new()
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_style(_subtitle, 20, NAV_FONT, Color("#dfc8a3"))
	content.add_child(_subtitle)

	_body = Label.new()
	_body.custom_minimum_size.y = 80
	_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_set_label_style(_body, 18, BODY_FONT, TEXT)
	content.add_child(_body)

	var screenshot_panel := _make_panel()
	screenshot_panel.custom_minimum_size.y = 360
	screenshot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(screenshot_panel)
	_lesson_screenshot = TextureRect.new()
	_lesson_screenshot.name = "LessonScreenshot"
	_lesson_screenshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lesson_screenshot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lesson_screenshot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lesson_screenshot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lesson_screenshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screenshot_panel.add_child(_lesson_screenshot)

	_quiz_panel = _make_panel()
	_quiz_panel.custom_minimum_size.y = 160
	_quiz_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_quiz_panel)
	var quiz_content := VBoxContainer.new()
	quiz_content.add_theme_constant_override("separation", 6)
	_quiz_panel.add_child(quiz_content)
	_question = Label.new()
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_style(_question, 18, NAV_FONT, TEXT)
	quiz_content.add_child(_question)
	_answers = VBoxContainer.new()
	_answers.add_theme_constant_override("separation", 4)
	quiz_content.add_child(_answers)
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_label_style(_feedback, 15, BODY_FONT, GREEN)
	quiz_content.add_child(_feedback)
	var footer_spacer := Control.new()
	footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(footer_spacer)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.custom_minimum_size.y = 52
	content.add_child(footer)
	_previous = _make_button("PREVIOUS", false)
	_previous.custom_minimum_size = Vector2(150, 48)
	_previous.pressed.connect(_previous_lesson)
	footer.add_child(_previous)
	_progress = ProgressBar.new()
	_progress.min_value = 0
	_progress.max_value = LESSONS.size()
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(180, 16)
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_progress)
	_progress_label = Label.new()
	_progress_label.custom_minimum_size.x = 72
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_label_style(_progress_label, 16, NAV_FONT, MUTED)
	footer.add_child(_progress_label)
	_next = _make_button("NEXT LESSON", true)
	_next.custom_minimum_size = Vector2(190, 48)
	_next.pressed.connect(_next_lesson)
	footer.add_child(_next)
	_practice = _make_button("PRACTICE VS AI", true)
	_practice.custom_minimum_size = Vector2(220, 48)
	_practice.pressed.connect(_start_practice)
	footer.add_child(_practice)

func _show_lesson(index: int) -> void:
	_current_lesson = clampi(index, 0, LESSONS.size() - 1)
	var lesson: Dictionary = LESSONS[_current_lesson]
	_lesson_count.text = "LESSON %02d" % (_current_lesson + 1)
	_title.text = lesson["title"]
	_subtitle.text = lesson["subtitle"]
	_body.text = lesson["body"]
	_lesson_screenshot.texture = lesson["screenshot"]
	_lesson_screenshot.tooltip_text = lesson["title"]
	_progress.value = _current_lesson + 1
	_progress_label.text = "%02d / %02d" % [_current_lesson + 1, LESSONS.size()]
	_previous.disabled = _current_lesson == 0
	_next.text = "REPLAY TUTORIAL" if _current_lesson == LESSONS.size() - 1 else "NEXT LESSON"
	_practice.visible = _current_lesson == LESSONS.size() - 1
	_answered_current = false
	_feedback.text = ""
	_feedback.add_theme_color_override("font_color", GREEN)
	_question.text = lesson["question"]
	_quiz_panel.visible = not lesson["question"].is_empty()
	for button_index in range(_lesson_buttons.size()):
		_lesson_buttons[button_index].set_pressed_no_signal(button_index == _current_lesson)
	for button in _answers.get_children():
		button.queue_free()
	_answer_buttons.clear()
	for i in range(lesson["answers"].size()):
		var answer_button := _make_button(lesson["answers"][i], false)
		answer_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		answer_button.custom_minimum_size.y = 28
		answer_button.add_theme_font_size_override("font_size", 16)
		answer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_button.add_theme_stylebox_override("normal", SECONDARY_DEFAULT)
		answer_button.add_theme_stylebox_override("hover", SECONDARY_HOVER)
		answer_button.add_theme_stylebox_override("pressed", SECONDARY_PRESSED)
		answer_button.pressed.connect(_check_answer.bind(i))
		_answers.add_child(answer_button)
		_answer_buttons.append(answer_button)
	queue_redraw()

func _check_answer(answer_index: int) -> void:
	if _answered_current:
		return
	var lesson: Dictionary = LESSONS[_current_lesson]
	if answer_index == lesson["correct"]:
		_answered_current = true
		_feedback.text = lesson["success"]
		_feedback.add_theme_color_override("font_color", GREEN)
		for button in _answer_buttons:
			button.disabled = true
	else:
		_feedback.text = "Not quite. Check the lesson above and try again."
		_feedback.add_theme_color_override("font_color", Color("#e5a09a"))

func _select_lesson(index: int) -> void:
	_show_lesson(index)

func _previous_lesson() -> void:
	_show_lesson(_current_lesson - 1)

func _next_lesson() -> void:
	if _current_lesson == LESSONS.size() - 1:
		_show_lesson(0)
	else:
		_show_lesson(_current_lesson + 1)

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://src/MainMenu/MainMenu.tscn")

func _start_practice() -> void:
	GS.close_connections()
	GS.game_decklist = GS.test_decklist.duplicate()
	GS.queue_type = GS.Types.GameType.AI_BO1_CONSTRUCTED
	get_tree().change_scene_to_file("res://src/GameBoard/GameBoard.tscn")

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PANEL_STYLE)
	return panel

func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", NAV_FONT)
	button.add_theme_font_size_override("font_size", 18)
	if not primary:
		button.add_theme_stylebox_override("normal", SECONDARY_DEFAULT)
		button.add_theme_stylebox_override("hover", SECONDARY_HOVER)
		button.add_theme_stylebox_override("pressed", SECONDARY_PRESSED)
	return button

func _set_label_style(label: Label, font_size: int, font: Font, color: Color) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

func _set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_left"):
		_previous_lesson()
	elif event.is_action_pressed("ui_right"):
		_next_lesson()
	elif event.is_action_pressed("ui_cancel"):
		_return_to_menu()
