extends Node
class_name GameController

@export var level_scene: PackedScene
@export var level_data: LevelData

@onready var world: Node = $"../World"
@onready var units_node: Node = $"../World/Units"
@onready var drag_overlay: Node = $"../World/DragOverlay"

@export var game_camera: Camera2D

var current_level: Node = null
var graph_map: GraphMap = null

func _ready() -> void:	
	if level_scene != null and level_data != null:
		load_level(level_data)

func load_level(level_data: LevelData) -> void:
	if current_level != null:
		current_level.queue_free()
		current_level = null
		graph_map = null

	current_level = level_scene.instantiate()
	world.add_child(current_level)

	graph_map = _find_graph_map(current_level)
	if graph_map == null:
		push_error("Could not find GraphMap inside loaded level.")
		return

	graph_map.level_data = level_data
	graph_map.set_units_node(units_node)
	graph_map.set_overlay(drag_overlay)
	graph_map.set_game_camera(game_camera)
	graph_map.build_from_level_data()
	
	game_camera.position = graph_map.get_graph_center()

func _find_graph_map(node: Node) -> GraphMap:
	if node is GraphMap:
		return node

	for child in node.get_children():
		var result := _find_graph_map(child)
		if result != null:
			return result

	return null
