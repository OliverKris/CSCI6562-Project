extends Node2D

var graph: GraphMap

func _ready() -> void:
	z_index = 1000

func _draw() -> void:
	if graph == null or not graph.is_dragging or graph.drag_from_city == null:
		return

	var start: Vector2 = graph.drag_from_city.global_position
	var end: Vector2 = get_global_mouse_position()

	if graph.hover_target_city != null \
	and graph.hover_target_city != graph.drag_from_city \
	and graph._is_adjacent(graph.drag_from_city, graph.hover_target_city):
		end = graph.hover_target_city.global_position

	draw_line(start, end, Color(1, 1, 1, 0.8), 3.0, true)

	if graph.hover_target_city != null \
	and graph.hover_target_city != graph.drag_from_city \
	and graph._is_adjacent(graph.drag_from_city, graph.hover_target_city):

		var target_radius: float = graph.hover_target_city.get_radius()
		draw_circle(
			graph.hover_target_city.global_position,
			target_radius + 4.0,
			Color(1, 1, 0.2, 0.22)
		)
