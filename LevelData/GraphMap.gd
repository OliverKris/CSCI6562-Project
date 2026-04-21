extends Node2D
class_name GraphMap

signal game_over(player_won: bool)

@onready var cities_node: Node = $Cities
@onready var road_layer: RoadLayer = $RoadLayer

@export var level_data: LevelData
@export var city_scene: PackedScene
@export var unit_scene: PackedScene
@export var battle_scene: PackedScene

@export var min_send_amount: int = 1
@export var city_pick_radius: float = 40.0

# Flat-top hex grid
@export var hex_size: float = 64.0

var roads: Array[RoadData] = []
var cities_by_id: Dictionary = {}
var adj: Dictionary = {}

var units_node: Node = null
var battles_node: Node = null
var overlay: Node = null
var game_camera: Camera2D = null
var game_ui = null

var selected_city: City = null
var drag_from_city: City = null
var hover_target_city: City = null
var is_dragging: bool = false

var player_send_ratio: float = 0.5
var _game_over: bool = false

# --- Hex math (flat-top) ---
# Hex (12, 0) maps to world (0, 0). Offset applied in pixel space.
# Y-axis: negative r = up (negative screen Y), positive r = down (positive screen Y).

func hex_to_world(hex: Vector2i) -> Vector2:
	var x: float = hex_size * 1.5 * float(hex.x)
	var y: float = hex_size * (sqrt(3.0) / 2.0 * float(hex.x) + sqrt(3.0) * float(hex.y))
	return Vector2(x, y)

func world_to_hex(world: Vector2) -> Vector2i:
	var px: float = world.x
	var py: float = world.y
	var q: float = (2.0 / 3.0) * px / hex_size
	var r: float = (-1.0 / 3.0 * px + sqrt(3.0) / 3.0 * py) / hex_size
	return _hex_round(q, r)

func _hex_round(q: float, r: float) -> Vector2i:
	var s: float = -q - r
	var rq: int = roundi(q)
	var rr: int = roundi(r)
	var rs: int = roundi(s)
	var q_diff: float = abs(float(rq) - q)
	var r_diff: float = abs(float(rr) - r)
	var s_diff: float = abs(float(rs) - s)
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	return Vector2i(rq, rr)

# --- Wiring (called by GameController before initialize_level) ---
func set_units_node(node: Node) -> void:
	units_node = node

func set_battles_node(node: Node) -> void:
	battles_node = node

func set_overlay(node: Node) -> void:
	overlay = node
	if overlay != null:
		overlay.graph = self
		overlay.queue_redraw()

func set_game_camera(cam: Camera2D) -> void:
	game_camera = cam

func set_game_ui(ui) -> void:
	game_ui = ui

# --- Lifecycle ---
func _ready() -> void:
	road_layer.set_graph(self)
	road_layer.queue_redraw()
	CycleClock.cycle_ticked.connect(_on_cycle)

func _exit_tree() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_cycle):
		CycleClock.cycle_ticked.disconnect(_on_cycle)

## Called by GameController._setup_graph_map() after wiring is complete.
## Builds all cities and roads from the assigned level_data resource.
func initialize_level() -> void:
	build_from_level_data()

func _on_cycle() -> void:
	if _game_over:
		return

	for c in cities_node.get_children():
		if c is City:
			c.produce_once()
			if c.data != null and c.data.owner != 0:
				FactionState.add_gold(c.data.owner, float(c.data.gold_per_cycle))

	_check_win_loss()

func _process(_delta: float) -> void:
	if _game_over:
		return
	if is_dragging:
		hover_target_city = _get_city_under_mouse()
		if overlay != null:
			overlay.queue_redraw()

func _check_win_loss() -> void:
	var player_cities := 0
	var enemy_cities := 0
	var neutral_cities := 0
	var total := 0
	for c in cities_node.get_children():
		if c is City and c.data != null:
			total += 1
			if c.data.owner == 1:
				player_cities += 1
			elif c.data.owner == 2:
				enemy_cities += 1
			else:
				neutral_cities += 1
	if total == 0:
		return
	if player_cities == 0:
		_game_over = true
		emit_signal("game_over", false)
		return
	# Tutorial check: if no enemy cities exist at all (tutorial has no enemy agent),
	# win when player controls ALL cities (including formerly neutral ones).
	var _has_any_enemy := false
	for c in cities_node.get_children():
		if c is City and c.data != null and c.data.owner == 2:
			_has_any_enemy = true
			break
	# At game start we check if there were ever enemy cities. Use level_data.
	var level_has_enemy_cities := false
	if level_data != null:
		for city_def in level_data.cities:
			if city_def.owner == 2:
				level_has_enemy_cities = true
				break
	if level_has_enemy_cities:
		# Normal win: eliminate all enemy cities
		if enemy_cities == 0:
			_game_over = true
			emit_signal("game_over", true)
	else:
		# Tutorial win: conquer ALL cities (no enemy agent exists)
		if neutral_cities == 0 and enemy_cities == 0:
			_game_over = true
			emit_signal("game_over", true)

func get_graph_center() -> Vector2:
	if cities_by_id.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	var count := 0
	for city in cities_by_id.values():
		sum += (city as City).global_position
		count += 1
	return sum / float(count)

func build_from_level_data() -> void:
	if level_data == null:
		push_warning("GraphMap.build_from_level_data: level_data is null. Assign a LevelData .tres to this scene.")
		return
	if city_scene == null:
		push_warning("GraphMap.build_from_level_data: city_scene is null.")
		return

	# Clear existing state
	for child in cities_node.get_children():
		child.queue_free()

	cities_by_id.clear()
	adj.clear()
	roads.clear()
	_game_over = false
	FactionState.reset()

	# Spawn cities
	for city_def in level_data.cities:
		var city_instance := city_scene.instantiate()
		if city_instance is City:
			var city: City = city_instance
			cities_node.add_child(city)
			city.position = hex_to_world(city_def.hex_coord)
			city.setup_from_spawn_data(city_def)
			if not city.captured.is_connected(_on_city_captured):
				city.captured.connect(_on_city_captured)

	roads = level_data.roads.duplicate()
	_register_cities()
	_build_adjacency_from_roads()
	road_layer.set_graph(self)
	road_layer.queue_redraw()
	if overlay != null:
		overlay.graph = self
		overlay.queue_redraw()

func _on_city_captured(_city: City, _new_owner: int) -> void:
	if game_ui != null and game_ui.has_method("refresh_selected_city"):
		game_ui.refresh_selected_city()

func _register_cities() -> void:
	cities_by_id.clear()
	for child in cities_node.get_children():
		if child is City and child.data != null:
			cities_by_id[child.data.id] = child

func get_city_by_id(id: int) -> City:
	if cities_by_id.has(id):
		return cities_by_id[id]
	return null

func get_all_cities() -> Array:
	var result: Array = []
	for child in cities_node.get_children():
		if child is City:
			result.append(child)
	return result

func get_adjacent_cities(city: City) -> Array:
	if city == null or city.data == null:
		return []
	var result: Array = []
	if adj.has(city.data.id):
		for neighbor_id in adj[city.data.id]:
			var neighbor := get_city_by_id(neighbor_id)
			if neighbor != null:
				result.append(neighbor)
	return result

func _set_selected_city(city: City) -> void:
	if selected_city != null:
		selected_city.set_selected(false)
	selected_city = city
	if selected_city != null:
		selected_city.set_selected(true)
	if game_ui != null and game_ui.has_method("on_city_selected"):
		game_ui.on_city_selected(selected_city)

# --- Input ---
func _is_mouse_over_ui() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	return hovered.mouse_filter == Control.MOUSE_FILTER_STOP

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_mouse_over_ui():
			return
		if event.pressed:
			_on_mouse_press(event.position)
		else:
			_on_mouse_release()

func _on_mouse_press(mouse_pos: Vector2) -> void:
	var c: City = _get_city_under_mouse()
	if c == null:
		_set_selected_city(null)
		if game_camera != null and not Input.is_key_pressed(KEY_SPACE):
			game_camera.start_left_pan(mouse_pos)
		return
	_set_selected_city(c)
	if c.can_send_units():
		is_dragging = true
		drag_from_city = c
		hover_target_city = null
		if overlay != null:
			overlay.queue_redraw()
	else:
		if game_camera != null and not Input.is_key_pressed(KEY_SPACE):
			game_camera.start_left_pan(mouse_pos)

func _on_mouse_release() -> void:
	if game_camera != null:
		game_camera.stop_left_pan()
	if not is_dragging:
		return
	var target: City = _get_city_under_mouse()
	if target != null and target != drag_from_city and _is_adjacent(drag_from_city, target):
		_send_units(drag_from_city, target)
	is_dragging = false
	drag_from_city = null
	hover_target_city = null
	if overlay != null:
		overlay.queue_redraw()

func _get_city_under_mouse() -> City:
	var mouse: Vector2 = get_global_mouse_position()
	for c in cities_node.get_children():
		if c is City:
			if c.global_position.distance_to(mouse) <= city_pick_radius:
				return c
	return null

func _is_adjacent(a: City, b: City) -> bool:
	if a == null or b == null or a.data == null or b.data == null:
		return false
	if not adj.has(a.data.id):
		return false
	return adj[a.data.id].has(b.data.id)

func _send_units(from_city: City, to_city: City) -> void:
	_do_send(from_city, to_city, player_send_ratio)

func send_units_from(from_city: City, to_city: City, ratio: float) -> void:
	if not _is_adjacent(from_city, to_city):
		return
	_do_send(from_city, to_city, ratio)

func _do_send(from_city: City, to_city: City, ratio: float) -> void:
	if from_city == null or to_city == null:
		return
	if from_city.data == null or to_city.data == null:
		return
	if units_node == null or unit_scene == null:
		return

	var road: RoadData = get_road_between(from_city.data.id, to_city.data.id)
	if road == null:
		return

	# A faction may only have one unit (marching or fighting) on a road at a time.
	if _is_road_occupied_by(road, from_city.data.owner):
		return

	# Cannot send if an enemy battle has ALREADY REACHED from_city (city is under siege).
	# But CAN send to intercept an enemy still marching along the road toward from_city.
	if _is_city_under_active_siege(from_city):
		return

	var send_amount: int = from_city.compute_send_amount(ratio, min_send_amount)
	if send_amount <= 0:
		return
	var actual: int = from_city.remove_units(send_amount)
	if actual <= 0:
		return

	var unit_instance: Node = unit_scene.instantiate()
	if unit_instance is Unit:
		var unit: Unit = unit_instance
		units_node.add_child(unit)
		unit.setup(from_city, to_city, road, actual, from_city.data.owner)
		unit.arrived.connect(_on_unit_arrived)

func _on_unit_arrived(unit: Unit, target_city: City) -> void:
	if target_city == null or not is_instance_valid(target_city):
		unit.queue_free()
		return

	var arriving_owner: int = unit.unit_owner
	var arriving_amount: int = unit.amount
	var arriving_road: RoadData = unit.road

	if target_city.data == null:
		unit.queue_free()
		return

	if target_city.data.owner == arriving_owner:
		unit.queue_free()
		target_city.receive_reinforcement(arriving_amount)
		return

	unit.park_at_city()
	_start_battle(arriving_amount, arriving_owner, target_city, arriving_road, unit)

func _start_battle(attackers: int, attacker_owner: int, target_city: City, road_data: RoadData = null, parked_unit: Unit = null) -> void:
	if battle_scene == null or battles_node == null:
		# Instant fallback
		var eff: int = int(float(target_city.data.army) * target_city.data.get_defense_multiplier())
		var att_rem: int = attackers - eff
		var def_rem: int = target_city.data.army - attackers
		if att_rem > 0:
			target_city.apply_capture(att_rem, attacker_owner)
		elif def_rem > 0:
			target_city.data.army = def_rem
			target_city.refresh_from_data()
		else:
			target_city.data.army = 0
			target_city.refresh_from_data()
		if parked_unit != null and is_instance_valid(parked_unit):
			parked_unit.queue_free()
		return

	var battle_instance := battle_scene.instantiate()
	if battle_instance is Battle:
		var battle: Battle = battle_instance
		battles_node.add_child(battle)
		battle.setup(attackers, attacker_owner, target_city, road_data, parked_unit)
		battle.battle_ended.connect(_on_battle_ended)

func _on_battle_ended(_battle: Battle, _survivors: int, _owner: int) -> void:
	if game_ui != null and game_ui.has_method("refresh_selected_city"):
		game_ui.refresh_selected_city()

## Returns true if the given faction already has a unit marching OR a battle
## active on this road (one-unit-per-road-per-faction rule).
func _is_road_occupied_by(road: RoadData, faction_owner: int) -> bool:
	if road == null:
		return false
	if units_node != null:
		for child in units_node.get_children():
			if child is Unit:
				var u: Unit = child as Unit
				if u.unit_owner == faction_owner and u.road != null:
					var same: bool = (u.road.a_id == road.a_id and u.road.b_id == road.b_id) \
						or (u.road.a_id == road.b_id and u.road.b_id == road.a_id)
					if same:
						return true
	if battles_node != null:
		for child in battles_node.get_children():
			if child is Battle:
				var b: Battle = child as Battle
				if b.attacker_owner == faction_owner and b.road != null:
					var same: bool = (b.road.a_id == road.a_id and b.road.b_id == road.b_id) \
						or (b.road.a_id == road.b_id and b.road.b_id == road.a_id)
					if same:
						return true
	return false

## Returns true if from_city is currently under active siege (enemy battle
## has already arrived at the city). In this case, sending a sortie would be
## pointless since the city-battle is already underway.
## This does NOT block sending if an enemy is merely marching toward the city —
## in that case the player can intercept with a field battle.
func _is_city_under_active_siege(from_city: City) -> bool:
	if from_city == null or from_city.data == null:
		return false
	if battles_node != null:
		for child in battles_node.get_children():
			if child is Battle:
				var b: Battle = child as Battle
				if b.attacker_owner != from_city.data.owner and b.target_city == from_city:
					return true
	return false

func get_road_between(a: int, b: int) -> RoadData:
	for r: RoadData in roads:
		if r == null:
			continue
		if (r.a_id == a and r.b_id == b) or (r.a_id == b and r.b_id == a):
			return r
	return null

func _build_adjacency_from_roads() -> void:
	adj.clear()
	for id in cities_by_id.keys():
		adj[id] = []
	for r: RoadData in roads:
		if r == null:
			continue
		if not cities_by_id.has(r.a_id) or not cities_by_id.has(r.b_id):
			continue
		adj[r.a_id].append(r.b_id)
		adj[r.b_id].append(r.a_id)
