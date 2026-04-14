extends Control

## How many levels exist. Keep in sync with GameController.level_scenes array.
const LEVEL_COUNT: int = 3  # update this as you add levels

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var tutorial_button: Button = $VBoxContainer/TutorialButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# Resolved in _ready() so we can use has_node() safely.
# @onready ternary initializers don't work in GDScript.
var level_select: OptionButton = null

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	tutorial_button.pressed.connect(_on_tutorial)
	quit_button.pressed.connect(_on_quit)

	# Grab the OptionButton only if it actually exists in the scene.
	if has_node("VBoxContainer/LevelSelect"):
		level_select = $VBoxContainer/LevelSelect
		level_select.clear()
		for i in range(LEVEL_COUNT):
			level_select.add_item("Level %d" % (i + 1), i)
		level_select.selected = 0

func _on_play() -> void:
	var chosen_index: int = 0
	if level_select != null:
		chosen_index = level_select.get_selected_id()

	# Guard against LevelSelection not yet being registered as an Autoload.
	# To register: Project > Project Settings > Autoload > add LevelSelection.gd as "LevelSelection"
	if Engine.has_singleton("LevelSelection"):
		LevelSelection.selected_level = chosen_index

	get_tree().change_scene_to_file("res://Game.tscn")

func _on_tutorial() -> void:
	get_tree().change_scene_to_file("res://UI/Tutorial.tscn")

func _on_quit() -> void:
	get_tree().quit()
