extends Node2D
class_name GraphMap

@onready var cities_node: Node = $Cities
@onready var road_layer: RoadLayer = $RoadLayer
@onready var units_node: Node = $Units

@export var roads: Array[RoadData] = []
@export var unit_scene: PackedScene

@export var send_ratio: float = 0.5
@export var min_send_amount: int = 1
@export var city_pick_radius: float = 24.0

var cities_by_id: Dictionary = {}
var adj: Dictionary = {}

var selected_city: City = null

var drag_from_city: City = null
var hover_target_city: City = null
var is_dragging: bool = false

func _ready() -> void:
	_register_cities()
	_build_adjacency_from_roads()
	road_layer.set_graph(self)
	road_layer.queue_redraw()
	queue_redraw()

func _process(_delta: float) -> void:
	if is_dragging:
		hover_target_city = _get_city_under_mouse()
		queue_redraw()

func _draw() -> void:
	if not is_dragging or drag_from_city == null:
		return

	var start: Vector2 = to_local(drag_from_city.global_position)
	var mouse: Vector2 = to_local(get_global_mouse_position())
	draw_line(start, mouse, Color(1, 1, 1, 0.8), 3.0, true)

	if hover_target_city != null and hover_target_city != drag_from_city and _is_adjacent(drag_from_city, hover_target_city):
		draw_circle(to_local(hover_target_city.global_position), 28.0, Color(1.0, 1.0, 0.2, 0.22))

func _register_cities() -> void:
	cities_by_id.clear()

	for child in cities_node.get_children():
		if child is City and child.data != null:
			cities_by_id[child.data.id] = child
			child.clicked.connect(_on_city_clicked)

func get_city_by_id(id: int) -> City:
	if cities_by_id.has(id):
		return cities_by_id[id]
	return null

func _on_city_clicked(city: City) -> void:
	if is_dragging:
		return

	_set_selected_city(city)

func _set_selected_city(city: City) -> void:
	if selected_city != null:
		selected_city.set_selected(false)

	selected_city = city

	if selected_city != null:
		selected_city.set_selected(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_mouse_press()
		else:
			_on_mouse_release()

func _on_mouse_press() -> void:
	var c: City = _get_city_under_mouse()

	if c == null:
		_set_selected_city(null)
		return

	_set_selected_city(c)

	if c.data != null and c.data.owner == 1:
		is_dragging = true
		drag_from_city = c
		hover_target_city = null
		queue_redraw()

func _on_mouse_release() -> void:
	if not is_dragging:
		return

	var target: City = _get_city_under_mouse()

	if target != null and target != drag_from_city and _is_adjacent(drag_from_city, target):
		_send_units(drag_from_city, target)

	is_dragging = false
	drag_from_city = null
	hover_target_city = null
	queue_redraw()

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

	var road: RoadData = get_road_between(from_city.data.id, to_city.data.id)
	if road == null:
		return

	var send_amount: int = max(min_send_amount, int(from_city.data.army * send_ratio))
	send_amount = min(send_amount, from_city.data.army)

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
	if target_city == null or target_city.data == null:
		unit.queue_free()
		return

	if target_city.data.owner == unit.unit_owner:
		target_city.add_units(unit.amount)
	else:
		if unit.amount > target_city.data.army:
			target_city.data.owner = unit.unit_owner
			target_city.data.army = unit.amount - target_city.data.army
		else:
			target_city.data.army -= unit.amount

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
