extends RefCounted
## Lift the visual card while its wrapper retains the Container layout slot.
## Top-level drawing lets the raised card extend beyond a ScrollContainer.
var distance := 16.0
var amount := 0.0
var _target: WeakRef
var _home := Vector2.ZERO
var _home_size := Vector2.ZERO
var _parent_size := Vector2.ZERO
var _old_top_level := false
var _old_z := 0
var _raised := false

func _init(target: Control):
	_target = weakref(target)

func update(delta: float, active: bool):
	var target = _target.get_ref()
	if not is_instance_valid(target):
		return
	if active and not _raised:
		_home = target.position
		_home_size = target.size
		_parent_size = target.get_parent().size
		_old_top_level = target.is_set_as_top_level()
		_old_z = target.z_index
		var screen_position = target.global_position
		target.set_as_top_level(true)
		target.global_position = screen_position
		target.z_index = 20
		_raised = true
	if not _raised:
		return
	var goal = distance if active else 0.0
	amount = lerpf(amount, goal, 1.0 - exp(-18.0 * maxf(delta, 0.0)))
	if absf(amount - goal) < 0.05:
		amount = goal
	var parent = target.get_parent()
	if parent.size != _parent_size and _parent_size.x > 0 and _parent_size.y > 0:
		var factor = minf(parent.size.x / _parent_size.x, parent.size.y / _parent_size.y)
		target.size = _home_size * factor
		_home = (parent.size - target.size) / 2.0
		_home_size = target.size
		_parent_size = parent.size
	target.global_position = parent.get_global_transform() * (_home - Vector2(0, amount))
	if not active and amount == 0.0:
		reset()

func reset():
	var target = _target.get_ref()
	if _raised and is_instance_valid(target):
		target.set_as_top_level(_old_top_level)
		target.position = _home
		target.z_index = _old_z
		if target.get_parent() is Container:
			target.get_parent().queue_sort()
	amount = 0.0
	_raised = false

func offset():
	return Vector2(0, -amount)
