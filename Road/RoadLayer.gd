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

	for road: RoadData in _graph.roads:
		if road == null:
			continue

		var city_a: City = _graph.get_city_by_id(road.a_id)
		var city_b: City = _graph.get_city_by_id(road.b_id)

		if city_a == null or city_b == null:
			continue

		# Because RoadLayer is inside GraphMap, convert city global positions
		# into GraphMap-local space, then into RoadLayer-local space.
		var a_in_graph: Vector2 = _graph.to_local(city_a.global_position)
		var b_in_graph: Vector2 = _graph.to_local(city_b.global_position)

		draw_line(a_in_graph, b_in_graph, color, width, true)
