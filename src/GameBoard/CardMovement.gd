extends CanvasLayer
## Presentation-only copies travel above clipping containers. Destination cards
## keep their layout slots and are restored when movement ends or is cancelled.

var duration := 0.28
var motions = {}
var _overlay: Control

func _ready():
	layer = 20
	_overlay = Control.new()
	_overlay.name = "MovingCards"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func screen_rect(view):
	var transform = view.get_global_transform_with_canvas()
	return Rect2(transform.origin, view.size * transform.get_scale().abs())

func current_rect(id, fallback):
	if motions.has(id) and is_instance_valid(motions[id].ghost):
		return screen_rect(motions[id].ghost)
	return screen_rect(fallback)

func animate(id, destination, data, square, origin):
	cancel(id)
	if duration <= 0 or origin.size.x <= 0 or origin.size.y <= 0:
		return
	var ghost = GS.SquareCardScene.instantiate() if square else GS.CardScene.instantiate()
	ghost.setup(data, square)
	ghost.name = "MovingCard"
	_disable_input(ghost)
	ghost.process_mode = Node.PROCESS_MODE_DISABLED
	_overlay.add_child(ghost)
	ghost.size = destination.size.max(destination.custom_minimum_size).max(Vector2.ONE)
	var internal = ghost.find_child("InternalContainer")
	internal.display = true
	internal.hover = false
	var entry = {
		"ghost": ghost,
		"destination": weakref(destination),
		"original_modulate": destination.modulate,
		"origin": origin,
		"progress": 0.0,
		"tween": null,
		"input_state": [],
		"input_ids": {},
		"data_bytes": data.to_bytes(),
	}
	_disable_input(destination, entry.input_state, entry.input_ids)
	motions[id] = entry
	# Modulate preserves the Container slot; hide() would collapse its layout.
	destination.modulate = Color(destination.modulate, 0)
	_sample(0.0, id)
	var tween = create_tween()
	entry.tween = tween
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_sample.bind(id), 0.0, 1.0, duration)
	tween.tween_callback(_finish.bind(id))

func refresh(id, data, square):
	if not motions.has(id):
		return
	var entry = motions[id]
	var bytes = data.to_bytes()
	if entry.data_bytes == bytes:
		return
	entry.data_bytes = bytes
	entry.ghost.setup(data, square)
	entry.ghost.name = "MovingCard"
	entry.ghost.find_child("InternalContainer").display = true
	_disable_input(entry.ghost)
	var destination = entry.destination.get_ref()
	if is_instance_valid(destination):
		# A changed card can create new cost-symbol controls during a flight.
		_disable_input(destination, entry.input_state, entry.input_ids)
	_sample(entry.progress, id)

func _sample(progress, id):
	if not motions.has(id):
		return
	var entry = motions[id]
	var destination = entry.destination.get_ref()
	if not is_instance_valid(destination) or not destination.is_inside_tree() or destination.is_queued_for_deletion():
		cancel(id)
		return
	entry.progress = progress
	# Read the destination on every sample, including after Container sorting,
	# scrolling, resize or another snapshot that changes neighbouring cards.
	var target = screen_rect(destination)
	var rect = Rect2(entry.origin.position.lerp(target.position, progress), entry.origin.size.lerp(target.size, progress))
	var overlay_inverse = _overlay.get_global_transform_with_canvas().affine_inverse()
	entry.ghost.position = overlay_inverse * rect.position
	entry.ghost.scale = rect.size / entry.ghost.size.max(Vector2.ONE)

func _finish(id):
	if not motions.has(id):
		return
	var entry = motions[id]
	_restore(entry)
	entry.ghost.queue_free()
	motions.erase(id)

func cancel(id):
	if not motions.has(id):
		return
	var entry = motions[id]
	if entry.tween != null and entry.tween.is_valid():
		entry.tween.kill()
	_restore(entry)
	if is_instance_valid(entry.ghost):
		entry.ghost.queue_free()
	motions.erase(id)

func _restore(entry):
	var destination = entry.destination.get_ref()
	if is_instance_valid(destination):
		destination.modulate = entry.original_modulate
	for item in entry.input_state:
		var node = item.node.get_ref()
		if is_instance_valid(node):
			node.mouse_filter = item.mouse_filter
			node.focus_mode = item.focus_mode

func _disable_input(node, saved=null, known=null):
	if node is Control:
		if saved != null and (known == null or not known.has(node.get_instance_id())):
			if known != null:
				known[node.get_instance_id()] = true
			saved.append({"node": weakref(node), "mouse_filter": node.mouse_filter, "focus_mode": node.focus_mode})
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_input(child, saved, known)

func _exit_tree():
	for id in motions.keys():
		cancel(id)
