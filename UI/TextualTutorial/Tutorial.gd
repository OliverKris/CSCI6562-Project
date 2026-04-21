extends Control

@onready var back_button: AnimatedIconButton = $MarginContainer/VBoxContainer/CenterContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back)

func _on_back() -> void:
	await CustomSceneFader.change_scene_faded("res://UI/MainMenu/MainMenu.tscn")
