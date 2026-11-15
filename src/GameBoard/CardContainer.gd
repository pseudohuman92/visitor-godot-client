extends Container

# Keep serialized values, not references into mutable protobuf snapshots.
var _views = {}
var _card_bytes = {}
var _mode = ""

# Full replacement is retained for popups and callers explicitly asking for it.
func populate(cards, square=false, setup=true):
	if GS.gameState:
		clear()
		sync_cards(cards, square, setup)

# Reconcile one zone by stable card ID. Hidden cards have positional identities.
# Return only newly created views so their signals can be connected once.
func sync_cards(cards, square=false, setup=true):
	var created = []
	var mode = str(square) + ":" + str(setup)
	if _mode != mode:
		clear()
		_mode = mode
	var ordered = cards.duplicate()
	if name == "Stack":
		ordered.reverse()
	var keys = []
	for i in range(ordered.size()):
		var data = ordered[i]
		var id = str(data.get_id()) if setup and data else ""
		keys.append("card:" + id if not id.is_empty() else "position:" + str(i))
	for key in _views.keys():
		if key not in keys:
			_remove_view(key)
	for i in range(ordered.size()):
		var key = keys[i]
		var data = ordered[i]
		var bytes = data.to_bytes() if setup and data else PackedByteArray()
		var view = _views.get(key)
		if not is_instance_valid(view):
			view = GS.SquareCardScene.instantiate() if square else GS.CardScene.instantiate()
			if setup:
				view.setup(data, square)
			else:
				view.setup()
			add_child(view)
			_views[key] = view
			_card_bytes[key] = bytes
			created.append(view)
		elif _card_bytes[key] != bytes:
			# Update the existing view, preserving hover, drag and signal connections.
			view.setup(data, square)
			_card_bytes[key] = bytes
		elif setup:
			# New snapshots may contain equal values in a different generated class.
			view.find_child("InternalContainer").card = data
		if get_child(i) != view:
			move_child(view, i)
	return created

func _remove_view(key):
	var view = _views[key]
	if is_instance_valid(view):
		var internal = view.find_child("InternalContainer")
		if GS.dragged_card == internal:
			GS.clear_drag()
		if SS.selecting_card == internal:
			SS.selecting_card = null
			SS.selection_targets = []
		remove_child(view)
		view.queue_free()
	_views.erase(key)
	_card_bytes.erase(key)

func clear():
	for child in get_children():
		var internal = child.find_child("InternalContainer")
		if internal != null and GS.dragged_card == internal:
			GS.clear_drag()
		remove_child(child)
		child.queue_free()
	_views.clear()
	_card_bytes.clear()
	_mode = ""
