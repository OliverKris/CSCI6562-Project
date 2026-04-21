extends Control

@onready var bg_rect: TextureRect = $BackgroundScroll

const SCROLL_SPEED: float = 30.0

func _ready() -> void:
	$VBoxContainer/TutorialButton.pressed.connect(_on_tutorial)
	$VBoxContainer/Chapter1Button.pressed.connect(_on_chapter1)
	$VBoxContainer/Chapter2Button.pressed.connect(_on_chapter2)
	$VBoxContainer/ReturnButton.pressed.connect(_on_return)
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

func _go_to_level(level_id: int) -> void:
	if Engine.has_singleton("LevelSelection"):
		Engine.get_singleton("LevelSelection").selected_level = level_id
	else:
		Engine.set_meta("selected_level", level_id)
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_tutorial() -> void:
	_go_to_level(0)

func _on_chapter1() -> void:
	_go_to_level(1)

func _on_chapter2() -> void:
	_go_to_level(2)

func _on_return() -> void:
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
