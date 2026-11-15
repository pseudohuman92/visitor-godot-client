extends Node2D
## Curved, non-interactive targeting indicator. Geometry changes only when its
## endpoints change; the small moving glints and reticle animate separately.
var tint := Color("e5c180")
var _start := Vector2.ZERO
var _end := Vector2.ZERO
var _control_a := Vector2.ZERO
var _control_b := Vector2.ZERO
var _clock := 0.0
var _initialized := false
var _strokes = []
var _head: Polygon2D
var _head_shadow: Polygon2D
var _accents: Node2D

func _ready():
	z_index = 100
	_strokes.append(_stroke("Shadow", 10.0, Color(0.015, 0.025, 0.035, 0.55)))
	_strokes.append(_stroke("Glow", 16.0, Color(tint, 0.07)))
	var line = _stroke("Line", 4.0, tint)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(tint, 0.35))
	gradient.set_color(1, tint.lightened(0.12))
	line.gradient = gradient
	var taper = Curve.new()
	taper.add_point(Vector2(0, 0.35))
	taper.add_point(Vector2(0.25, 1.0))
	taper.add_point(Vector2(0.85, 0.9))
	taper.add_point(Vector2(1, 0.45))
	line.width_curve = taper
	_strokes.append(line)
	_strokes.append(_stroke("Highlight", 1.0, Color(tint.lightened(0.65), 0.40)))
	var shape = PackedVector2Array([Vector2.ZERO, Vector2(-22, -9), Vector2(-16, 0), Vector2(-22, 9)])
	_head_shadow = Polygon2D.new()
	_head_shadow.name = "HeadShadow"
	_head_shadow.polygon = shape
	_head_shadow.color = Color(0.01, 0.02, 0.03, 0.65)
	_head_shadow.antialiased = true
	add_child(_head_shadow)
	_head = Polygon2D.new()
	_head.name = "Head"
	_head.polygon = shape
	_head.color = tint.lightened(0.15)
	_head.antialiased = true
	add_child(_head)
	_accents = Node2D.new()
	_accents.name = "Accents"
	add_child(_accents)
	_accents.draw.connect(_draw_accents)

func _stroke(node_name, width, color):
	var line = Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)
	return line

func set_endpoints(start, end):
	visible = start.distance_to(end) >= 24.0
	if not visible:
		return
	if _initialized and _start.is_equal_approx(start) and _end.is_equal_approx(end):
		return
	_start = start
	_end = end
	_initialized = true
	var delta = end - start
	var length = delta.length()
	visible = length >= 24.0
	if not visible:
		return
	var direction = delta / length
	var normal = Vector2(direction.y, -direction.x)
	var bend = minf(100.0, length * 0.20)
	_control_a = start + delta * 0.30 + normal * bend
	_control_b = end - delta * 0.30 + normal * bend
	var points = PackedVector2Array()
	for i in range(41):
		points.append(start.bezier_interpolate(_control_a, _control_b, end, i / 40.0))
	for stroke in _strokes:
		stroke.points = points
	_head.position = end
	_head.rotation = (end - _control_b).angle()
	_head_shadow.position = end + Vector2(0, 2)
	_head_shadow.rotation = _head.rotation
	_accents.queue_redraw()

func _process(delta):
	_clock += delta
	if visible and _initialized:
		_accents.queue_redraw()

func _draw_accents():
	if not _initialized or not visible:
		return
	# Small origin socket and restrained destination reticle.
	_accents.draw_circle(_start, 6.0, Color("14242d"))
	_accents.draw_arc(_start, 5.0, 0, TAU, 32, Color(tint, 0.85), 1.5, true)
	var radius = 11.0 + sin(_clock * 2.8) * 1.0
	_accents.draw_arc(_end, radius, 0, TAU, 40, Color(tint, 0.25), 1.0, true)
	# Glints communicate direction without an intrusive dashed line.
	for i in range(3):
		var t = fmod(_clock * 0.26 + i / 3.0, 1.0)
		var point = _start.bezier_interpolate(_control_a, _control_b, _end, t)
		var opacity = sin(t * PI) * 0.75
		_accents.draw_circle(point, 4.0, Color(tint, opacity * 0.12))
		_accents.draw_circle(point, 1.7, Color(tint.lightened(0.6), opacity))
