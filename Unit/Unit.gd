extends Node2D
class_name Unit

signal arrived(unit: Unit, target_city: City)

@export var pixels_per_road_unit: float = 150.0
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
var _in_battle: bool = false

var fill_color: Color = Color(1, 1, 1)

func setup(from_city: City, to_city: City, road_data: RoadData, send_amount: int, faction_owner: int) -> void:
	source_city = from_city
	target_city = to_city
	road = road_data
	amount = send_amount
	unit_owner = faction_owner

	# Travel between city edges, not centers, so the unit never overlaps the city.
	var dir: Vector2 = (to_city.global_position - from_city.global_position).normalized()
	_start_pos = from_city.global_position + dir * from_city.get_radius()
	_end_pos   = to_city.global_position   - dir * to_city.get_radius()
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

func get_progress() -> float:
	return min(_elapsed / _travel_time, 1.0)

func is_on_same_road_opposing(other: Unit) -> bool:
	if road == null or other.road == null:
		return false
	if _in_battle or other._in_battle:
		return false
	if unit_owner == other.unit_owner:
		return false
	var same_road: bool = (road.a_id == other.road.a_id and road.b_id == other.road.b_id) or \
						  (road.a_id == other.road.b_id and road.b_id == other.road.a_id)
	if not same_road:
		return false
	return source_city == other.target_city and target_city == other.source_city

# Field battle: simple linear attrition, same 1-per-tick approach.
# Winner continues to destination with remaining troops.
func _resolve_field_battle(other: Unit) -> void:
	if _in_battle or other._in_battle:
		return
	_in_battle = true
	other._in_battle = true

	var a: int = amount
	var b: int = other.amount

	if a > b:
		amount = a - b
		queue_redraw()
		other.queue_free()
		_in_battle = false
	elif b > a:
		other.amount = b - a
		other.queue_redraw()
		queue_free()
		other._in_battle = false
	else:
		other.queue_free()
		queue_free()

var _parked: bool = false

func park_at_city() -> void:
	## Freeze this unit at the destination city during battle.
	## It stays in the scene tree (road-occupancy check can still see it)
	## but stops moving and becomes invisible — the Battle marker takes over.
	_parked = true
	visible = false

func _process(delta: float) -> void:
	if _parked:
		return
	if _in_battle:
		return

	if target_city == null or not is_instance_valid(target_city):
		queue_free()
		return

	_elapsed += delta
	var t: float = min(_elapsed / _travel_time, 1.0)
	global_position = _start_pos.lerp(_end_pos, t)

	# Field battle check — only the further-along unit initiates
	if get_parent() != null:
		for sibling in get_parent().get_children():
			if sibling == self or not (sibling is Unit):
				continue
			var other: Unit = sibling as Unit
			if is_on_same_road_opposing(other):
				if get_progress() >= other.get_progress():
					_resolve_field_battle(other)
					return

	if t >= 1.0:
		emit_signal("arrived", self, target_city)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
