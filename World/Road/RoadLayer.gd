extends Node2D
class_name RoadLayer

@export var width: float = 10.0
@export var fallback_color: Color = Color(0.15, 0.15, 0.2, 1.0)

@export var road_textures: Array[Texture2D] = []
@export var segment_length: float = 20.0
@export var lateral_jitter: float = 1.5
@export var random_seed_offset: int = 0

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

		var a_local: Vector2 = to_local(city_a.global_position)
		var b_local: Vector2 = to_local(city_b.global_position)

		var dir: Vector2 = (b_local - a_local).normalized()
		var distance: float = a_local.distance_to(b_local)

		if distance <= 0.0:
			continue

		var a_r: float = city_a.get_radius()
		var b_r: float = city_b.get_radius()
		var a_edge: Vector2 = a_local + dir * a_r
		var b_edge: Vector2 = b_local - dir * b_r

		_draw_road_segmented(a_edge, b_edge, road)
		
func _draw_road_segmented(start: Vector2, end: Vector2, road: RoadData) -> void:
	var road_vec: Vector2 = end - start
	var road_len: float = road_vec.length()

	if road_len <= 0.0:
		return

	var dir: Vector2 = road_vec.normalized()
	var normal: Vector2 = Vector2(-dir.y, dir.x)
	var angle: float = dir.angle()

	if road_textures.is_empty():
		draw_line(start, end, fallback_color, width, true)
		return

	var rng := RandomNumberGenerator.new()
	var seed_value := int(start.x * 92821.0 + start.y * 68917.0 + end.x * 13007.0 + end.y * 47221.0) + random_seed_offset
	rng.seed = abs(seed_value)

	var first_tex: Texture2D = road_textures[0]
	if first_tex == null:
		draw_line(start, end, fallback_color, width, true)
		return

	var piece_length: float = first_tex.get_width()
	var piece_height: float = first_tex.get_height()

	if piece_length <= 0.0:
		return

	var count: int = int(ceil(road_len / piece_length))

	for i in range(count):
		var dist_along: float = (i + 0.5) * piece_length
		if dist_along > road_len:
			dist_along = road_len - piece_length * 0.5

		var pos: Vector2 = start + dir * dist_along
		pos += normal * rng.randf_range(-lateral_jitter, lateral_jitter)

		var tex: Texture2D = road_textures[rng.randi_range(0, road_textures.size() - 1)]
		if tex == null:
			continue

		draw_set_transform(pos, angle, Vector2.ONE)
		draw_texture(tex, Vector2(-tex.get_width() * 0.5, -tex.get_height() * 0.5))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
