extends Control

const SCROLL_SPEED: float = 30.0
const FADE_DURATION: float = 0.25

@onready var bg_rect: TextureRect = $BackgroundScroll
@onready var content: Control = $Content

var _transitioning: bool = false

func _ready() -> void:
	$Content/VBoxContainer/TutorialCenter/TutorialButton.pressed.connect(_on_tutorial)
	$Content/VBoxContainer/Chapter1Center/Chapter1Button.pressed.connect(_on_chapter1)
	$Content/VBoxContainer/Chapter2Center/Chapter2Button.pressed.connect(_on_chapter2)
	$Content/VBoxContainer/ReturnCenter/ReturnButton.pressed.connect(_on_return)

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

func _go_to_level(level_id: int) -> void:
	if _transitioning:
		return
	_transitioning = true

	if Engine.has_singleton("LevelSelection"):
		Engine.get_singleton("LevelSelection").selected_level = level_id
	else:
		Engine.set_meta("selected_level", level_id)

	await CustomSceneTransition.change_scene("res://Game.tscn")
	await _fade_out_content()

func _on_tutorial() -> void:
	await _go_to_level(0)

func _on_chapter1() -> void:
	await _go_to_level(1)

func _on_chapter2() -> void:
	await _go_to_level(2)

func _on_return() -> void:
	if _transitioning:
		return
	_transitioning = true
	await CustomSceneFader.change_scene_faded("res://UI/MainMenu/MainMenu.tscn")
	await _fade_out_content()
