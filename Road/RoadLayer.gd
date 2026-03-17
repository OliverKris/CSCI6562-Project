extends Node2D
class_name RoadLayer

@export var width: float = 4.0
@export var color: Color = Color(0.15, 0.15, 0.2, 1.0)

var _graph: GraphMap = null

func set_graph(graph: GraphMap) -> void:
	_graph = graph
	queue_redraw()

func _draw() -> void:
	if _graph == null:
		return
	
	var segments: Array = _graph.get_road_segments()
	for seg in segments:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		draw_line(a, b, color, width, true)
