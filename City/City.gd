extends Area2D
class_name City

signal clicked(city: City)

@export var data: CityData

@onready var army_label: Label = $Label
@onready var prod_timer: Timer = $ProductionTimer
@onready var visual: Node2D = $Visual

var _prod_accum: float = 0.0

func _ready() -> void:
	input_pickable = true

	if data:
		data.changed.connect(_refresh)

	prod_timer.wait_time = 0.25
	prod_timer.timeout.connect(_on_production_tick)
	prod_timer.start()

	_refresh()

func _refresh() -> void:
	if data == null:
		army_label.text = "?"
		return

	if visual and visual.has_method("set_faction"):
		visual.call("set_faction", data.owner)

	army_label.text = str(data.army)

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("clicked", self)

func set_selected(is_selected: bool) -> void:
	scale = Vector2.ONE * (1.15 if is_selected else 1.0)
	if visual.has_method("set_selected"):
		visual.call("set_selected", is_selected)

func _on_production_tick() -> void:
	if not data:
		return
	if data.owner == 0:
		return

	_prod_accum += data.production_per_sec * prod_timer.wait_time

	var add_units: int = int(floor(_prod_accum))
	if add_units > 0:
		_prod_accum -= add_units
		var new_army: int = min(data.army + add_units, data.max_army)
		data.army = new_army

func can_send(amount: int) -> bool:
	return data != null and amount > 0 and data.army >= amount

func remove_units(amount: int) -> int:
	if not data:
		return 0
	var taken: int = min(amount, data.army)
	data.army -= taken
	return taken

func add_units(amount: int) -> void:
	if not data or amount <= 0:
		return
	var new_army: int = min(data.army + amount, data.max_army)
	data.army = new_army
