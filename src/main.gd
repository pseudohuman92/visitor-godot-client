extends Node2D

var Card = preload("res://src/Card.tscn")

func _ready():
	var socket = Websocket.new()
	socket.connect("initialize_game_state", initialize_game_state)
	socket.connect("got_login_response", func(): socket.joinQueue())
	GlobalState.socket = socket
	socket.connect_to_server()

func initialize_game_state(new_state):
	GlobalState.gameState = new_state
	GlobalState.gameId = new_state.get_id()
	var player = new_state.get_player()
	GlobalState.playerId = player.get_id()
	var playerHand = player.get_hand()
	var playerHandNode = find_child("PlayerHand")
	for card in playerHand:
		#print("Creating Player Card")
		var c = Card.instantiate()
		c.setup(card)
		playerHandNode.add_child(c)
	var opponentHandNode = find_child("OpponentHand")
	for card in new_state.get_opponent().get_handSize():
		#print("Creating Opponent Card")
		var c = Card.instantiate()
		opponentHandNode.add_child(c)
	initialize_game_socket()
	
func initialize_game_socket():
	var gameSocket = GameSocket.new()
	gameSocket.connect("update_game_state", update_game_state)
	GlobalState.gameSocket = gameSocket
	gameSocket.connect_to_server()
	
func update_game_state(new_state):
	print("Update Called!!")
	GlobalState.gameState = new_state
	
	var playerHand = new_state.get_player().get_hand()
	var playerHandNode = find_child("PlayerHand")
	var handChildren = playerHandNode.get_children() 
	handChildren.map(func(c):playerHandNode.remove_child(c))
	for card in playerHand:
		#print("Creating Player Card")
		var c = Card.instantiate()
		c.setup(card)
		playerHandNode.add_child(c)
	
	var opponent = 	new_state.get_opponent()
	if opponent:
		var opponentHandNode = find_child("OpponentHand")
		var opponentHandChildren = opponentHandNode.get_children() 
		opponentHandChildren .map(func(c):opponentHandNode.remove_child(c))
		for card in opponent.get_handSize():
			#print("Creating Opponent Card")
			var c = Card.instantiate()
			opponentHandNode.add_child(c)
		
	var stackNode = find_child("Stack")
	var stackChildren = stackNode.get_children() 
	stackChildren .map(func(c):stackNode.remove_child(c))
	for card in new_state.get_stack():
		#print("Creating Stack Card")
		var c = Card.instantiate()
		c.setup(card)
		stackNode.add_child(c)
	
	var playerPlay = new_state.get_player().get_play()
	var playerPlayNode = find_child("PlayerPlayArea")
	var playChildren = playerPlayNode.get_children() 
	playChildren.map(func(c):playerPlayNode.remove_child(c))
	for card in playerPlay:
		#print("Creating Player Card")
		var c = Card.instantiate()
		c.setup(card)
		playerPlayNode.add_child(c)

func _process(_delta):
	if GlobalState.socket:
		GlobalState.socket._process(_delta)
	if GlobalState.gameSocket:
		GlobalState.gameSocket._process(_delta)
