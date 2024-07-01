extends Node

const ServerMessages = preload("res://src/proto/ServerMessages.gd")
const ClientMessages = preload("res://src/proto/ClientMessages.gd")
const ServerGameMessages = preload("res://src/proto/ServerGameMessages.gd")
const ClientGameMessages = preload("res://src/proto/ClientGameMessages.gd")
const Types = preload("res://src/proto/Types.gd")
const CardScene = preload("res://src/GameBoard/Card.tscn")
const SquareCardScene = preload("res://src/GameBoard/SquareCard.tscn")
const AbilityCardScene = preload("res://src/GameBoard/AbilityCard.tscn")
const CollectionCardScene = preload("res://src/DeckBuilder/CollectionCard.tscn")
const DecklistCardScene = preload("res://src/DeckBuilder/DecklistCard.tscn")
const server_name = "18.222.3.198:8080"
const websocket_url = "ws://"+server_name+"/profiles/"
const card_back_path = "res://assets/CardBack.png"

var game_decklist = ["3;test.Defendery",
			"3;test.MultiTargetCantrip",
			"3;test.MultiActivatedAbilitiesWithMultiTargeting"]

var collection = []
var decklist = []
var deck_name = "New Deck"
var decklist_changed = true

var socket
var gameSocket

var userId : String
var playerId : String
var gameId : String
var aiId : String

var gameType
var gameState

var can_drag = true
var is_dragging = false
var dragged_card

var is_waiting = true

var popup_cards = []
var popup_message = ""
var ability_selection_popup = false

var arrow_targets = []

var bigger_popup

func can_attack():
	for c in gameState.get_player().get_play():
		if c.get_canAttack():
			return true
	return false

func can_block():
	for c in gameState.get_player().get_play():
		if c.get_canBlock():
			return true
	return false


func clear_popup():
	popup_cards = []
	popup_message = ""
	ability_selection_popup = false

func has_action():
	for c in gameState.get_player().get_hand():
		if c.get_canStudy() or c.get_canPlay() or c.get_canActivate():
			return true
	for c in gameState.get_player().get_play():
		if c.get_canStudy() or c.get_canPlay() or c.get_canActivate():
			return true
	return false

func get_game_URL():
	match gameType:
		Types.GameType.AI_BO1_CONSTRUCTED:
			return "ws://"+server_name+"/ai/"+playerId+"/"+gameId+"/"+aiId
		Types.GameType.BO1_CONSTRUCTED:
			return "ws://"+server_name+"/games/"+playerId+"/"+gameId
		Types.GameType.P2_DRAFT:
			return "ws://"+server_name+"/drafts/"+playerId+"/"+gameId

func get_phase_name():
	if !gameState or gameState.get_phase() == Types.Phase.NOPHASE:
		return ""
	else:
		match gameState.get_phase():
			Types.Phase.REDRAW:
				return "Redraw"
			Types.Phase.BEGIN:
				return "Begin"
			Types.Phase.MAIN_BEFORE:
				return "Main Before"
			Types.Phase.ATTACK:
				return "Attack"
			Types.Phase.ATTACK_PLAY:
				return "Attack Play"
			Types.Phase.BLOCK:
				return "Block"
			Types.Phase.BLOCK_PLAY:
				return "Block Play"
			Types.Phase.MAIN_AFTER:
				return "Main After"
			Types.Phase.END:
				return "End"
	return "UNKNOWN"

func has_initiative():
	return !is_waiting and gameState and \
	gameState.get_activePlayer() == playerId and \
	(gameState.get_phase() == Types.Phase.MAIN_BEFORE or \
	gameState.get_phase() == Types.Phase.MAIN_AFTER or \
	gameState.get_phase() == Types.Phase.ATTACK_PLAY or \
	gameState.get_phase() == Types.Phase.BLOCK_PLAY)




