extends Control

@onready var bg_rect: TextureRect = $BackgroundScroll

const SCROLL_SPEED: float = 30.0
var _scroll_offset: float = 0.0

func _ready() -> void:
	$VBoxContainer/TutorialButton.pressed.connect(_on_tutorial)
	$VBoxContainer/Chapter1Button.pressed.connect(_on_chapter1)
	$VBoxContainer/Chapter2Button.pressed.connect(_on_chapter2)
	$VBoxContainer/ReturnButton.pressed.connect(_on_return)

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

func _go_to_level(level_id: int) -> void:
	# Works whether LevelSelection is an Autoload singleton or not.
	# If you have LevelSelection as an Autoload, it will be used.
	# Otherwise we store the choice in a ProjectSettings meta as a fallback.
	if Engine.has_singleton("LevelSelection"):
		Engine.get_singleton("LevelSelection").selected_level = level_id
	else:
		# Fallback: stash in a globally-accessible meta on the Engine object
		Engine.set_meta("selected_level", level_id)
	
	await CustomSceneTransition.change_scene("res://Game.tscn")

func _on_tutorial() -> void:
	_go_to_level(0)

func _on_chapter1() -> void:
	_go_to_level(1)

func _on_chapter2() -> void:
	_go_to_level(2)

func _on_return() -> void:
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
