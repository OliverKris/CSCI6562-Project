extends Node2D

var graph: GraphMap

@onready var drag_line: Line2D = $DragLine
@onready var target_marker: Sprite2D = $TargetMarker


func _ready() -> void:
	drag_line.visible = false
	target_marker.visible = false

	drag_line.z_index = 0
	target_marker.z_index = 1001

func _process(_delta: float) -> void:
	update_drag_visuals()

func update_drag_visuals() -> void:
	if graph == null or not graph.is_dragging or graph.drag_from_city == null:
		drag_line.visible = false
		target_marker.visible = false
		return

	var start: Vector2 = graph.drag_from_city.global_position
	var end: Vector2 = get_global_mouse_position()

	var valid_target := false

	if graph.hover_target_city != null \
	and graph.hover_target_city != graph.drag_from_city \
	and graph._is_adjacent(graph.drag_from_city, graph.hover_target_city):
		end = graph.hover_target_city.global_position
		valid_target = true

	drag_line.visible = true
	drag_line.global_position = Vector2.ZERO
	drag_line.points = [start, end]

	if valid_target:
		target_marker.visible = true
		target_marker.global_position = end + Vector2(0, -5)
	else:
		target_marker.visible = false
