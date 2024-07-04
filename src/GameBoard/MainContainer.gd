extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	O.screen_size = get_viewport_rect().size
	set_size(O.screen_size)


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://src/MainMenu/MainMenu.tscn")
