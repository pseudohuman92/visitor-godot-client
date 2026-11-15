extends Node
## Run: godot --headless --path . res://tests/regression.tscn
## Requires the original game's assets. No backend or network connection is used.

class TestBoard:
	extends "res://src/GameBoard/GameBoard.gd"
	var match_initialized = false
	func _ready():
		pass
	func initialize_game_socket():
		match_initialized = true

class CaptureSocket:
	extends "res://src/GameSocket.gd"
	var sent = []
	func send_message(message):
		sent.append(message.to_bytes())
		GS.is_waiting = true
		return OK

@onready var root = get_tree().root
var checks = 0
var failures = []

func _ready():
	call_deferred("run")

func expect(condition, description):
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: ", description)

func sample_card(protocol = null, cost = "2"):
	if protocol == null:
		protocol = GS.Types
	var card = protocol.CardP.new()
	card.set_id("sample")
	card.set_name("Sample")
	card.set_set("test")
	card.set_cost(cost)
	card.add_types("Unit")
	card.set_controller("player")
	card.new_combat().set_health(3)
	return card

func populate_state(state):
	state.set_id("game")
	state.set_activePlayer("player")
	state.set_turnPlayer("player")
	state.set_phase(GS.Types.Phase.MAIN_BEFORE)
	state.new_player().set_id("player")
	state.new_opponent().set_id("opponent")
	return state

func write_deck(path, text):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func run():
	O.smart_pass = false
	GS.playerId = "player"
	var socket = CaptureSocket.new()
	GS.gameSocket = socket
	socket.update_game_state.connect(func(state): GS.gameState = state)

	# Generated state classes must be accepted without a cross-script cast.
	var state = populate_state(GS.ServerMessages.GameStateP.new())
	state.get_player().get_hand().append(sample_card(GS.ServerMessages))
	var board = load("res://src/GameBoard/GameBoard.tscn").instantiate()
	board.set_script(TestBoard)
	root.add_child(board)
	board.initialize_game_state(state)
	expect(GS.gameState == state, "Initial state retains its actual generated type")
	expect(board.match_initialized, "Initialisation opens the match connection")
	expect(board.find_child("PlayerHand").get_child_count() == 1, "Initial snapshot populates the hand")

	# Numeric and symbolic costs have a deterministic natural ordering.
	var two = sample_card(GS.Types, "2")
	var ten = sample_card(GS.Types, "10")
	var symbolic = sample_card(GS.Types, "X")
	expect(CS.compare_cost_name_cardP(two, ten), "Cost 2 sorts before cost 10")
	expect(not CS.compare_cost_name_cardP(ten, two), "Cost ordering is asymmetric")
	expect(CS.compare_cost_name_cardP(ten, symbolic), "Numeric cost sorts before X")
	expect(not CS.compare_cost_name_cardP(two, two), "Equal cards do not compare as less")

	# Displaying a stack must not mutate the snapshot's array order.
	var stack = board.find_child("Stack")
	var first = sample_card()
	first.set_id("first")
	var second = sample_card()
	second.set_id("second")
	var cards = [first, second]
	stack.populate(cards)
	expect(cards[0] == first and cards[1] == second, "Stack display leaves model order intact")
	expect(stack.get_child(0).name == "second", "Stack is displayed in reverse order")
	var old_view = stack.get_child(0)
	stack.clear()
	await get_tree().process_frame
	expect(not is_instance_valid(old_view), "Cleared card nodes are freed")

	# Exactly-full pages must not expose a trailing empty page.
	var collection = load("res://src/DeckBuilder/Collection.gd").new()
	GS.collection = []
	for i in range(32):
		GS.collection.append(two)
	collection.populate()
	expect(collection.max_page == 0 and collection.get_child_count() == 32, "32 cards fit exactly one page")
	GS.collection.append(ten)
	collection.populate()
	expect(collection.max_page == 1, "33 cards expose a second page")
	GS.collection.clear()
	collection.page = 5
	collection.populate()
	expect(collection.page == 0 and collection.max_page == 0, "Empty collection clamps the page")
	collection.free()

	# The ability object belongs in Setup's third argument.
	var ability = GS.Types.TargetingAbility.new()
	ability.set_id("ability")
	ability.set_text("Choose a target.")
	var ability_view = GS.AbilityCardScene.instantiate()
	ability_view.setup(two, false, ability)
	expect(ability_view.get_child(0).targeting_ability == ability, "Ability view receives the selected ability")
	ability_view.free()

	# Native drag end resets globals even when no destination accepted the card.
	var drag_view = GS.CardScene.instantiate()
	drag_view.setup(two)
	var internal = drag_view.find_child("InternalContainer")
	GS.dragged_card = internal
	GS.is_dragging = true
	internal._notification(Control.NOTIFICATION_DRAG_END)
	expect(not GS.is_dragging and GS.dragged_card == null, "Cancelled drag clears shared state")
	var drop = load("res://src/GameBoard/DropArea.gd").new()
	drop.name = "PlayContainer"
	expect(not drop._can_drop_data(Vector2.ZERO, 42), "Drop target rejects unrelated data")
	drop.free()
	drag_view.free()

	# The actual Godot signal accepts both normal and blocking-arrow flags.
	var signal_view = GS.CardScene.instantiate()
	var signal_card = signal_view.find_child("InternalContainer")
	var flags = []
	signal_card.draw_target_arrows.connect(func(block): flags.append(block))
	signal_card.draw_target_arrows.emit(false)
	signal_card.draw_target_arrows.emit(true)
	expect(flags == [false, true], "Target-arrow signals carry their block flag")
	signal_view.free()

	# Arrows follow controls after layout changes and do not intercept input.
	var source = Control.new()
	source.name = "source"
	source.size = Vector2(40, 60)
	board.add_child(source)
	var target = Control.new()
	target.name = "target"
	target.position = Vector2(200, 80)
	target.size = Vector2(60, 80)
	board.add_child(target)
	board.draw_arrow("source", "target", Color.WHITE, board.arrows)
	var arrow = board.arrows.back()
	var original_endpoint = arrow.get_node("Line").points[-1]
	target.position += Vector2(50, 20)
	board.update_arrow(arrow)
	expect(arrow.get_node("Line").points[-1] != original_endpoint and arrow.get_node("Head").position == arrow.get_node("Line").points[-1], "Arrow endpoint and head follow a moved target")
	expect(arrow.get_node("Head") is Polygon2D, "Arrow has a non-interactive arrowhead")
	var curve = arrow.get_node("Line").points
	expect(curve.size() > 2 and not curve[curve.size() / 2].is_equal_approx(curve[0].lerp(curve[-1], 0.5)), "Target arrow follows a curved path")
	expect(arrow.get_node("Glow") is Line2D and arrow.get_node("Shadow") is Line2D, "Arrow has layered glow and contrast")
	expect(arrow.get_node("Line").width_curve != null and arrow.get_node("Line").gradient != null, "Arrow stroke has taper and a colour gradient")
	expect(not arrow.get_node("Line").points[-1].is_equal_approx(board._card_center("target", target)), "Target arrow attaches outside the card text area")
	var short_arrow = load("res://src/GameBoard/TargetArrow.gd").new()
	root.add_child(short_arrow)
	short_arrow.set_endpoints(Vector2.ZERO, Vector2(10, 0))
	short_arrow.visible = true
	short_arrow.set_endpoints(Vector2.ZERO, Vector2(10, 0))
	expect(not short_arrow.visible, "Repeated short-arrow updates stay hidden")
	short_arrow.queue_free()
	board.remove_target_arrows()
	await get_tree().process_frame
	expect(not is_instance_valid(arrow), "Removed arrows are freed")
	source.queue_free()
	target.queue_free()

	# Discard displays clear when a new snapshot contains no discarded cards.
	state.get_player().get_discardPile().append(sample_card(GS.ServerMessages))
	board.update_game_state(state)
	expect(board.find_child("PlayerDiscard").get_child_count() == 1, "Discard displays its top card")
	state.get_player().get_discardPile().clear()
	board.update_game_state(state)
	expect(board.find_child("PlayerDiscard").get_child_count() == 0, "Empty discard clears the old top card")

	# The game-end method name must match the generated schema.
	var ended = []
	socket.game_ended.connect(func(win): ended.append(win))
	var end_message = GS.ServerGameMessages.ServerGameMessage.new()
	var end_payload = end_message.new_gameEnd()
	populate_state(end_payload.new_game())
	end_payload.set_win(true)
	socket.decode_proto_message(end_message.to_bytes())
	expect(ended == [true], "Game-end packet decodes without an accessor error")

	# An automatic selection must retain the request's message type before replying.
	var select_message = GS.ServerGameMessages.ServerGameMessage.new()
	var selection = select_message.new_selectFrom()
	populate_state(selection.new_game())
	selection.set_messageType(GS.Types.SelectFromType.PLAY)
	var requirement = selection.new_targets()
	requirement.set_id("choice")
	requirement.set_minTargets(1)
	requirement.set_maxTargets(1)
	requirement.add_possibleTargets("only-target")
	socket.decode_proto_message(select_message.to_bytes())
	var response = GS.ClientGameMessages.ClientGameMessage.new()
	response.from_bytes(socket.sent.back())
	expect(response.get_selectFromResponse().get_messageType() == GS.Types.SelectFromType.PLAY, "Auto-selection serializes the correct request type")
	expect(response.get_selectFromResponse().get_selected() == ["only-target"], "Auto-selection submits the sole valid target")

	# Every declared but unfinished decision type is handled explicitly, without passing.
	var requests = []
	socket.decision_requested.connect(func(kind, _request): requests.append(kind))
	for kind in ["orderCards", "selectXValue", "assignDamage", "selectKnowledge", "pickCard"]:
		var message = GS.ServerGameMessages.ServerGameMessage.new()
		var payload = message.call("new_" + kind)
		if payload.has_method("new_game"):
			populate_state(payload.new_game())
		socket.decode_proto_message(message.to_bytes())
		expect(GS.pending_decision == kind and GS.is_waiting, "Unfinished decision blocks accidental pass: " + kind)
	expect(requests.size() == 5, "All remaining protocol variants emit an explicit decision request")
	GS.pending_decision = ""
	GS.connection_error = ""
	SS.clear_selection_data()

	# Parsing is atomic and rejects malformed, missing and over-limit deck entries.
	var path = "user://regression.deck"
	write_deck(path, "Example\n2;test.Sample\n\n")
	var parsed = CS.read_deck_file(path)
	expect(not parsed.has("error") and parsed.lines == ["2;test.Sample"], "Valid deck parses with blank lines")
	for text in ["", "Example\nbroken\n", "Example\n0;test.Sample\n", "Example\n4;test.Sample\n", "Example\n2;test.Sample\n2;test.Sample\n"]:
		write_deck(path, text)
		expect(CS.read_deck_file(path).has("error"), "Malformed deck is rejected: " + text.replace("\n", "/"))
	expect(CS.read_deck_file("user://does-not-exist.deck").has("error"), "Missing deck is reported safely")
	var deck_button = load("res://src/DeckBuilder/Buttons.gd").new()
	GS.collection = [two]
	GS.decklist = [ten]
	GS.deck_name = "Original"
	write_deck(path, "Replacement\n1;missing.Unknown\n")
	deck_button._on_file_dialog_file_selected(path)
	expect(GS.deck_name == "Original" and GS.decklist == [ten], "Unknown cards leave the existing deck unchanged")
	write_deck(path, "Loaded\n2;test.Sample\n")
	deck_button._on_file_dialog_file_selected(path)
	expect(GS.deck_name == "Loaded" and GS.decklist.size() == 2, "Valid deck replaces the edited deck")
	GS.deck_name = "regression-saved"
	deck_button.save()
	parsed = CS.read_deck_file("user://regression-saved.deck")
	expect(not parsed.has("error") and parsed.lines == ["2;test.Sample"], "Deck save/load round trip preserves counts")
	deck_button.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://regression-saved.deck"))

	# Repeated updates reuse a finite number of cost-symbol nodes.
	var cost_view = GS.CardScene.instantiate()
	var cost_area = cost_view.find_child("CostArea")
	var knowledge = GS.Types.KnowledgeGroup.new()
	knowledge.set_knowledge(GS.Types.Knowledge.BLUE)
	knowledge.set_count(1)
	cost_area.update("2", [knowledge])
	var child_count = cost_area.get_child_count()
	cost_area.update("", [knowledge])
	expect(cost_area.get_child_count() == child_count, "Cost refresh does not accumulate old symbols")
	expect(not cost_area.find_child("CostBG").visible, "Clearing a cost hides its previous value")
	cost_view.free()

	# Delayed smart-pass checks must respect newer state and ongoing targeting.
	GS.gameState = state
	GS.is_waiting = false
	GS.pending_decision = ""
	GS.connection_error = ""
	GS.popup_cards.clear()
	SS.clear_selection_data()
	O.smart_pass = true
	var prior_messages = socket.sent.size()
	board.check_smart_pass_deferred(state, board._state_revision)
	board._state_revision += 1
	await get_tree().create_timer(0.25).timeout
	expect(socket.sent.size() == prior_messages, "Stale smart-pass timer cannot send an action")
	SS.selection_targets = ["pending-target"]
	board.check_smart_pass_deferred(state, board._state_revision)
	await get_tree().create_timer(0.25).timeout
	expect(socket.sent.size() == prior_messages, "Smart pass waits for target selection")
	SS.clear_selection_data()
	board.check_smart_pass_deferred(state, board._state_revision)
	await get_tree().create_timer(0.25).timeout
	expect(socket.sent.size() == prior_messages + 1, "Valid smart pass sends after a non-blocking delay")
	O.smart_pass = false

	# An unbounded target list is not the same as a zero-target requirement.
	var unbounded = GS.Types.Targeting.new()
	unbounded.set_id("unbounded")
	unbounded.set_minTargets(1)
	unbounded.set_maxTargets(-1)
	unbounded.add_possibleTargets("a")
	unbounded.add_possibleTargets("b")
	var completions = []
	SS.process_selections([unbounded], two, func(id): completions.append(id), SS.selection_type.PLAY)
	expect(SS.is_selecting() and completions.is_empty(), "Unbounded selection waits for user input")
	SS.selected_single = ["a"]
	SS.submit_selection()
	expect(completions == [two.get_id()], "Unbounded selection completes after submission")
	SS.clear_selection_data()

	await check_socket_transport()

	# No connected backend is needed to safely close either WebSocket wrapper.
	var profile = Websocket.new()
	profile.close()
	profile.free()
	var match_socket = GameSocket.new()
	match_socket.close()
	match_socket.free()
	expect(true, "Godot 4 socket lifecycle methods complete without errors")

	board.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await check_incremental_updates()
	await check_zone_movement()
	print("Regression checks: ", checks, "; failures: ", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func check_socket_transport():
	# Real binary WebSocket exchange against an ephemeral local peer, not the backend.
	var listener = TCPServer.new()
	var error = listener.listen(0, "127.0.0.1")
	expect(error == OK, "Loopback server can listen")
	if error != OK:
		return
	var client = GameSocket.new()
	var received = []
	client.update_game_state.connect(func(state): received.append(state))
	error = client._client.connect_to_url("ws://127.0.0.1:%d/test" % listener.get_local_port())
	client._polling = error == OK
	var remote = null
	for i in range(100):
		if remote == null and listener.is_connection_available():
			remote = WebSocketPeer.new()
			remote.accept_stream(listener.take_connection())
		if remote != null:
			remote.poll()
		client._process(0)
		if client._client.get_ready_state() == WebSocketPeer.STATE_OPEN and remote != null and remote.get_ready_state() == WebSocketPeer.STATE_OPEN:
			break
		await get_tree().create_timer(0.002).timeout
	var opened = client._client.get_ready_state() == WebSocketPeer.STATE_OPEN
	expect(opened, "Godot WebSocket handshake completes")
	if opened:
		client.keep()
		for i in range(100):
			remote.poll()
			client._process(0)
			if remote.get_available_packet_count() > 0:
				break
			await get_tree().create_timer(0.002).timeout
		var got_packet = remote.get_available_packet_count() > 0
		expect(got_packet, "GameSocket sends a binary action")
		if got_packet:
			var response = GS.ClientGameMessages.ClientGameMessage.new()
			response.from_bytes(remote.get_packet())
			expect(response.has_keep() and not remote.was_string_packet(), "Binary action preserves protobuf payload")
		var update = GS.ServerGameMessages.ServerGameMessage.new()
		populate_state(update.new_updateGameStateP().new_game())
		remote.send(update.to_bytes(), WebSocketPeer.WRITE_MODE_BINARY)
		for i in range(100):
			remote.poll()
			client._process(0)
			if not received.is_empty():
				break
			await get_tree().create_timer(0.002).timeout
		expect(received.size() == 1 and not GS.is_waiting, "GameSocket polls and decodes a real binary snapshot")
	client.close()
	client.free()
	if remote != null:
		remote.close()
	listener.stop()

func check_incremental_updates():
	O.smart_pass = false
	GS.is_waiting = false
	GS.playerId = "player"
	SS.clear_selection_data()
	var state = populate_state(GS.ServerMessages.GameStateP.new())
	var player = state.get_player()
	var first = sample_card(GS.ServerMessages)
	first.set_id("hand-first")
	var first_knowledge = first.add_knowledgeCost()
	first_knowledge.set_knowledge(GS.Types.Knowledge.BLUE)
	first_knowledge.set_count(1)
	var second = sample_card(GS.ServerMessages)
	second.set_id("hand-second")
	player.get_hand().append_array([first, second])
	var unit = sample_card(GS.ServerMessages)
	unit.set_id("unit")
	player.get_play().append(unit)
	state.get_opponent().set_handSize(2)
	var board = load("res://src/GameBoard/GameBoard.tscn").instantiate()
	board.set_script(TestBoard)
	root.add_child(board)
	board.initialize_game_state(state)
	var hand = board.find_child("PlayerHand")
	var first_view = hand.get_child(0)
	var second_view = hand.get_child(1)
	var first_internal = first_view.find_child("InternalContainer")
	var second_internal = second_view.find_child("InternalContainer")
	var first_art = first_internal.find_child("CardImage").get_theme_stylebox("panel")
	var second_art = second_internal.find_child("CardImage").get_theme_stylebox("panel")
	var first_symbol = first_internal.find_child("CostArea").children[0]
	var unit_view = board.find_child("PlayerUnitArea").get_child(0)
	var changes = []
	hand.child_entered_tree.connect(func(_node): changes.append("added"))
	hand.child_exiting_tree.connect(func(_node): changes.append("removed"))

	# A freshly decoded but equal snapshot must not recreate or redraw any card.
	var equal_state = GS.ServerGameMessages.GameStateP.new()
	equal_state.from_bytes(state.to_bytes())
	GS.gameState = equal_state # Decoder may already have replaced GS before the callback.
	board.update_game_state(equal_state)
	expect(changes.is_empty(), "Equal snapshot does not modify the hand scene tree")
	expect(hand.get_child(0) == first_view and hand.get_child(1) == second_view, "Equal snapshots preserve card identities")
	expect(first_internal.card == equal_state.get_player().get_hand()[0], "Equal snapshot refreshes the backing data reference")
	expect(first_internal.find_child("CostArea").children[0] == first_symbol, "Equal snapshot preserves cost-symbol nodes")
	expect(first_internal.find_child("CardImage").get_theme_stylebox("panel") == first_art, "Equal snapshot does not rerender unchanged cards")

	# Changes outside card zones update their labels without touching card content.
	equal_state.get_player().set_health(17)
	equal_state.get_player().set_energy(4)
	equal_state.get_player().set_maxEnergy(6)
	equal_state.get_player().set_deckSize(31)
	var pool = equal_state.get_player().add_knowledgePool()
	pool.set_knowledge(GS.Types.Knowledge.BLUE)
	pool.set_count(2)
	board.update_game_state(equal_state)
	expect(changes.is_empty() and hand.get_child(0) == first_view, "Player-stat changes do not rebuild the hand")
	expect(first_internal.find_child("CostArea").children[0] == first_symbol, "Player-stat changes do not redraw card contents")
	expect(board.find_child("PlayerEnergyDisplay").find_child("EnergyLabel").text == "4/6", "Energy display updates on changed values")
	expect(board.find_child("PlayerEnergyDisplay").find_child("HealthLabel").text == "17", "Health display updates on changed values")
	expect(board.find_child("PlayerDeckSize").text == "31", "Deck-size label updates independently")
	expect(board.find_child("PlayerKnowledgeDisplay").find_child("BLabel").text == "2", "Knowledge pool updates independently")

	# Mutating the exact same protobuf instance still compares against cached bytes.
	var current_first = equal_state.get_player().get_hand()[0]
	current_first.get_combat().set_health(7)
	current_first.get_combat().set_shield(2)
	board.update_game_state(equal_state)
	expect(hand.get_child(0) == first_view and changes.is_empty(), "Changed card updates in place")
	expect(first_internal.find_child("Health").text == "7", "Changed card health is refreshed")
	expect(first_internal.find_child("Shield").visible and first_internal.find_child("Shield").text == "2", "Reused card restores a previously hidden shield")
	expect(second_internal.find_child("CardImage").get_theme_stylebox("panel") == second_art, "Changing one card does not rerender its neighbour")
	expect(board.find_child("PlayerUnitArea").get_child(0) == unit_view, "Changing a hand card preserves other zones")

	# Reordering keeps existing nodes and connects each signal exactly once.
	equal_state.get_player().get_hand().reverse()
	board.update_game_state(equal_state)
	expect(hand.get_child(0) == second_view and hand.get_child(1) == first_view, "Hand reorder moves existing nodes")
	expect(changes.is_empty(), "Reordering causes no card creation or removal")
	expect(first_internal.draw_target_arrows.get_connections().size() == 1, "Reused cards have one arrow-signal connection")

	# Hidden cards use stable positional identities as their count changes.
	var opponent_hand = board.find_child("OpponentHand")
	var hidden_first = opponent_hand.get_child(0)
	var hidden_second = opponent_hand.get_child(1)
	equal_state.get_opponent().set_handSize(3)
	board.update_game_state(equal_state)
	expect(opponent_hand.get_child_count() == 3 and opponent_hand.get_child(0) == hidden_first and opponent_hand.get_child(1) == hidden_second, "Growing a hidden hand preserves existing backs")
	equal_state.get_opponent().set_handSize(1)
	board.update_game_state(equal_state)
	expect(opponent_hand.get_child_count() == 1 and opponent_hand.get_child(0) == hidden_first, "Shrinking a hidden hand removes only excess backs")

	# Unchanged hover arrows persist through unrelated and equal snapshots.
	var current_second = equal_state.get_player().get_hand()[0]
	current_second.add_targets("opponent")
	board.update_game_state(equal_state)
	second_internal._on_mouse_entered()
	var hover_arrow = board.arrows.back()
	equal_state.get_player().set_health(16)
	board.update_game_state(equal_state)
	expect(second_internal.hover and board.arrows[0] == hover_arrow, "Unrelated updates preserve hover and its arrow")

	# Removal affects only the missing card and safely cancels its active drag.
	GS.dragged_card = first_internal
	GS.is_dragging = true
	equal_state.get_player().get_hand().pop_back()
	board.update_game_state(equal_state)
	expect(hand.get_child_count() == 1 and hand.get_child(0) == second_view, "Removal preserves the other hand cards")
	expect(not GS.is_dragging and GS.dragged_card == null, "Removing a dragged card clears dragging")
	await get_tree().process_frame
	expect(not is_instance_valid(first_view), "Removed incremental view is freed")

	# Card additions leave surviving nodes untouched.
	var added = sample_card(GS.ServerGameMessages)
	added.set_id("new-hand-card")
	equal_state.get_player().get_hand().append(added)
	board.update_game_state(equal_state)
	expect(hand.get_child_count() == 2 and hand.get_child(0) == second_view, "Addition creates only the new card")

	# Server-confirmed block arrows also keep identity until the relationship changes.
	equal_state.set_phase(GS.Types.Phase.BLOCK_PLAY)
	var attacker = sample_card(GS.ServerGameMessages)
	attacker.set_id("attacker")
	equal_state.get_opponent().get_play().append(attacker)
	equal_state.get_player().get_play()[0].get_combat().set_blockedAttacker("attacker")
	board.update_game_state(equal_state)
	var block_arrow = board.block_arrows[0]
	board.update_game_state(equal_state)
	expect(board.block_arrows[0] == block_arrow, "Equal block assignments preserve their arrow")
	equal_state.get_player().get_play()[0].get_combat().set_blockedAttacker("")
	board.update_game_state(equal_state)
	expect(board.block_arrows.is_empty() and board.arrows[0] == hover_arrow, "Removing a block leaves the hover arrow intact")

	# Leaving a local selection cycle clears flags on nodes that are now reused.
	var unit_internal = unit_view.find_child("InternalContainer")
	var attacker_internal = board.find_child("OpponentUnitArea").get_child(0).find_child("InternalContainer")
	equal_state.set_phase(GS.Types.Phase.BLOCK)
	SS.selected["unit"] = [unit_internal, attacker_internal]
	GS.block_arrow_targets["unit"] = ["unit", "attacker"]
	board.update_game_state(equal_state)
	expect(unit_internal.blocking and attacker_internal.blocked, "Incremental updates preserve pending local block selections")
	SS.clear_selection_data()
	equal_state.set_phase(GS.Types.Phase.MAIN_AFTER)
	board.update_game_state(equal_state)
	expect(not unit_internal.blocking and not attacker_internal.blocked, "Completed block selection clears stale flags")

	# Clearing a pool hides only the removed knowledge indicators.
	equal_state.get_player().get_knowledgePool().clear()
	board.update_game_state(equal_state)
	expect(not board.find_child("PlayerKnowledgeDisplay").find_child("BContainer").visible, "Removed knowledge groups are hidden")
	board.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func check_zone_movement():
	O.smart_pass = false
	GS.playerId = "player"
	var state = populate_state(GS.ServerMessages.GameStateP.new())
	var moving = sample_card(GS.ServerMessages)
	moving.set_id("moving")
	var untouched = sample_card(GS.ServerMessages)
	untouched.set_id("untouched")
	state.get_player().get_hand().append_array([moving, untouched])
	var board = load("res://src/GameBoard/GameBoard.tscn").instantiate()
	board.set_script(TestBoard)
	board.card_move_duration = 0.20
	root.add_child(board)
	board.initialize_game_state(state)
	await get_tree().process_frame
	await get_tree().process_frame
	expect(not is_instance_valid(board._card_movement), "Initial snapshot does not animate the initial deal")
	var hand = board.find_child("PlayerHand")
	var source = hand.get_child(0)
	var stable_view = hand.get_child(1)
	var origin = board._screen_card_rect(source)
	expect(origin.size.x > 0 and origin.size.y > 0, "Animation captures a laid-out source rectangle")
	moving.get_combat().set_health(5)
	board.update_game_state(state)
	expect(not is_instance_valid(board._card_movement), "In-place stat changes do not start a movement")

	state.get_player().get_hand().erase(moving)
	state.get_stack().append(moving)
	board.update_game_state(state)
	var animation = board._card_movement
	expect(is_instance_valid(animation) and animation.motions.has("moving"), "Hand-to-stack move starts an animation")
	var first_motion = animation.motions.moving
	var ghost = first_motion.ghost
	var destination = board.find_child("Stack").get_child(0)
	expect(animation.screen_rect(ghost).position.is_equal_approx(origin.position), "Moving copy begins at the old screen position")
	expect(animation.screen_rect(ghost).size.is_equal_approx(origin.size), "Moving copy begins at the old card size")
	expect(destination.visible and destination.modulate.a == 0, "Destination reserves its slot without drawing a duplicate")
	expect(ghost.mouse_filter == Control.MOUSE_FILTER_IGNORE and ghost.find_child("InternalContainer").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Moving copy ignores mouse input")
	expect(destination.find_child("InternalContainer").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Invisible destination cannot receive clicks")
	expect(hand.get_child(0) == stable_view and stable_view.modulate.a == 1, "Unchanged neighbours remain visible and keep identity")

	await get_tree().create_timer(0.04).timeout
	expect(first_motion.progress > 0 and first_motion.progress < 1, "Tween advances gradually through intermediate positions")
	var equal_state = GS.ServerGameMessages.GameStateP.new()
	equal_state.from_bytes(state.to_bytes())
	board.update_game_state(equal_state)
	expect(animation.motions.moving.ghost == ghost, "Equal snapshot does not restart the current movement")
	state = equal_state
	moving = state.get_stack()[0]
	moving.get_combat().set_health(8)
	board.update_game_state(state)
	expect(animation.motions.moving.ghost == ghost and ghost.find_child("Health").text == "8", "Changed card data refreshes the moving copy without restarting it")

	# Retarget before the first flight completes; start from the visible ghost.
	var interrupted_rect = animation.screen_rect(ghost)
	state.get_stack().clear()
	state.get_player().get_play().append(moving)
	board.update_game_state(state)
	var second_motion = animation.motions.moving
	var square_destination = board.find_child("PlayerUnitArea").get_child(0)
	expect(second_motion.ghost != ghost, "Consecutive zone changes replace the old presentation copy")
	expect(second_motion.origin.position.is_equal_approx(interrupted_rect.position) and second_motion.origin.size.is_equal_approx(interrupted_rect.size), "Interrupted movement resumes from its current visible rectangle")
	expect(ghost.is_queued_for_deletion(), "Interrupted movement releases its old copy")
	expect(square_destination.modulate.a == 0, "Square destination waits for the moving copy")
	var current_ghost = second_motion.ghost
	await get_tree().create_timer(0.30).timeout
	expect(animation.motions.is_empty(), "Completed tween removes its bookkeeping entry")
	expect(square_destination.modulate.a == 1 and square_destination.visible, "Completion restores destination visibility")
	expect(square_destination.find_child("InternalContainer").mouse_filter != Control.MOUSE_FILTER_IGNORE, "Completion restores destination mouse handling")
	expect(not is_instance_valid(current_ghost), "Completed moving copy is freed")
	expect(board.find_child("PlayerUnitArea").get_child(0) == square_destination, "Animation does not replace the destination view")

	# A card removed by a newer snapshot cancels its movement safely.
	state.get_player().get_play().clear()
	state.get_player().get_discardPile().append(moving)
	board.update_game_state(state)
	expect(animation.motions.has("moving"), "Battlefield-to-discard move is animated")
	var discarded_ghost = animation.motions.moving.ghost
	state.get_player().get_discardPile().clear()
	board.update_game_state(state)
	expect(not animation.motions.has("moving"), "Removing a destination cancels its movement")
	await get_tree().process_frame
	expect(not is_instance_valid(discarded_ghost), "Cancelled moving copy is freed")

	# A duration of zero is an explicit reduced-motion option.
	board.card_move_duration = 0.0
	state.get_player().get_hand().append(moving)
	board.update_game_state(state)
	await get_tree().process_frame
	state.get_player().get_hand().erase(moving)
	state.get_stack().append(moving)
	board.update_game_state(state)
	expect(animation.motions.is_empty() and board.find_child("Stack").get_child(0).modulate.a == 1, "Zero duration performs an immediate visible move")

	# Scene exit during a live flight cancels tweens and releases their copies.
	board.card_move_duration = 0.20
	await get_tree().process_frame
	state.get_stack().clear()
	state.get_player().get_play().append(moving)
	board.update_game_state(state)
	var exit_ghost = animation.motions.moving.ghost
	board.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(not is_instance_valid(animation) and not is_instance_valid(exit_ghost), "Scene exit releases the animation layer and moving cards")
