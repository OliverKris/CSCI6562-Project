class_name MainMenu
extends Control

const LEVEL_COUNT: int = 3
const SCROLL_SPEED: float = 30.0
const FADE_DURATION: float = 0.25

@onready var play_button: TextureButton = $Content/VBoxContainer/PlayCenter/PlayButton
@onready var tutorial_button: TextureButton = $Content/VBoxContainer/TutorialCenter/TutorialButton
@onready var quit_button: TextureButton = $Content/VBoxContainer/QuitCenter/QuitButton
@onready var bg_rect: TextureRect = $BackgroundScroll
@onready var content: Control = $Content

var level_select: OptionButton = null
var _transitioning: bool = false

static var shared_scroll_offset: float = 0.0

func _ready() -> void:
	AudioManager.play_main_menu_music()

	play_button.pressed.connect(_on_play)
	tutorial_button.pressed.connect(_on_tutorial)
	quit_button.pressed.connect(_on_quit)

	_apply_offset()
	_setup_content_fade_state()
	await _fade_in_content()

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

func _setup_content_fade_state() -> void:
	if content == null:
		return
	content.modulate.a = 0.0

func _fade_in_content() -> void:
	if content == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

func _fade_out_content() -> void:
	if content == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(content, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished

func _on_play() -> void:
	await CustomSceneFader.change_scene_faded("res://UI/LevelSelect/LevelSelect.tscn")

func _on_tutorial() -> void:
	await CustomSceneFader.change_scene_faded("res://UI/TextualTutorial/Tutorial.tscn")

func _on_quit() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_out_content()
	get_tree().quit()
