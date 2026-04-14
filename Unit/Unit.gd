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

var _field_battle_opponent: Unit = null

# Field battle: synchronized attrition using the same formula as city battles.
# Both units freeze at their midpoint and lose max(1, floor(opponent/4)) per tick.
func _resolve_field_battle(other: Unit) -> void:
	if _in_battle or other._in_battle:
		return
	_in_battle = true
	other._in_battle = true
	_field_battle_opponent = other
	other._field_battle_opponent = self

	# Freeze both units at their midpoint
	var mid: Vector2 = (global_position + other.global_position) / 2.0
	global_position = mid
	other.global_position = mid

	# Only the initiator connects the tick signal (it manages both sides)
	CycleClock.cycle_ticked.connect(_on_field_battle_tick)

func _on_field_battle_tick() -> void:
	if not _in_battle:
		return
	if _field_battle_opponent == null or not is_instance_valid(_field_battle_opponent):
		# Opponent already gone — we won
		_in_battle = false
		_field_battle_opponent = null
		if CycleClock.cycle_ticked.is_connected(_on_field_battle_tick):
			CycleClock.cycle_ticked.disconnect(_on_field_battle_tick)
		return

	# Synchronized damage: calculate both values before applying either.
	var self_damage: int = maxi(1, _field_battle_opponent.amount / 4)
	var opp_damage: int = maxi(1, amount / 4)

	amount -= self_damage
	_field_battle_opponent.amount -= opp_damage
	queue_redraw()
	_field_battle_opponent.queue_redraw()

	var self_dead: bool = amount <= 0
	var opp_dead: bool = _field_battle_opponent.amount <= 0

	if CycleClock.cycle_ticked.is_connected(_on_field_battle_tick):
		CycleClock.cycle_ticked.disconnect(_on_field_battle_tick)

	if self_dead and opp_dead:
		_field_battle_opponent.queue_free()
		queue_free()
	elif self_dead:
		var opp := _field_battle_opponent
		opp._in_battle = false
		opp._field_battle_opponent = null
		queue_free()
	elif opp_dead:
		_in_battle = false
		_field_battle_opponent.queue_free()
		_field_battle_opponent = null

var _parked: bool = false

func park_at_city() -> void:
	## Freeze this unit at the destination city during battle.
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

	# Scale movement by the game speed so troops travel faster at higher speeds
	_elapsed += delta * CycleClock.speed_scale
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
