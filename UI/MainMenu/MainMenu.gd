extends Control

@onready var play_button: TextureButton = $VBoxContainer/PlayButton
@onready var tutorial_button: TextureButton = $VBoxContainer/TutorialButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton
@onready var bg_rect: TextureRect = $BackgroundScroll

const SCROLL_SPEED: float = 30.0
var _scroll_offset: float = 0.0

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	tutorial_button.pressed.connect(_on_tutorial)
	quit_button.pressed.connect(_on_quit)

func _process(delta: float) -> void:
	if bg_rect == null or bg_rect.texture == null:
		return
	var tex_w: float = float(bg_rect.texture.get_width())
	if tex_w <= 0.0:
		return
	_scroll_offset += SCROLL_SPEED * delta
	_scroll_offset = fmod(_scroll_offset, tex_w)
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("offset", _scroll_offset / tex_w)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://UI/LevelSelect/LevelSelect.tscn")

func _on_tutorial() -> void:
	get_tree().change_scene_to_file("res://UI/TextualTutorial/Tutorial.tscn")

func _on_quit() -> void:
	get_tree().quit()
