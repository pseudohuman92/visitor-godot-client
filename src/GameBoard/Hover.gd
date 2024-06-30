extends Control

var initial_pos

func _on_mouse_entered():
	if !GS.is_dragging:
		initial_pos = get_global_position()
		set_scale(Vector2(1.5,1.5))
		z_index = 1
		var size = get_size()
		var pos = get_global_position()-size/3
		set_global_position(Vector2(min(max(0, pos.x), 1820-size.x), min(max(0, pos.y), 930-size.y)))


func _on_mouse_exited():
	if !GS.is_dragging:
		set_scale(Vector2(1,1))
		z_index = 0
		set_global_position(initial_pos)

