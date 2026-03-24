extends Node2D
class_name Unit

signal arrived(unit: Unit, target_city: City)

@export var pixels_per_road_unit: float = 120.0
@export var radius: float = 8.0

var source_city: City
var target_city: City
var road: RoadData

var unit_owner: int = 0
var amount: int = 0

var _start_pos: Vector2
var _end_pos: Vector2
var _travel_time: float = 1.0
var _elapsed: float = 0.0

var fill_color: Color = Color(1, 1, 1)

func setup(from_city: City, to_city: City, road_data: RoadData, send_amount: int, faction_owner: int) -> void:
	source_city = from_city
	target_city = to_city
	road = road_data
	amount = send_amount
	unit_owner = faction_owner

	_start_pos = from_city.global_position
	_end_pos = to_city.global_position
	global_position = _start_pos

	match unit_owner:
		1: fill_color = Color(0.2, 0.7, 1.0)
		2: fill_color = Color(1.0, 0.3, 0.3)
		_: fill_color = Color(0.7, 0.7, 0.7)

	var dist: float = _start_pos.distance_to(_end_pos)
	var road_len: float = 1.0
	if road != null:
		road_len = max(road.length, 0.1)

	var computed_time: float = (dist / pixels_per_road_unit) * road_len
	_travel_time = max(computed_time, 0.05)

func _process(delta: float) -> void:
	if target_city == null or not is_instance_valid(target_city):
		queue_free()
		return

	_elapsed += delta

	var t: float = min(_elapsed / _travel_time, 1.0)
	global_position = _start_pos.lerp(_end_pos, t)

	if t >= 1.0:
		emit_signal("arrived", self, target_city)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
