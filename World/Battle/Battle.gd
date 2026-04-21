extends Node2D
class_name Battle

signal battle_ended(battle: Battle, surviving_count: int, attacker_owner: int)

## The road this battle is "occupying" so the restriction check can see it.
var road: RoadData = null

var attacker_count: int = 0
var attacker_owner: int = 0
var target_city: City = null
var _finished: bool = false

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

	if target_city != null and parked_unit != null:
		global_position = parked_unit.global_position
		_parked_unit.visible = true
		if _parked_unit.has_method("begin_city_attack"):
			_parked_unit.begin_city_attack()
	elif target_city != null:
		global_position = target_city.global_position

func _ready() -> void:
	add_to_group("active_battles")
	CycleClock.cycle_ticked.connect(_on_cycle)

func _exit_tree() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_cycle):
		CycleClock.cycle_ticked.disconnect(_on_cycle)

func _draw() -> void:
	pass

func _on_cycle() -> void:
	if _finished:
		return

	if _parked_unit != null and is_instance_valid(_parked_unit):
		_parked_unit.global_position = global_position
		_parked_unit.amount = attacker_count
		if _parked_unit.has_method("_update_label"):
			_parked_unit._update_label()

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

	var attacker_damage: int = maxi(1, int(sqrt(float(garrison))))
	var garrison_damage: int = maxi(1, int(sqrt(float(attacker_count))))

	var defense_reduction: float = 0.0
	match target_city.data.defense_level:
		0: defense_reduction = 0.05
		1: defense_reduction = 0.10
		2: defense_reduction = 0.15
		3: defense_reduction = 0.20

	garrison_damage = maxi(1, int(float(garrison_damage) * (1.0 - defense_reduction)))

	attacker_count -= attacker_damage
	target_city.data.army -= garrison_damage
	target_city.refresh_from_data()

	if attacker_count <= 0 and target_city.data.army <= 0:
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

	if _parked_unit != null and is_instance_valid(_parked_unit):
		if survivors > 0:
			if _parked_unit.has_method("end_city_attack"):
				_parked_unit.end_city_attack()
			_parked_unit.fade_out_into_friendly_city()
		else:
			if _parked_unit.has_method("die_in_battle"):
				_parked_unit.die_in_battle()
			elif _parked_unit.has_method("_die"):
				_parked_unit._die()
			else:
				_parked_unit.fade_out_into_friendly_city()

		_parked_unit = null

	emit_signal("battle_ended", self, survivors, attacker_owner)
	queue_free()
