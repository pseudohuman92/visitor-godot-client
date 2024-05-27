extends Node2D

var arrows = []

func _ready():
	var socket = Websocket.new()
	socket.connect("initialize_game_state", initialize_game_state)
	socket.connect("got_login_response", func(): socket.joinQueue())
	GS.socket = socket
	socket.connect_to_server()

func initialize_game_state(new_state):
	GS.gameState = new_state as GS.Types.GameStateP
	GS.gameId = new_state.get_id()
	GS.playerId = new_state.get_player().get_id()

	find_child("PlayerHand").populate(new_state.get_player().get_hand())
	find_child("OpponentHand").populate(new_state.get_opponent().get_hand(), false, false)
	initialize_game_socket()

func initialize_game_socket():
	var gameSocket = GameSocket.new()
	gameSocket.connect("update_game_state", update_game_state)
	GS.gameSocket = gameSocket
	gameSocket.connect_to_server()

func update_game_state(new_state):
	print("Update Called!!")
	GS.gameState = new_state
	if new_state.get_activePlayer() != GS.playerId:
		GS.is_waiting = true

	find_child("PlayerHand").populate(new_state.get_player().get_hand())
	for c in find_child("PlayerHand").get_children():
		c.connect("draw_target_arrows", draw_target_arrows)
		c.connect("remove_target_arrows", remove_target_arrows)

	find_child("PlayerPlayArea").populate(new_state.get_player().get_play(), true)
	for c in find_child("PlayerPlayArea").get_children():
		c.connect("draw_target_arrows", draw_target_arrows)
		c.connect("remove_target_arrows", remove_target_arrows)

	var player_discard = new_state.get_player().get_discardPile()
	if player_discard:
		find_child("PlayerDiscard").populate([player_discard[player_discard.size()-1]])

	if new_state.get_opponent():
		var hand = []
		for i in new_state.get_opponent().get_handSize():
			hand.append(0)
		find_child("OpponentHand").populate(hand, false, false)
		for c in find_child("OpponentHand").get_children():
			c.connect("draw_target_arrows", draw_target_arrows)
			c.connect("remove_target_arrows", remove_target_arrows)

		find_child("OpponentPlayArea").populate(new_state.get_opponent().get_play(), true)
		for c in find_child("OpponentPlayArea").get_children():
			c.connect("draw_target_arrows", draw_target_arrows)
			c.connect("remove_target_arrows", remove_target_arrows)

		var opponent_discard = new_state.get_opponent().get_discardPile()
		if opponent_discard:
			find_child("OpponentDiscard").populate([opponent_discard[opponent_discard.size()-1]])


	find_child("Stack").populate(new_state.get_stack())
	for c in find_child("Stack").get_children():
		c.connect("draw_target_arrows", draw_target_arrows)
		c.connect("remove_target_arrows", remove_target_arrows)

	check_smart_pass(new_state)


func check_smart_pass(new_state):
	if new_state.get_activePlayer() == GS.playerId:
		if new_state.get_phase() == GS.Types.Phase.ATTACK and \
		!GS.can_attack():
			GS.gameSocket.select_attackers()
		elif new_state.get_phase() == GS.Types.Phase.BLOCK and \
		!GS.can_block():
			GS.gameSocket.select_blockers()
		#elif GS.has_initiative() and !GS.has_action() and !GS.is_selecting():
			#GS.gameSocket.pass_()
		OS.delay_msec(200)

func draw_target_arrows():
	for a in GS.arrow_targets:
		print("Drawing arrow for ", a)
		draw_arrow(a[0], a[1])

func remove_target_arrows():
	for a in arrows:
		remove_child(a)
	arrows = []
	GS.arrow_targets = []

func draw_arrow(start_id, end_id):
	var scard = find_child(start_id, true, false)
	var ecard = find_child(end_id, true, false)
	var scenter = scard.get_global_position() + scard.get_size()/2
	var ecenter = ecard.get_global_position() + ecard.get_size()/2
	var arrow = ColorRect.new()
	arrow.set_color(Color.FIREBRICK)
	arrow.set_name(start_id+end_id)
	arrow.set_global_position(scenter)
	arrow.set_size(Vector2(scenter.distance_to(ecenter), 5))
	arrow.set_rotation(scenter.angle_to_point(ecenter))
	arrows.append(arrow)
	add_child(arrow)

func _process(_delta):
	if GS.socket:
		GS.socket._process(_delta)
	if GS.gameSocket:
		GS.gameSocket._process(_delta)


func _on_opponent_display_area_gui_input(event):
	pass # Replace with function body.
