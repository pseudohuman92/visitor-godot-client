extends Node

const ServerMessages = preload("res://src/proto/ServerMessages.gd")
const ClientMessages = preload("res://src/proto/ClientMessages.gd")
const ServerGameMessages = preload("res://src/proto/ServerGameMessages.gd")
const ClientGameMessages = preload("res://src/proto/ClientGameMessages.gd")
const Types = preload("res://src/proto/Types.gd")
const CardScene = preload("res://src/Cards/Card.tscn")
const SquareCardScene = preload("res://src/Cards/SquareCard.tscn")
const AbilityCardScene = preload("res://src/Cards/AbilityCard.tscn")
const CollectionCardScene = preload("res://src/Cards/CollectionCard.tscn")
const DecklistCardScene = preload("res://src/Cards/DecklistCard.tscn")
const CardPreview = preload("res://src/Cards/CardPreview.gd")
#const server_name = "18.222.3.198:8080"
const server_name = "localhost:8080"
const websocket_url = "ws://"+server_name+"/profiles/"
const card_back_path = "res://assets/card-backs/Visitor_All_Factions_Card_Back(2).png"

var test_decklist = ["3;base2.ASoulforASoul",
"3;base2.Assassin",
"3;base2.Necropainter",
"3;base2.SiphonLife",
"3;base2.Baiter",
"3;base2.BloodPrice",
"3;base2.EternalSpawn",
"3;base2.InfuseLife",
"3;base2.OutofCommision",
"3;base2.Reanimator",
"3;base2.Vampireling",
"3;base2.ZombieAmalgam",
"3;base2.Contagion",
"3;base2.Ressurrector",
"3;base2.RavenousVampire",
]

var ai_vs_ai_demo_decklist = [
	"3;base2.BlitzRobbers",
	"3;base2.ExplosiveShot",
	"3;base2.PuncturingRounds",
	"3;base2.HitTeam",
	"3;base2.TacticalBriefing",
]

var collection = []
var game_decklist = []
var decklist = []
var deck_name = "New Deck"
var decklist_changed = true

var socket
var gameSocket

var userId : String
var playerId : String
var gameId : String
var draft_id : String
var aiId : String

var queue_type
var gameType
var gameState

var can_drag = true
var is_dragging = false
var dragged_card

var is_waiting = true
var is_spectating_ai_match = false
var connection_error = ""
var pending_decision = ""

var popup_cards = []
var popup_message = ""
var ability_selection_popup = false
var popup_discard_pile = false

var arrow_targets = []
var block_arrow_targets = {}

var bigger_popup

func show_card_preview(card_data, collection_card := false):
	close_bigger_popup()
	bigger_popup = CardPreview.new()
	get_tree().root.add_child(bigger_popup)
	bigger_popup.setup(card_data, collection_card)

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
	if ability_selection_popup:
		for entry in popup_cards:
			if entry is Node and is_instance_valid(entry) and entry.get_parent() == null:
				entry.queue_free()
	popup_cards = []
	popup_message = ""
	ability_selection_popup = false
	popup_discard_pile = false

func has_action():
	for c in gameState.get_player().get_hand():
		if c.get_canStudy() or c.get_canPlay() or c.get_canActivate():
			return true
	for c in gameState.get_player().get_play():
		if c.get_canStudy() or c.get_canPlay() or c.get_canActivate():
			return true
	return false

func get_server_base():
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge = Engine.get_singleton("JavaScriptBridge")
		var configured = bridge.eval("window.VISITOR_SERVER_URL || ''", true)
		if configured is String and (configured.begins_with("ws://") or configured.begins_with("wss://")):
			return configured.trim_suffix("/")
	return "ws://" + server_name

func get_profile_URL():
	return get_server_base() + "/profiles/" + userId.uri_encode()

func get_game_URL():
	var base = get_server_base()
	match gameType:
		Types.GameType.AI_BO1_CONSTRUCTED:
			return base+"/ai/"+playerId+"/"+gameId+"/"+aiId
		Types.GameType.AI_VS_AI:
			return base+"/ai-vs-ai/"+playerId+"/"+gameId+"/"+aiId
		Types.GameType.BO1_CONSTRUCTED:
			return base+"/games/"+playerId+"/"+gameId
		Types.GameType.P2_DRAFT_GAME:
			return base+"/games/"+playerId+"/"+gameId
		Types.GameType.P2_DRAFT:
			return base+"/drafts/"+playerId+"/"+gameId

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
	return !is_spectating_ai_match and !is_waiting and gameState and \
	gameState.get_activePlayer() == playerId and \
	(gameState.get_phase() == Types.Phase.MAIN_BEFORE or \
	gameState.get_phase() == Types.Phase.MAIN_AFTER or \
	gameState.get_phase() == Types.Phase.BLOCK or \
	gameState.get_phase() == Types.Phase.ATTACK_PLAY or \
	gameState.get_phase() == Types.Phase.BLOCK_PLAY)

func clear_drag():
	if is_instance_valid(dragged_card) and dragged_card.has_method("restore_drag_visual"):
		dragged_card.restore_drag_visual()
	is_dragging = false
	dragged_card = null

func close_bigger_popup():
	if is_instance_valid(bigger_popup):
		bigger_popup.visible = false
		bigger_popup.queue_free()
	bigger_popup = null

func close_connections():
	for peer in [socket, gameSocket]:
		if is_instance_valid(peer):
			peer.close()
			peer.queue_free()
	socket = null
	gameSocket = null
	is_waiting = true
	is_spectating_ai_match = false
	clear_drag()
	close_bigger_popup()
	clear_popup()
	SS.clear_selection_data()
	gameState = null
	arrow_targets.clear()
	block_arrow_targets.clear()
	pending_decision = ""
	connection_error = ""
