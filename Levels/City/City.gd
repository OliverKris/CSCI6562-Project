extends Area2D
class_name City

signal captured(city: City, new_owner: int)

var data: CityData = null

@onready var visual = $CityVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var army_label: Label = $ArmyLabel

@export var production_interval: float = 2.0
@export var production_amount: int = 1
@export var hitbox_padding: float = 6.0

var _production_timer: float = 0.0

func setup_from_spawn_data(spawn: CitySpawnData) -> void:
	if data == null:
		data = CityData.new()

	data.id = spawn.id
	data.name = spawn.city_name
	data.owner = spawn.owner
	data.army = spawn.army

	_production_timer = 0.0
	_sync_collision_to_visual()
	refresh_from_data()

func refresh_from_data() -> void:
	if data == null:
		if army_label != null:
			army_label.text = "?"
		return

	set_faction(data.owner)

	if army_label != null:
		army_label.text = str(data.army)

func set_faction(owner: int) -> void:
	if visual != null and visual.has_method("set_faction"):
		visual.set_faction(owner)

func set_selected(selected: bool) -> void:
	if visual != null and visual.has_method("set_selected"):
		visual.set_selected(selected)
	_sync_collision_to_visual()

func get_radius() -> float:
	if visual != null and visual.has_method("get_radius"):
		return visual.get_radius()
	return 24.0

func get_hit_radius() -> float:
	return get_radius() + hitbox_padding

func add_units(amount: int) -> void:
	if data == null:
		return
	data.army += amount
	refresh_from_data()

func remove_units(amount: int) -> int:
	if data == null:
		return 0

	var actual: int = min(amount, data.army)
	data.army -= actual
	refresh_from_data()
	return actual

func receive_reinforcement(amount: int) -> void:
	add_units(amount)

func receive_units(amount: int, incoming_owner: int) -> void:
	if data == null:
		return

	var old_owner: int = data.owner

	if data.owner == incoming_owner:
		data.army += amount
	else:
		if amount > data.army:
			data.owner = incoming_owner
			data.army = amount - data.army
		else:
			data.army -= amount

	refresh_from_data()

	if data.owner != old_owner:
		captured.emit(self, data.owner)

func apply_capture(remaining_army: int, new_owner: int) -> void:
	if data == null:
		return

	var old_owner: int = data.owner
	data.owner = new_owner
	data.army = remaining_army
	refresh_from_data()

	if data.owner != old_owner:
		captured.emit(self, data.owner)

func can_send_units() -> bool:
	return data != null and data.owner == 1 and data.army > 0

func compute_send_amount(send_ratio: float, min_send_amount: int) -> int:
	if data == null:
		return 0

	var amount: int = max(min_send_amount, int(data.army * send_ratio))
	return min(amount, data.army)

func tick_production(delta: float) -> void:
	if data == null or data.owner == 0:
		return

	_production_timer += delta
	if _production_timer >= production_interval:
		_production_timer = 0.0
		add_units(production_amount)

func produce_once() -> void:
	if data == null:
		return
	if data.owner == 0:
		return

	# Only produce troops if the city is NOT under attack
	if not _is_under_attack():
		add_units(data.production_per_cycle)

	# Gold is always produced (even under attack)
	FactionState.add_gold(data.owner, data.gold_per_cycle)

func _is_under_attack() -> bool:
	for battle in get_tree().get_nodes_in_group("active_battles"):
		if battle is Battle and battle.target_city == self:
			return true
	return false

func _ready() -> void:
	if collision_shape != null and collision_shape.shape != null:
		collision_shape.shape = collision_shape.shape.duplicate()
	_sync_collision_to_visual()

func _sync_collision_to_visual() -> void:
	if collision_shape == null:
		return

	var radius: float = get_hit_radius()

	var circle: CircleShape2D = null
	if collision_shape.shape is CircleShape2D:
		circle = collision_shape.shape as CircleShape2D
	else:
		circle = CircleShape2D.new()
		collision_shape.shape = circle

	circle.radius = radius
