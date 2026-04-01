extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var tutorial_button: Button = $VBoxContainer/TutorialButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	tutorial_button.pressed.connect(_on_tutorial)
	quit_button.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_tutorial() -> void:
	get_tree().change_scene_to_file("res://UI/Tutorial.tscn")

func _on_quit() -> void:
	get_tree().quit()
