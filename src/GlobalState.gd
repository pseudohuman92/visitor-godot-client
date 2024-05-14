extends Node2D

const ServerMessages = preload("res://src/proto/ServerMessages.gd")
const ClientMessages = preload("res://src/proto/ClientMessages.gd")
const ServerGameMessages = preload("res://src/proto/ServerGameMessages.gd")
const ClientGameMessages = preload("res://src/proto/ClientGameMessages.gd")
const Types = preload("res://src/proto/Types.gd")
const server_name = "localhost:8080"
const websocket_url = "ws://"+server_name+"/profiles/"

var socket
var gameSocket

var userId
var playerId
var gameId
var gameType
var aiId
var gameState = Types.GameStateP.new()

var is_dragging = false
var can_drag = true
var is_waiting = true

func get_game_URL():
	match gameType:
		Types.GameType.AI_BO1_CONSTRUCTED:
			return "ws://"+server_name+"/ai/"+playerId+"/"+gameId+"/"+aiId
		Types.GameType.BO1_CONSTRUCTED:
			return "ws://"+server_name+"/games/"+playerId+"/"+gameId
		Types.GameType.P2_DRAFT:
			return "ws://"+server_name+"/drafts/"+playerId+"/"+gameId

func has_initiative():
	return gameState and \
	gameState.get_activePlayer() == playerId and \
	(gameState.get_phase() == Types.Phase.MAIN_BEFORE or \
	gameState.get_phase() == Types.Phase.MAIN_AFTER or \
	gameState.get_phase() == Types.Phase.ATTACK_PLAY or \
	gameState.get_phase() == Types.Phase.BLOCK_PLAY)
