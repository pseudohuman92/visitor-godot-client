extends Control

var _guide_start := Vector2.ZERO
var _guide_end := Vector2.ZERO
var _guide_active := false
var _combat_routes: Array = []


func set_arrows(start: Vector2, target: Vector2, active: bool, combat_routes: Array) -> void:
	if start == _guide_start and target == _guide_end and active == _guide_active and combat_routes == _combat_routes:
		return
	_guide_start = start
	_guide_end = target
	_guide_active = active
	_combat_routes = combat_routes.duplicate(true)
	queue_redraw()


func _draw() -> void:
	for route in _combat_routes:
		_draw_arrow(route["from"], route["to"], Color("#80bddb"), 4.0)
	if _guide_active:
		_draw_arrow(_guide_start, _guide_end, Color("#f1c17b"), 4.0)


func _draw_arrow(start: Vector2, finish: Vector2, color: Color, width: float) -> void:
	var distance := start.distance_to(finish)
	if distance < 12.0:
		return
	var direction := (finish - start).normalized()
	var horizontal_direction := 1.0 if finish.x >= start.x else -1.0
	var control_a := start + Vector2(horizontal_direction * minf(distance * 0.38, 180.0), 0)
	var control_b := finish - Vector2(horizontal_direction * minf(distance * 0.18, 80.0), 0)
	var previous := start
	for index in range(1, 25):
		var t := float(index) / 24.0
		var inverse := 1.0 - t
		var point := inverse * inverse * inverse * start \
			+ 3.0 * inverse * inverse * t * control_a \
			+ 3.0 * inverse * t * t * control_b \
			+ t * t * t * finish
		var glow := color
		glow.a = 0.3
		draw_line(previous, point, glow, width + 5.0, true)
		draw_line(previous, point, color, width, true)
		previous = point

	var head_size := 14.0 if width > 3.0 else 10.0
	var left := finish - direction.rotated(0.48) * head_size
	var right := finish - direction.rotated(-0.48) * head_size
	draw_colored_polygon(PackedVector2Array([finish, left, right]), color)
	draw_circle(finish, 5.0, color)
