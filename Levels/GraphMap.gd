extends Node2D
class_name GraphMap

@onready var cities_node: Node = $Cities
@onready var road_layer: RoadLayer = $RoadLayer

@export var level_data: LevelData
@export var city_scene: PackedScene
@export var unit_scene: PackedScene

@export var send_ratio: float = 0.5
@export var min_send_amount: int = 1
@export var city_pick_radius: float = 24.0

var roads: Array[RoadData] = []
var cities_by_id: Dictionary = {}
var adj: Dictionary = {}

var units_node: Node = null
var overlay: Node = null
var game_camera: Camera2D = null

var selected_city: City = null
var drag_from_city: City = null
var hover_target_city: City = null
var is_dragging: bool = false

func set_units_node(node: Node) -> void:
	units_node = node

func set_overlay(node: Node) -> void:
	overlay = node
	if overlay != null:
		overlay.graph = self
		overlay.queue_redraw()

func set_game_camera(cam: Camera2D) -> void:
	game_camera = cam
	
func _ready() -> void:
	road_layer.set_graph(self)
	road_layer.queue_redraw()

func _process(delta: float) -> void:
	if is_dragging:
		hover_target_city = _get_city_under_mouse()
		if overlay != null:
			overlay.queue_redraw()

	for c in cities_node.get_children():
		if c is City:
			c.tick_production(delta)

func get_graph_center() -> Vector2:
	if level_data == null or level_data.cities.is_empty():
		return Vector2.ZERO

	var first_pos: Vector2 = level_data.cities[0].position
	var min_pos: Vector2 = first_pos
	var max_pos: Vector2 = first_pos

	for city_def in level_data.cities:
		var p: Vector2 = city_def.position
		min_pos.x = min(min_pos.x, p.x)
		min_pos.y = min(min_pos.y, p.y)
		max_pos.x = max(max_pos.x, p.x)
		max_pos.y = max(max_pos.y, p.y)

	return (min_pos + max_pos) * 0.5

func build_from_level_data() -> void:
	if level_data == null:
		push_warning("GraphMap.level_data is null")
		return

	if city_scene == null:
		push_warning("GraphMap.city_scene is null")
		return

	for child in cities_node.get_children():
		child.queue_free()

	cities_by_id.clear()
	adj.clear()
	roads.clear()

	for city_def in level_data.cities:
		var city_instance := city_scene.instantiate()
		if city_instance is City:
			var city: City = city_instance
			cities_node.add_child(city)
			city.setup_from_spawn_data(city_def)

	roads = level_data.roads.duplicate()

	_register_cities()
	_build_adjacency_from_roads()

	road_layer.set_graph(self)
	road_layer.queue_redraw()

	if overlay != null:
		overlay.graph = self
		overlay.queue_redraw()

func _register_cities() -> void:
	cities_by_id.clear()

	for child in cities_node.get_children():
		if child is City and child.data != null:
			cities_by_id[child.data.id] = child

func get_city_by_id(id: int) -> City:
	if cities_by_id.has(id):
		return cities_by_id[id]
	return null

func _set_selected_city(city: City) -> void:
	if selected_city != null:
		selected_city.set_selected(false)

	selected_city = city

	if selected_city != null:
		selected_city.set_selected(true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_mouse_press(event.position)
		else:
			_on_mouse_release()

func _on_mouse_press(mouse_pos: Vector2) -> void:
	var c: City = _get_city_under_mouse()

	if c == null:
		_set_selected_city(null)
		
		# Plain left click on empty space -> pan
		if game_camera != null and not Input.is_key_pressed(KEY_SPACE):
			game_camera.start_left_pan(mouse_pos)		
		return

	_set_selected_city(c)

	if c.can_send_units():
		is_dragging = true
		drag_from_city = c
		hover_target_city = null
		if overlay != null:
			overlay.queue_redraw()
			
	else:
		# Left click on non-draggable city can also pan
		if game_camera != null and not Input.is_key_pressed(KEY_SPACE):
			game_camera.start_left_pan(mouse_pos)

func _on_mouse_release() -> void:
	if game_camera != null:
		game_camera.stop_left_pan()
	
	if not is_dragging:
		return

	var target: City = _get_city_under_mouse()

	if target != null and target != drag_from_city and _is_adjacent(drag_from_city, target):
		_send_units(drag_from_city, target)

	is_dragging = false
	drag_from_city = null
	hover_target_city = null
	if overlay != null:
		overlay.queue_redraw()

func _get_city_under_mouse() -> City:
	var mouse: Vector2 = get_global_mouse_position()

	for c in cities_node.get_children():
		if c is City:
			if c.global_position.distance_to(mouse) <= city_pick_radius:
				return c
	return null

func _is_adjacent(a: City, b: City) -> bool:
	if a == null or b == null or a.data == null or b.data == null:
		return false
	if not adj.has(a.data.id):
		return false
	return adj[a.data.id].has(b.data.id)

func _send_units(from_city: City, to_city: City) -> void:
	if from_city == null or to_city == null:
		return
	if from_city.data == null or to_city.data == null:
		return
	if units_node == null:
		push_warning("GraphMap.units_node is null")
		return
	if unit_scene == null:
		push_warning("GraphMap.unit_scene is null")
		return

	var road: RoadData = get_road_between(from_city.data.id, to_city.data.id)
	if road == null:
		return

	var send_amount: int = from_city.compute_send_amount(send_ratio, min_send_amount)
	if send_amount <= 0:
		return

	var actual: int = from_city.remove_units(send_amount)
	if actual <= 0:
		return

	var unit_instance: Node = unit_scene.instantiate()
	if unit_instance is Unit:
		var unit: Unit = unit_instance
		units_node.add_child(unit)
		unit.setup(from_city, to_city, road, actual, from_city.data.owner)
		unit.arrived.connect(_on_unit_arrived)

func _on_unit_arrived(unit: Unit, target_city: City) -> void:
	if target_city == null:
		unit.queue_free()
		return

	target_city.receive_units(unit.amount, unit.unit_owner)
	unit.queue_free()

func get_road_between(a: int, b: int) -> RoadData:
	for r: RoadData in roads:
		if r == null:
			continue
		if (r.a_id == a and r.b_id == b) or (r.a_id == b and r.b_id == a):
			return r
	return null

func _build_adjacency_from_roads() -> void:
	adj.clear()

	for id in cities_by_id.keys():
		adj[id] = []

	for r: RoadData in roads:
		if r == null:
			continue
		if not cities_by_id.has(r.a_id) or not cities_by_id.has(r.b_id):
			continue
		adj[r.a_id].append(r.b_id)
		adj[r.b_id].append(r.a_id)
