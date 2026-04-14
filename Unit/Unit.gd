extends Area2D
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

func is_opposing(other: Unit) -> bool:
	if _in_battle or other._in_battle:
		return false
	if unit_owner == other.unit_owner:
		return false
	if road == null or other.road == null:
		return false
	var same_road: bool = (road.a_id == other.road.a_id and road.b_id == other.road.b_id) or \
						  (road.a_id == other.road.b_id and road.b_id == other.road.a_id)
	if not same_road:
		return false
	return source_city == other.target_city and target_city == other.source_city

# ── Field battle ──────────────────────────────────────────────────────────────

var _field_battle_opponent: Unit = null
var _is_battle_manager: bool = false

func _resolve_field_battle(other: Unit) -> void:
	if _in_battle or other._in_battle:
		return
	_in_battle = true
	other._in_battle = true
	_field_battle_opponent = other
	other._field_battle_opponent = self
	_is_battle_manager = true
	other._is_battle_manager = false

	if not CycleClock.cycle_ticked.is_connected(_on_field_battle_tick):
		CycleClock.cycle_ticked.connect(_on_field_battle_tick)

func _on_field_battle_tick() -> void:
	if not _is_battle_manager:
		return

	if _field_battle_opponent == null or not is_instance_valid(_field_battle_opponent):
		_disconnect_tick()
		_finish_as_winner()
		return

	var self_damage: int = maxi(1, int(sqrt(float(_field_battle_opponent.amount))))
	var opp_damage:  int = maxi(1, int(sqrt(float(amount))))

	amount -= self_damage
	_field_battle_opponent.amount -= opp_damage
	queue_redraw()
	_field_battle_opponent.queue_redraw()

	var self_dead: bool = amount <= 0
	var opp_dead:  bool = _field_battle_opponent.amount <= 0

	if self_dead and opp_dead:
		_disconnect_tick()
		_field_battle_opponent.queue_free()
		_field_battle_opponent = null
		queue_free()
	elif self_dead:
		var opp := _field_battle_opponent
		_disconnect_tick()
		_field_battle_opponent = null
		opp._field_battle_opponent = null
		opp._finish_as_winner()
		queue_free()
	elif opp_dead:
		var opp := _field_battle_opponent
		_disconnect_tick()
		_field_battle_opponent = null
		opp._field_battle_opponent = null
		opp.queue_free()
		_finish_as_winner()

func _disconnect_tick() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_field_battle_tick):
		CycleClock.cycle_ticked.disconnect(_on_field_battle_tick)

func _finish_as_winner() -> void:
	_in_battle = false
	_is_battle_manager = false
	_field_battle_opponent = null
	_disconnect_tick()
	if _travel_time > 0.0:
		var current_dist: float = global_position.distance_to(_end_pos)
		var total_dist:   float = _start_pos.distance_to(_end_pos)
		var remaining_frac: float = current_dist / max(total_dist, 0.001)
		_elapsed = _travel_time * (1.0 - remaining_frac)
	queue_redraw()

func _exit_tree() -> void:
	_disconnect_tick()

# ── Physics collision ─────────────────────────────────────────────────────────

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(other_area: Area2D) -> void:
	if not (other_area is Unit):
		return
	var other: Unit = other_area as Unit
	if not is_opposing(other):
		return
	if get_progress() >= other.get_progress():
		_resolve_field_battle(other)

# ── Parked (at city during city battle) ───────────────────────────────────────

var _parked: bool = false

func park_at_city() -> void:
	_parked = true
	visible = false

# ── Movement ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _parked or _in_battle:
		return

	if target_city == null or not is_instance_valid(target_city):
		queue_free()
		return

	_elapsed += delta * CycleClock.speed_scale
	var t: float = min(_elapsed / _travel_time, 1.0)
	global_position = _start_pos.lerp(_end_pos, t)

	if t >= 1.0:
		emit_signal("arrived", self, target_city)

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
