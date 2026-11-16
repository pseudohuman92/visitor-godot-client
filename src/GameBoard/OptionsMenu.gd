extends Control

var _sfx_slider: HSlider
var _sfx_value: Label

func _ready():
	_sfx_slider = find_child("SfxVolume", true, false) as HSlider
	_sfx_value = find_child("SfxValue", true, false) as Label
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index >= 0:
		_sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0
	_update_sfx_value(_sfx_slider.value)

func _on_sfx_volume_changed(value: float):
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value / 100.0, 0.001)))
	_update_sfx_value(value)

func _update_sfx_value(value: float):
	if is_instance_valid(_sfx_value):
		_sfx_value.text = "%d%%" % roundi(value)

func _on_resume_pressed():
	SFX.play(&"ui_confirm")
	hide()

func _on_main_menu_pressed():
	SFX.play(&"ui_confirm")
	get_tree().change_scene_to_file("res://src/MainMenu/MainMenu.tscn")
