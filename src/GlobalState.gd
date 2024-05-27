extends Node2D

const ServerMessages = preload("res://src/proto/ServerMessages.gd")
const ClientMessages = preload("res://src/proto/ClientMessages.gd")
const ServerGameMessages = preload("res://src/proto/ServerGameMessages.gd")
const ClientGameMessages = preload("res://src/proto/ClientGameMessages.gd")
const Types = preload("res://src/proto/Types.gd")
const CardScene = preload("res://src/Card.tscn")
const SquareCardScene = preload("res://src/SquareCard.tscn")
const AbilityCardScene = preload("res://src/AbilityCard.tscn")
const server_name = "localhost:8080"
const websocket_url = "ws://"+server_name+"/profiles/"
const card_back_path = "res://assets/CardBack.png"

var decklist = ["3;test.Hasty",
			"3;test.ActivatedAbility1",
			"3;test.SingleTargetCantrip",
			"3;test.MultiTargetCantrip",
			"3;test.ActivatedAbility2"]

var socket
var gameSocket

var userId : String
var playerId : String
var gameId : String
var aiId : String

var gameType
var gameState

var select_from_type
var selection_info
var selected = []
enum targeting_for {PLAY, ACTIVATE, NONE}
var targeting_card
var targeting_type

var can_drag = true
var is_dragging = false
var dragged_card

var is_waiting = true

var selectingX = false

var popup_cards = []
var popup_message = ""
var ability_selection_popup = false

var arrow_targets = []

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

func is_selecting():
	return (selection_info and selection_info.get_possibleTargets()) or \
	(gameState and gameState.get_activePlayer() == playerId and \
	(gameState.get_phase() == Types.Phase.ATTACK or \
		gameState.get_phase() == Types.Phase.BLOCK))

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

const text_icons = {
	"{U}": "res://assets/card-components/knowledge-U.png",
	"{G}": "res://assets/card-components/knowledge-G.png",
	"{P}": "res://assets/card-components/knowledge-P.png",
	"{R}": "res://assets/card-components/knowledge-R.png",
	"{Y}": "res://assets/card-components/knowledge-Y.png",
	"{USE}": "res://assets/card-back-2.png",
}

func get_card_image(set_name, card_name):
	return load("res://assets/card-images/"+set_name+"/"+card_name+".jpg")

func get_type_icon(type):
	return load ("res://assets/card-components/"+type+".png")

func to_knowledge_string(knowledge):
	var s = ""
	for knw in knowledge:
		var label = ""
		match knw.get_knowledge():
			GS.Types.Knowledge.BLUE:
				label = "B"
			GS.Types.Knowledge.GREEN:
				label = "G"
			GS.Types.Knowledge.RED:
				label = "R"
			GS.Types.Knowledge.PURPLE:
				label = "P"
			GS.Types.Knowledge.YELLOW:
				label = "Y"

		var count = knw.get_count()
		for i in count:
			s += label
	return s

func to_array_string(arr, sep = " "):
	var res = ""
	for s in arr:
		res += s + sep
	return res
