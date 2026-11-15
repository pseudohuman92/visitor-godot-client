extends Node
## Gameplay cues follow authoritative snapshots, not speculative button presses.

signal effect_played(effect: StringName)

const SOUNDS = {
	&"card_draw": preload("res://assets/audio/card_draw.wav"),
	&"card_play": preload("res://assets/audio/card_play.wav"),
	&"study": preload("res://assets/audio/study.wav"),
	&"attack": preload("res://assets/audio/attack.wav"),
	&"damage": preload("res://assets/audio/damage.wav"),
	&"turn_end": preload("res://assets/audio/turn_end.wav"),
	&"ui_confirm": preload("res://assets/audio/ui_confirm.wav"),
	&"victory": preload("res://assets/audio/victory.wav"),
}

var _players: Dictionary = {}
var _previous: Dictionary = {}
var _finished_game := ""

func _ready():
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_volume_db(AudioServer.bus_count - 1, -8.0)
	for effect in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = SOUNDS[effect]
		player.bus = &"SFX"
		player.max_polyphony = 3
		add_child(player)
		_players[effect] = player

func play(effect: StringName):
	if _players.has(effect):
		_players[effect].play()
		effect_played.emit(effect)

func reset_match():
	_previous.clear()
	_finished_game = ""
	for effect in _players:
		# Let the menu click finish when it opens a new match.
		if effect != &"ui_confirm":
			_players[effect].stop()

func finish_match(game_id: String, won: bool):
	if game_id != _finished_game:
		_finished_game = game_id
		if won:
			play(&"victory")

func observe(state):
	if state == null or state.get_player() == null or state.get_opponent() == null:
		return
	var current := _snapshot(state)
	if _previous.is_empty() or current.id != _previous.id:
		_finished_game = ""
		if not current.hand.is_empty():
			play(&"card_draw")
	else:
		if _has_new_ids(current.hand, _previous.hand) and current.deck < _previous.deck:
			play(&"card_draw")
		# A card resolving from stack to battlefield is one play, not two.
		if _has_new_ids(current.table, _previous.table):
			play(&"card_play")
		if current.study > _previous.study:
			play(&"study")
		if _has_new_ids(current.attackers, _previous.attackers):
			play(&"attack")
		if current.health < _previous.health or current.opponent_health < _previous.opponent_health:
			play(&"damage")
		if current.turn != _previous.turn:
			play(&"turn_end")
	_previous = current

func _has_new_ids(current: Array, previous: Array) -> bool:
	for id in current:
		if id not in previous:
			return true
	return false

func _ids(cards) -> Array:
	var ids := []
	for card in cards:
		ids.append(card.get_id())
	return ids

func _snapshot(state) -> Dictionary:
	var player = state.get_player()
	var opponent = state.get_opponent()
	# Copy scalars and IDs: protobuf objects can be mutated in place.
	return {
		"id": state.get_id(),
		"hand": _ids(player.get_hand()),
		"deck": player.get_deckSize(),
		"table": _ids(state.get_stack()) + _ids(player.get_play()) + _ids(opponent.get_play()),
		"study": player.get_maxEnergy(),
		"attackers": state.get_attackers().duplicate(),
		"health": player.get_health(),
		"opponent_health": opponent.get_health(),
		"turn": state.get_turnPlayer(),
	}
