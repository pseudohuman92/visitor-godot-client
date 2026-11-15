extends Node2D

var arrows = []
var block_arrows = []
var _state_revision = 0
var _zone_bytes = {}
var _display_values = {}
@export_range(0.0, 2.0, 0.01) var card_move_duration := 0.28
var _card_movement
const CARD_ZONES = ["PlayerHand", "PlayerUnitArea", "PlayerAssetArea", "PlayerDiscard", "OpponentUnitArea", "OpponentAssetArea", "OpponentDiscard", "Stack"]

func _ready():
	GS.close_connections()
	var socket = Websocket.new()
	socket.connect("initialize_game_state", initialize_game_state)
	socket.connect("got_login_response", func(): socket.joinQueue(GS.queue_type))
	GS.socket = socket
	socket.connect_to_server()

func initialize_game_state(new_state):
	GS.gameState = new_state
	GS.gameId = new_state.get_id()
	GS.playerId = new_state.get_player().get_id()

	find_child("PlayerEnergyDisplay").find_child("AvatarContainer").set_name(new_state.get_player().get_id())
	find_child("OpponentEnergyDisplay").find_child("AvatarContainer").set_name(new_state.get_opponent().get_id())
	initialize_game_socket()
	update_game_state(new_state)

func initialize_game_socket():
	var gameSocket = GameSocket.new()
	gameSocket.connect("update_game_state", update_game_state)
	GS.gameSocket = gameSocket
	gameSocket.connect_to_server()
	find_child("LoadingPanel").set_visible(false)

func update_game_state(new_state):
	# Capture before reconciliation detaches obsolete source views. Initial deal
	# has no previous visible positions and intentionally does not animate.
	var origins = _capture_card_origins() if not _zone_bytes.is_empty() else {}
	GS.gameState = new_state
	_state_revision += 1
	if new_state.get_activePlayer() != GS.playerId:
		GS.is_waiting = true

	_sync_player(new_state.get_player(), "Player")
	_sync_player(new_state.get_opponent(), "Opponent")
	_sync_zone("Stack", new_state.get_stack())
	_animate_zone_changes(origins)

	_sync_local_block_selections()
	# Reconcile indicators without discarding unchanged hover/block arrows.
	_refresh_hover_arrows()
	if new_state.get_phase() == GS.Types.Phase.MAIN_AFTER:
		if not block_arrows.is_empty() or not GS.block_arrow_targets.is_empty():
			remove_target_arrows(true)
			GS.block_arrow_targets.clear()
	elif new_state.get_phase() == GS.Types.Phase.BLOCK_PLAY:
		populate_block_arrows(new_state)
	else:
		_sync_arrows(GS.block_arrow_targets.values(), true)

	if O.smart_pass:
		check_smart_pass_deferred(new_state, _state_revision)

func _capture_card_origins():
	var origins = {}
	for zone_name in CARD_ZONES:
		for view in find_child(zone_name).get_children():
			var data = view.find_child("InternalContainer").card
			if data and not data.get_id().is_empty():
				var rect = _card_movement.current_rect(data.get_id(), view) if is_instance_valid(_card_movement) else _screen_card_rect(view)
				origins[data.get_id()] = {"zone": zone_name, "rect": rect}
	return origins

func _screen_card_rect(view):
	var transform = view.get_global_transform_with_canvas()
	var offset = Vector2.ZERO
	var internal = view.find_child("InternalContainer")
	if internal != null and internal.has_method("get_hover_offset"):
		offset = internal.get_hover_offset()
	return Rect2(transform * offset, view.size * transform.get_scale().abs())

func _animate_zone_changes(origins):
	var destinations = {}
	for zone_name in CARD_ZONES:
		for view in find_child(zone_name).get_children():
			var data = view.find_child("InternalContainer").card
			if data and not data.get_id().is_empty():
				destinations[data.get_id()] = {"zone": zone_name, "view": view, "data": data}
	if is_instance_valid(_card_movement):
		for id in _card_movement.motions.keys():
			if not destinations.has(id):
				_card_movement.cancel(id)
	for id in destinations:
		var target = destinations[id]
		if not origins.has(id) or origins[id].zone == target.zone:
			if is_instance_valid(_card_movement):
				_card_movement.refresh(id, target.data, target.zone.ends_with("UnitArea") or target.zone.ends_with("AssetArea"))
			continue
		if not is_instance_valid(_card_movement):
			_card_movement = preload("res://src/GameBoard/CardMovement.gd").new()
			_card_movement.name = "CardMovement"
			add_child(_card_movement)
		_card_movement.duration = card_move_duration
		_card_movement.animate(id, target.view, target.data, target.zone.ends_with("UnitArea") or target.zone.ends_with("AssetArea"), origins[id].rect)

func _card_center(id, view):
	if is_instance_valid(_card_movement) and _card_movement.motions.has(id):
		var rect = _card_movement.current_rect(id, view)
		return get_global_transform_with_canvas().affine_inverse() * rect.get_center()
	return get_global_transform_with_canvas().affine_inverse() * _screen_card_rect(view).get_center()

func _sync_player(player, prefix):
	_set_text_if_changed(prefix + "DeckSize", str(player.get_deckSize()) if player else "0")
	var energy = [player.get_energy(), player.get_maxEnergy(), player.get_health()] if player else []
	if _display_values.get(prefix + "Energy") != energy:
		find_child(prefix + "EnergyDisplay").update_player(player)
		_display_values[prefix + "Energy"] = energy
	var knowledge = []
	if player:
		for group in player.get_knowledgePool():
			knowledge.append([group.get_knowledge(), group.get_count()])
	if _display_values.get(prefix + "Knowledge") != knowledge:
		find_child(prefix + "KnowledgeDisplay").update_pool(player.get_knowledgePool() if player else [])
		_display_values[prefix + "Knowledge"] = knowledge

	if prefix == "Opponent":
		var hand = []
		hand.resize(player.get_handSize() if player else 0)
		_sync_zone("OpponentHand", hand, false, false)
	else:
		_sync_zone("PlayerHand", player.get_hand() if player else [])
	var units = []
	var assets = []
	if player:
		for card in player.get_play():
			if card.get_types().has("Unit"):
				units.append(card)
			else:
				assets.append(card)
	_sync_zone(prefix + "UnitArea", units, true)
	_sync_zone(prefix + "AssetArea", assets, true)
	var discarded = player.get_discardPile() if player else []
	_sync_zone(prefix + "Discard", [discarded.back()] if discarded else [])

func _set_text_if_changed(node_name, value):
	if _display_values.get(node_name) != value:
		find_child(node_name).text = value
		_display_values[node_name] = value

func _sync_zone(node_name, cards, square=false, setup=true):
	var values = []
	if setup:
		for card in cards:
			values.append(card.to_bytes())
	else:
		values.append(cards.size())
	if _zone_bytes.get(node_name) == values and find_child(node_name).get_child_count() == cards.size():
		# Refresh data references without touching the scene tree or presentation.
		if setup:
			var zone = find_child(node_name)
			var ordered = cards.duplicate()
			if node_name == "Stack":
				ordered.reverse()
			for i in range(ordered.size()):
				zone.get_child(i).find_child("InternalContainer").card = ordered[i]
		return
	var created = find_child(node_name).sync_cards(cards, square, setup)
	_zone_bytes[node_name] = values
	connect_arrow_signals(node_name, created)

func connect_arrow_signals(node_name, cards=null):
	var views = find_child(node_name).get_children() if cards == null else cards
	for view in views:
		var internal = view.find_child("InternalContainer")
		if not internal.draw_target_arrows.is_connected(draw_target_arrows):
			internal.draw_target_arrows.connect(draw_target_arrows)
		if not internal.remove_target_arrows.is_connected(remove_target_arrows):
			internal.remove_target_arrows.connect(remove_target_arrows)

func _sync_local_block_selections():
	# Reused card nodes must not retain flags from a completed selection cycle.
	for key in SS.selected.keys():
		var pair = SS.selected[key]
		if pair is Array and pair.size() == 2:
			if not is_instance_valid(pair[0]) or not is_instance_valid(pair[1]) or not pair[0].is_inside_tree() or not pair[1].is_inside_tree():
				SS.selected.erase(key)
				GS.block_arrow_targets.erase(key)
	for zone_name in ["PlayerUnitArea", "OpponentUnitArea"]:
		for view in find_child(zone_name).get_children():
			var internal = view.find_child("InternalContainer")
			internal.blocking = false
			internal.blocked = false
	for pair in SS.selected.values():
		if pair is Array and pair.size() == 2:
			pair[0].blocking = true
			pair[1].blocked = true

func _refresh_hover_arrows():
	var targets = []
	for zone_name in ["PlayerHand", "PlayerUnitArea", "PlayerAssetArea", "OpponentUnitArea", "OpponentAssetArea", "Stack"]:
		for view in find_child(zone_name).get_children():
			var internal = view.find_child("InternalContainer")
			if internal.hover and internal.card:
				for target_id in internal.card.get_targets():
					targets.append([internal.card.get_id(), target_id])
	if GS.arrow_targets != targets:
		GS.arrow_targets = targets
	_sync_arrows(targets, false)

func _sync_arrows(targets, block):
	var store = block_arrows if block else arrows
	var desired = {}
	for pair in targets:
		desired[JSON.stringify(pair)] = pair
	var existing = {}
	for arrow in store.duplicate():
		var key = JSON.stringify([arrow.get_meta("start_id"), arrow.get_meta("end_id")])
		if desired.has(key) and not existing.has(key):
			existing[key] = arrow
		else:
			store.erase(arrow)
			remove_child(arrow)
			arrow.queue_free()
	for key in desired:
		if not existing.has(key):
			var pair = desired[key]
			draw_arrow(pair[0], pair[1], Color("80bddb") if block else Color("e5c180"), store)

func check_smart_pass_deferred(new_state, revision):
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or revision != _state_revision:
		return
	if O.smart_pass and GS.pending_decision.is_empty() and not GS.popup_cards:
		check_smart_pass(new_state)

func check_smart_pass(new_state):
	if not GS.is_waiting and new_state.get_activePlayer() == GS.playerId:
		if new_state.get_phase() == GS.Types.Phase.ATTACK and not GS.can_attack():
			GS.gameSocket.select_attackers()
		elif new_state.get_phase() == GS.Types.Phase.BLOCK and not GS.can_block():
			GS.gameSocket.select_blockers()
		elif GS.has_initiative() and not GS.has_action() and not SS.is_selecting():
			GS.gameSocket.pass_()

func draw_target_arrows(block = false):
	_sync_arrows(GS.block_arrow_targets.values() if block else GS.arrow_targets, block)

func remove_target_arrows(block = false):
	var store = block_arrows if block else arrows
	for arrow in store:
		if is_instance_valid(arrow):
			remove_child(arrow)
			arrow.queue_free()
	store.clear()
	if not block:
		GS.arrow_targets.clear()

func draw_arrow(start_id, end_id, color, store):
	var arrow = preload("res://src/GameBoard/TargetArrow.gd").new()
	arrow.name = "TargetArrow"
	arrow.tint = color
	arrow.set_meta("start_id", start_id)
	arrow.set_meta("end_id", end_id)
	add_child(arrow)
	store.append(arrow)
	update_arrow(arrow)

func _arrow_attachment(id, view, towards):
	var center = _card_center(id, view)
	var rect = _card_movement.current_rect(id, view) if is_instance_valid(_card_movement) else _screen_card_rect(view)
	var inverse = get_global_transform_with_canvas().affine_inverse()
	var half_size = ((inverse * rect.end) - (inverse * rect.position)).abs() * 0.5
	var direction = (towards - center).normalized()
	var x_distance = half_size.x / absf(direction.x) if absf(direction.x) > 0.001 else INF
	var y_distance = half_size.y / absf(direction.y) if absf(direction.y) > 0.001 else INF
	return center + direction * (minf(x_distance, y_distance) + 9.0)

func update_arrow(arrow):
	var start_id = arrow.get_meta("start_id")
	var end_id = arrow.get_meta("end_id")
	var source = find_child(start_id, true, false)
	var target = find_child(end_id, true, false)
	if not is_instance_valid(source) or not is_instance_valid(target):
		arrow.visible = false
		return
	var source_center = _card_center(start_id, source)
	var target_center = _card_center(end_id, target)
	if source_center.distance_to(target_center) < 24.0:
		arrow.visible = false
		return
	var start = _arrow_attachment(start_id, source, target_center)
	var end = _arrow_attachment(end_id, target, source_center)
	# Containers can temporarily overlap while sorting; suppress reversed arrows.
	if (end - start).dot(target_center - source_center) <= 0:
		arrow.visible = false
		return
	arrow.visible = true
	arrow.set_endpoints(start, end)

func populate_block_arrows(state):
	var assignments = {}
	for player in [state.get_player(), state.get_opponent()]:
		if not player:
			continue
		for card in player.get_play():
			if card.get_combat() and card.get_combat().get_blockedAttacker():
				assignments[card.get_id()] = [card.get_id(), card.get_combat().get_blockedAttacker()]
	GS.block_arrow_targets = assignments
	_sync_arrows(assignments.values(), true)

func _process(_delta):
	for arrow in arrows + block_arrows:
		if is_instance_valid(arrow):
			update_arrow(arrow)
	if not GS.connection_error.is_empty():
		find_child("LoadingText").text = GS.connection_error + "\nPress Escape to return to the menu."
	if GS.socket:
		GS.socket._process(_delta)
	if GS.gameSocket:
		GS.gameSocket._process(_delta)

func _exit_tree():
	_state_revision += 1
	GS.close_connections()
