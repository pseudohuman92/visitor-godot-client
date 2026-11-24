extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	O.screen_size = get_viewport_rect().size
	set_size(O.screen_size)


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		var scene = get_tree().current_scene
		var options: Control = null
		if scene:
			options = scene.find_child("OptionsOverlay", true, false) as Control
		if options:
			options.visible = not options.visible
		else:
			get_tree().change_scene_to_file("res://src/MainMenu/MainMenu.tscn")
