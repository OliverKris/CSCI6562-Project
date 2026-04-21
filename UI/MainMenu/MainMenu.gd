class_name MainMenu
extends Control

## How many levels exist. Keep in sync with GameController.level_scenes array.
const LEVEL_COUNT: int = 3  # update this as you add levels

@onready var play_button: TextureButton = $VBoxContainer/PlayCenter/PlayButton
@onready var tutorial_button: TextureButton = $VBoxContainer/TutorialCenter/TutorialButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitCenter/QuitButton
@onready var bg_rect: TextureRect = $BackgroundScroll

var level_select: OptionButton = null

const SCROLL_SPEED: float = 30.0

## Single source of truth for the scroll offset, shared with LevelSelect.gd.
static var shared_scroll_offset: float = 0.0

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	tutorial_button.pressed.connect(_on_tutorial)
	quit_button.pressed.connect(_on_quit)
	_apply_offset()

func _process(delta: float) -> void:
	if bg_rect == null or bg_rect.texture == null:
		return
	var tex_w: float = float(bg_rect.texture.get_width())
	if tex_w <= 0.0:
		return
	MainMenu.shared_scroll_offset += SCROLL_SPEED * delta
	MainMenu.shared_scroll_offset = fmod(MainMenu.shared_scroll_offset, tex_w)
	_apply_offset()

func _apply_offset() -> void:
	if bg_rect == null or bg_rect.material == null or bg_rect.texture == null:
		return
	var tex_w: float = float(bg_rect.texture.get_width())
	if tex_w > 0.0:
		bg_rect.material.set_shader_parameter("offset", MainMenu.shared_scroll_offset / tex_w)

func _on_play() -> void:
	var chosen_index: int = 0
	if level_select != null:
		chosen_index = level_select.get_selected_id()
	if Engine.has_singleton("LevelSelection"):
		LevelSelection.selected_level = chosen_index
	get_tree().change_scene_to_file("res://UI/LevelSelect/LevelSelect.tscn")

func _on_tutorial() -> void:
	get_tree().change_scene_to_file("res://UI/TextualTutorial/Tutorial.tscn")

func _on_quit() -> void:
	get_tree().quit()
