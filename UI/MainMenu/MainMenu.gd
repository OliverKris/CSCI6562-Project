extends Control

## How many levels exist. Keep in sync with GameController.level_scenes array.
const LEVEL_COUNT: int = 3  # update this as you add levels

@onready var play_button: TextureButton = $VBoxContainer/PlayCenter/PlayButton
@onready var tutorial_button: TextureButton = $VBoxContainer/TutorialCenter/TutorialButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitCenter/QuitButton
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
	var chosen_index: int = 0
	if level_select != null:
		chosen_index = level_select.get_selected_id()

	# Guard against LevelSelection not yet being registered as an Autoload.
	# To register: Project > Project Settings > Autoload > add LevelSelection.gd as "LevelSelection"
	if Engine.has_singleton("LevelSelection"):
		LevelSelection.selected_level = chosen_index

	await CustomSceneTransition.change_scene("res://Game.tscn")

func _on_tutorial() -> void:
	get_tree().change_scene_to_file("res://UI/TextualTutorial/Tutorial.tscn")

func _on_quit() -> void:
	get_tree().quit()
