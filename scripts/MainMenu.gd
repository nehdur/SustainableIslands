extends Control

@onready var play_button: Button = $CenterContainer/VBox/MenuPanel/MenuVBox/PlayButton
@onready var settings_button: Button = $CenterContainer/VBox/MenuPanel/MenuVBox/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBox/MenuPanel/MenuVBox/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	print("Play pressed")
	# TODO: get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_settings_pressed() -> void:
	print("Settings pressed")
	# TODO: get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
