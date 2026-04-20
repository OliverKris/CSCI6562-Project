extends Node
class_name GameController

## Assign all playable level scenes here in the Inspector.
## Index 0 = Level 1, index 1 = Level 2, etc.
@export var level_scenes: Array[PackedScene] = []

## Which level to load on startup (0-based index into level_scenes).
@export var starting_level_index: int = 0

@export var game_camera: Camera2D

@onready var world: Node = $"../World"
@onready var level_container: Node = $"../World/LevelContainer"
@onready var units_node: Node = $"../World/Units"
@onready var battles_node: Node = $"../World/Battles"
@onready var drag_overlay: Node = $"../World/DragOverlay"
@onready var game_ui = $"../UILayer/GameUi"
@onready var ai_controller: AIController = $"../AIController"

static var selected_level: int = 0

var current_level: Node = null
var graph_map: GraphMap = null
var _current_level_index: int = -1

func _ready() -> void:
	if level_scenes.is_empty():
		push_error("GameController: no level_scenes assigned.")
		return
	
	# --- Determine which level was selected ---
	var level_index: int = GameController.selected_level

	if Engine.has_singleton("LevelSelection"):
		level_index = Engine.get_singleton("LevelSelection").selected_level
	elif Engine.has_meta("selected_level"):
		level_index = Engine.get_meta("selected_level")
	else:
		# Fall back to starting_level_index if LevelSelection wasn't set.
		level_index = starting_level_index

	# Clamp so an out-of-range value never crashes
	level_index = clamp(level_index, 0, level_scenes.size() - 1)
	
	# Load the level using the existing function to ensure proper setup
	load_level_by_index(level_index)

## Load a level by its index in level_scenes[].
func load_level_by_index(index: int) -> void:
	if index < 0 or index >= level_scenes.size():
		push_error("GameController.load_level_by_index: index %d out of range (have %d levels)." % [index, level_scenes.size()])
		return
	var scene: PackedScene = level_scenes[index]
	if scene == null:
		push_error("GameController.load_level_by_index: level_scenes[%d] is null." % index)
		return
	_current_level_index = index
	load_level_scene(scene)

## Load the next level, wrapping around to index 0 after the last.
func load_next_level() -> void:
	var next: int = (_current_level_index + 1) % level_scenes.size()
	load_level_by_index(next)

## Returns how many levels are registered.
func get_level_count() -> int:
	return level_scenes.size()

## Returns the current level index (0-based).
func get_current_level_index() -> int:
	return _current_level_index

func load_level_scene(level_scene: PackedScene) -> void:
	if level_scene == null:
		push_error("GameController.load_level_scene: level_scene is null.")
		return

	_clear_current_level()

	current_level = level_scene.instantiate()
	level_container.add_child(current_level)

	graph_map = _find_graph_map(current_level)
	if graph_map == null:
		push_error("GameController: could not find a GraphMap node inside the loaded level scene.")
		return

	_setup_graph_map()

	if game_camera != null:
		game_camera.global_position = graph_map.get_graph_center()
	else:
		push_warning("GameController: game_camera is null, cannot center map.")

func _clear_current_level() -> void:
	if current_level != null:
		current_level.queue_free()
		current_level = null
	graph_map = null

func _setup_graph_map() -> void:
	graph_map.set_units_node(units_node)
	graph_map.set_battles_node(battles_node)
	graph_map.set_overlay(drag_overlay)
	graph_map.set_game_camera(game_camera)
	graph_map.set_game_ui(game_ui)

	# initialize_level() builds cities/roads from the LevelData resource.
	graph_map.initialize_level()

	if graph_map.game_over.is_connected(_on_game_over) == false:
		graph_map.game_over.connect(_on_game_over)

	if game_camera != null and graph_map.has_method("get_graph_center"):
		game_camera.position = graph_map.get_graph_center()

	if ai_controller != null:
		ai_controller.set_graph_map(graph_map)

	if game_ui != null and game_ui.has_method("set_graph_map"):
		game_ui.set_graph_map(graph_map)

func _on_game_over(player_won: bool) -> void:
	if game_ui != null and game_ui.has_method("show_game_over"):
		game_ui.show_game_over(player_won)

func _find_graph_map(node: Node) -> GraphMap:
	if node is GraphMap:
		return node as GraphMap
	for child in node.get_children():
		var result := _find_graph_map(child)
		if result != null:
			return result
	return null
