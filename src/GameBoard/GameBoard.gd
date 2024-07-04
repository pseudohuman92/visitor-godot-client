extends Node2D

var arrows = []
var block_arrows = []

func _ready():
	var socket = Websocket.new()
	socket.connect("initialize_game_state", initialize_game_state)
	socket.connect("got_login_response", func(): socket.joinQueue(GS.queue_type))
	GS.socket = socket
	socket.connect_to_server()

func initialize_game_state(new_state):
	GS.gameState = new_state as GS.Types.GameStateP
	GS.gameId = new_state.get_id()
	GS.playerId = new_state.get_player().get_id()

	find_child("PlayerHand").populate(new_state.get_player().get_hand())
	find_child("OpponentHand").populate(new_state.get_opponent().get_hand(), false, false)
	find_child("PlayerEnergyDisplay").find_child("AvatarContainer").set_name(new_state.get_player().get_id())
	find_child("OpponentEnergyDisplay").find_child("AvatarContainer").set_name(new_state.get_opponent().get_id())
	initialize_game_socket()

func initialize_game_socket():
	var gameSocket = GameSocket.new()
	gameSocket.connect("update_game_state", update_game_state)
	GS.gameSocket = gameSocket
	gameSocket.connect_to_server()
	find_child("LoadingPanel").set_visible(false)

func update_game_state(new_state):
	print("Update Called!!")
	GS.gameState = new_state
	if new_state.get_activePlayer() != GS.playerId:
		GS.is_waiting = true

	if new_state.get_phase() == GS.Types.Phase.MAIN_AFTER:
		remove_target_arrows(true)
		GS.block_arrow_targets = {}

	find_child("PlayerDeckSize").set_text(str(new_state.get_player().get_deckSize()))
	find_child("PlayerHand").populate(new_state.get_player().get_hand())

	var assets = []
	var units = []
	for c in new_state.get_player().get_play():
		if c.get_types().has("Unit"):
			units.append(c)
		else:
			assets.append(c)
	find_child("PlayerUnitArea").populate(units, true)
	find_child("PlayerAssetArea").populate(assets, true)

	var player_discard = new_state.get_player().get_discardPile()
	if player_discard:
		find_child("PlayerDiscard").populate([player_discard[player_discard.size()-1]])


	if new_state.get_opponent():
		var hand = []
		for i in new_state.get_opponent().get_handSize():
			hand.append(0)
		find_child("OpponentHand").populate(hand, false, false)

		find_child("OpponentDeckSize").set_text(str(new_state.get_opponent().get_deckSize()))

		assets = []
		units = []
		for c in new_state.get_opponent().get_play():
			if c.get_types().has("Unit"):
				units.append(c)
			else:
				assets.append(c)
		find_child("OpponentUnitArea").populate(units, true)
		find_child("OpponentAssetArea").populate(assets, true)

		var opponent_discard = new_state.get_opponent().get_discardPile()
		if opponent_discard:
			find_child("OpponentDiscard").populate([opponent_discard[opponent_discard.size()-1]])


	find_child("Stack").populate(new_state.get_stack())

	connect_arrow_signals("PlayerHand")
	connect_arrow_signals("PlayerUnitArea")
	connect_arrow_signals("PlayerAssetArea")
	connect_arrow_signals("OpponentHand")
	connect_arrow_signals("OpponentUnitArea")
	connect_arrow_signals("OpponentAssetArea")
	connect_arrow_signals("Stack")

	if new_state.get_phase() == GS.Types.Phase.BLOCK_PLAY:
		populate_block_arrows(new_state)

	if O.smart_pass:
		check_smart_pass(new_state)

func connect_arrow_signals(node_name):
	for c in find_child(node_name).get_children():
		var ci = c.find_child("InternalContainer")
		ci.connect("draw_target_arrows", draw_target_arrows)
		ci.connect("remove_target_arrows", remove_target_arrows)


func check_smart_pass(new_state):
	if !GS.is_waiting and new_state.get_activePlayer() == GS.playerId:
		if new_state.get_phase() == GS.Types.Phase.ATTACK and \
		!GS.can_attack():
			GS.gameSocket.select_attackers()
		elif new_state.get_phase() == GS.Types.Phase.BLOCK and \
		!GS.can_block():
			GS.gameSocket.select_blockers()
		elif GS.has_initiative() and !GS.has_action() and !SS.is_selecting():
			GS.gameSocket.pass_()
		OS.delay_msec(200)

func draw_target_arrows(block = false):
	var arr
	var color
	var store

	if block:
		arr = GS.block_arrow_targets.values()
		color = Color.NAVY_BLUE
		store = block_arrows
	else:
		arr = GS.arrow_targets
		color = Color.PALE_GOLDENROD
		store = arrows

	print("Drawing arrows. Block: ", str(block))
	print(arr)

	for a in arr:
		print("Drawing arrow for ", a)
		draw_arrow(a[0], a[1], color, store)

func remove_target_arrows(block = false):
	print("Removing arrows. Block: ", str(block))
	if block:
		for a in block_arrows:
			remove_child(a)
		block_arrows = []
	else:
		for a in arrows:
			remove_child(a)
		arrows = []
		GS.arrow_targets = []

func draw_arrow(start_id, end_id, color, store):
	var scard = find_child(start_id, true, false)
	var ecard = find_child(end_id, true, false)
	if scard and ecard:
		var scenter = scard.get_global_position() + scard.get_size()/2
		var ecenter = ecard.get_global_position() + ecard.get_size()/2
		var arrow = ColorRect.new()
		arrow.set_color(color)
		arrow.set_name(start_id+end_id)
		arrow.set_global_position(scenter)
		arrow.set_size(Vector2(scenter.distance_to(ecenter), 5))
		arrow.set_rotation(scenter.angle_to_point(ecenter))
		store.append(arrow)
		add_child(arrow)

func populate_block_arrows(state):
	GS.block_arrow_targets = {}
	remove_target_arrows(true)
	for c in state.get_player().get_play():
		if c.get_combat() and c.get_combat().get_blockedAttacker():
			GS.block_arrow_targets[c.get_id()] = [c.get_id(), c.get_combat().get_blockedAttacker()]
	for c in state.get_opponent().get_play():
		if c.get_combat() and c.get_combat().get_blockedAttacker():
			GS.block_arrow_targets[c.get_id()] = [c.get_id(), c.get_combat().get_blockedAttacker()]
	draw_target_arrows(true)


func _process(_delta):
	if GS.socket:
		GS.socket._process(_delta)
	if GS.gameSocket:
		GS.gameSocket._process(_delta)

