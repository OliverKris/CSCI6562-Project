extends Area2D
class_name City

signal clicked(city: City)

var data: CityData

@onready var visual = $CityVisual
@onready var army_label: Label = $ArmyLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var production_interval: float = 2.0
@export var production_amount: int = 1

var _production_timer: float = 0.0

func _ready() -> void:
	_sync_collision_to_visual()

func setup_from_spawn_data(spawn: CitySpawnData) -> void:
	position = spawn.position

	if data == null:
		data = CityData.new()

	data.id = spawn.id
	data.name = spawn.city_name
	data.owner = spawn.owner
	data.army = spawn.army

	_sync_collision_to_visual()
	refresh_from_data()

func _sync_collision_to_visual() -> void:
	if collision_shape == null or visual == null:
		return

	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = visual.radius * 5

func refresh_from_data() -> void:
	if data == null:
		if army_label != null:
			army_label.text = "?"
		return

	set_faction(data.owner)

	if army_label != null:
		army_label.text = str(data.army)

func set_faction(owner: int) -> void:
	if visual != null:
		visual.set_faction(owner)

func set_selected(selected: bool) -> void:
	if visual != null:
		visual.set_selected(selected)

func get_radius() -> float:
	if visual != null:
		return visual.radius
	return 24.0

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

func receive_units(amount: int, incoming_owner: int) -> void:
	if data == null:
		return

	if data.owner == incoming_owner:
		data.army += amount
	else:
		if amount > data.army:
			data.owner = incoming_owner
			data.army = amount - data.army
		else:
			data.army -= amount

	refresh_from_data()

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
