extends Area2D
class_name City

signal captured(city: City, new_owner: int)

var data: CityData

@onready var visual = $CityVisual
@onready var army_label: Label = $ArmyLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_sync_collision_to_visual()
	CycleClock.cycle_ticked.connect(_on_cycle)

func _exit_tree() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_cycle):
		CycleClock.cycle_ticked.disconnect(_on_cycle)

func setup_from_spawn_data(spawn: CitySpawnData) -> void:
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
		shape.radius = visual.radius

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
	data.army = min(data.army + amount, data.max_army)
	refresh_from_data()

func remove_units(amount: int) -> int:
	if data == null:
		return 0
	var actual: int = min(amount, data.army)
	data.army -= actual
	refresh_from_data()
	return actual

func apply_capture(surviving_attackers: int, attacker_owner: int) -> void:
	if data == null:
		return
	var prev_owner := data.owner
	data.owner = attacker_owner
	data.army = surviving_attackers
	refresh_from_data()
	if data.owner != prev_owner:
		emit_signal("captured", self, data.owner)

func receive_reinforcement(amount: int) -> void:
	if data == null:
		return
	data.army = min(data.army + amount, data.max_army)
	refresh_from_data()

func can_send_units() -> bool:
	return data != null and data.owner == 1 and data.army > 0

func compute_send_amount(send_ratio: float, min_send_amount: int) -> int:
	if data == null:
		return 0
	var amount: int = max(min_send_amount, int(data.army * send_ratio))
	return min(amount, data.army)

# Called every cycle by CycleClock
func _on_cycle() -> void:
	if data == null or data.owner == 0:
		return
	# Troop production is suspended while this city is under attack
	if not _is_under_attack():
		add_units(data.production_per_cycle)
	# Gold — goes to owning faction's pool
	FactionState.add_gold(data.owner, float(data.gold_per_cycle))

## Returns true if there is an active Battle targeting this city.
func _is_under_attack() -> bool:
	var battles_node: Node = get_tree().get_first_node_in_group("battles")
	if battles_node == null:
		# Fallback: walk up to find the battles node by name
		var root := get_tree().current_scene
		battles_node = _find_node_named(root, "Battles")
	if battles_node == null:
		return false
	for child in battles_node.get_children():
		if child is Battle and child.target_city == self:
			return true
	return false

func _find_node_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _find_node_named(child, target_name)
		if result != null:
			return result
	return null

func try_upgrade_production() -> bool:
	if data == null:
		return false
	return data.apply_production_upgrade()

func try_upgrade_gold() -> bool:
	if data == null:
		return false
	return data.apply_gold_upgrade()

func try_upgrade_defense() -> bool:
	if data == null:
		return false
	return data.apply_defense_upgrade()
