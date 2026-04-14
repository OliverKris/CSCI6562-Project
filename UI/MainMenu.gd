extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var tutorial_button: Button = $VBoxContainer/TutorialButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var bg_rect: TextureRect = $BackgroundScroll

# Pixels per second the background scrolls rightward
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
	var uv_offset: float = _scroll_offset / tex_w
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("offset", uv_offset)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_tutorial() -> void:
	get_tree().change_scene_to_file("res://UI/Tutorial.tscn")

func _on_quit() -> void:
	get_tree().quit()
