extends Node2D
class_name Battle

signal battle_ended(battle: Battle, surviving_count: int, attacker_owner: int)

## The road this battle is "occupying" so the restriction check can see it.
var road: RoadData = null

var attacker_count: int = 0
var attacker_owner: int = 0
var target_city: City = null
var _finished: bool = false

# Visual marker radius and colour — mirrors Unit's style.
@export var radius: float = 8.0
var fill_color: Color = Color(1, 1, 1)

# Parked unit node kept alive so it stays visible during the fight.
var _parked_unit: Unit = null

func setup(attackers: int, owner: int, city: City, road_data: RoadData, parked_unit: Unit = null) -> void:
	attacker_count = attackers
	attacker_owner = owner
	target_city = city
	road = road_data
	_parked_unit = parked_unit

	match attacker_owner:
		1: fill_color = Color(0.2, 0.7, 1.0)
		2: fill_color = Color(1.0, 0.3, 0.3)
		_: fill_color = Color(0.7, 0.7, 0.7)

	# Position the battle marker at the edge of the target city facing the attacker,
	# which is exactly where the parked unit stopped.
	if target_city != null and parked_unit != null:
		global_position = parked_unit.global_position
	elif target_city != null:
		global_position = target_city.global_position

	queue_redraw()

func _ready() -> void:
	CycleClock.cycle_ticked.connect(_on_cycle)

func _exit_tree() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_cycle):
		CycleClock.cycle_ticked.disconnect(_on_cycle)

func _draw() -> void:
	# Pulsing filled circle (same visual language as Unit) plus troop count.
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius + 2.0, 0, TAU, 24, Color(1, 1, 0, 0.9), 2.0)
	# Show remaining attacker count above the marker.
	var label_pos := Vector2(-10, -radius - 14)
	draw_string(ThemeDB.fallback_font, label_pos, str(attacker_count),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))

func _on_cycle() -> void:
	if _finished:
		return

	# Target freed
	if target_city == null or not is_instance_valid(target_city):
		_finish(0)
		return

	if target_city.data == null:
		_finish(0)
		return

	# City flipped to same faction mid-battle — reinforce
	if target_city.data.owner == attacker_owner:
		target_city.receive_reinforcement(attacker_count)
		_finish(0)
		return

	var garrison: int = target_city.data.army

	if garrison <= 0:
		target_city.apply_capture(attacker_count, attacker_owner)
		_finish(attacker_count)
		return

	# One unit subtracted from each side per cycle
	attacker_count -= 1
	target_city.data.army -= 1
	target_city.refresh_from_data()
	queue_redraw()

	if attacker_count <= 0 and target_city.data.army <= 0:
		# Mutual destruction
		target_city.data.army = 0
		target_city.refresh_from_data()
		_finish(0)
	elif attacker_count <= 0:
		_finish(0)
	elif target_city.data.army <= 0:
		target_city.apply_capture(attacker_count, attacker_owner)
		_finish(attacker_count)

func _finish(survivors: int) -> void:
	_finished = true
	# Free the parked unit now that the battle is resolved.
	if _parked_unit != null and is_instance_valid(_parked_unit):
		_parked_unit.queue_free()
		_parked_unit = null
	emit_signal("battle_ended", self, survivors, attacker_owner)
	queue_free()
