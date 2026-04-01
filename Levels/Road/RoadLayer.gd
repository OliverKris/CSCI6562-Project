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

		var dir: Vector2 = (b_in_graph - a_in_graph).normalized()
		var a_r: float = city_a.get_radius()
		var b_r: float = city_b.get_radius()
		var a_edge: Vector2 = a_in_graph + dir * a_r
		var b_edge: Vector2 = b_in_graph - dir * b_r
		draw_line(a_edge, b_edge, color, width, true)
