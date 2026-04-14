extends Node
class_name AIController

const AI_OWNER: int = 2

# How many cycles between attack decisions (increase to slow AI down)
@export var decision_every_n_cycles: int = 8
@export var min_attack_troops: int = 8
@export var attack_ratio: float = 0.6
@export var reinforce_ratio: float = 0.4
@export var attack_confidence: float = 1.2

var graph_map: GraphMap = null
var _cycle_count: int = 0

func _ready() -> void:
	CycleClock.cycle_ticked.connect(_on_cycle)

func _exit_tree() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_cycle):
		CycleClock.cycle_ticked.disconnect(_on_cycle)

func set_graph_map(gm: GraphMap) -> void:
	graph_map = gm

func _on_cycle() -> void:
	if graph_map == null:
		return

	# Attack/intercept decision every N cycles
	_cycle_count += 1
	if _cycle_count >= decision_every_n_cycles:
		_cycle_count = 0
		# Upgrade decisions bundled with attack decisions so AI isn't too reactive
		_try_ai_upgrades()
		_make_attack_decisions()

func _try_ai_upgrades() -> void:
	var cities: Array[City] = _get_ai_cities()
	if cities.is_empty():
		return

	var gold: float = FactionState.get_gold(AI_OWNER)
	if gold <= 0:
		return

	var best_city: City = null
	var best_cost: int = 999999
	var best_type: String = ""

	for city in cities:
		if city.data == null:
			continue

		if city.data.production_level < 3:
			var cost := city.data.get_production_upgrade_cost()
			if cost < best_cost and FactionState.can_afford(AI_OWNER, float(cost)):
				best_cost = cost
				best_city = city
				best_type = "production"

		if city.data.gold_level < 3:
			var cost := city.data.get_gold_upgrade_cost()
			if cost < best_cost and FactionState.can_afford(AI_OWNER, float(cost)):
				best_cost = cost
				best_city = city
				best_type = "gold"

		if city.data.defense_level < 3 and _is_threatened(city):
			var cost := city.data.get_defense_upgrade_cost()
			if cost < best_cost and FactionState.can_afford(AI_OWNER, float(cost)):
				best_cost = cost
				best_city = city
				best_type = "defense"

	if best_city == null:
		return

	match best_type:
		"production": best_city.data.apply_production_upgrade()
		"gold":       best_city.data.apply_gold_upgrade()
		"defense":    best_city.data.apply_defense_upgrade()

	best_city.refresh_from_data()

func _is_threatened(city: City) -> bool:
	if graph_map == null or city.data == null:
		return false
	for neighbor in graph_map.get_adjacent_cities(city):
		if neighbor.data != null and neighbor.data.owner != AI_OWNER:
			if neighbor.data.army > city.data.army:
				return true
	return false

func _make_attack_decisions() -> void:
	for city in _get_ai_cities():
		if city.data != null and city.data.army >= min_attack_troops:
			_decide_for_city(city)

func _decide_for_city(city: City) -> void:
	var neighbors: Array[City] = []
	for n in graph_map.get_adjacent_cities(city):
		if n is City:
			neighbors.append(n as City)

	if neighbors.is_empty():
		return

	var enemy_neighbors: Array[City] = []
	var friendly_neighbors: Array[City] = []

	for neighbor in neighbors:
		if neighbor.data == null:
			continue
		if neighbor.data.owner != AI_OWNER:
			enemy_neighbors.append(neighbor)
		else:
			friendly_neighbors.append(neighbor)

	# Priority 0: Intercept an incoming enemy army marching toward this city
	# (only if the city itself is not already under active siege)
	if not _city_is_under_siege(city):
		for neighbor in enemy_neighbors:
			if neighbor.data == null:
				continue
			var road := graph_map.get_road_between(city.data.id, neighbor.data.id)
			if road == null:
				continue
			# Check if an enemy unit is marching toward this city along that road
			if _enemy_marching_toward(road, city) and city.data.army >= min_attack_troops:
				# Send an interception sortie — use the full attack ratio for maximum effect
				graph_map.send_units_from(city, neighbor, attack_ratio)
				return

	# Priority 1: Attack if clearly outnumbering
	var best_target: City = null
	var best_ratio: float = 0.0

	for target in enemy_neighbors:
		if target.data == null:
			continue
		var def_mult: float = target.data.get_defense_multiplier() if target.data.owner != 0 else 1.0
		var effective_defense: float = float(target.data.army) * def_mult
		if effective_defense < 1.0:
			effective_defense = 1.0
		var ratio: float = float(city.data.army) / effective_defense
		if ratio > best_ratio:
			best_ratio = ratio
			best_target = target

	if best_target != null and best_ratio >= attack_confidence:
		graph_map.send_units_from(city, best_target, attack_ratio)
		return

	# Priority 2: Reinforce threatened friendly neighbors
	var reinforce_target: City = null
	var lowest_army: int = city.data.army

	for neighbor in friendly_neighbors:
		if neighbor.data == null or neighbor.data.army >= lowest_army:
			continue
		var neighbor_neighbors: Array[City] = []
		for nn in graph_map.get_adjacent_cities(neighbor):
			if nn is City:
				neighbor_neighbors.append(nn as City)
		var threatened: bool = false
		for nn in neighbor_neighbors:
			if nn.data != null and nn.data.owner != AI_OWNER and nn.data.army > neighbor.data.army:
				threatened = true
				break
		if threatened:
			lowest_army = neighbor.data.army
			reinforce_target = neighbor

	if reinforce_target != null:
		graph_map.send_units_from(city, reinforce_target, reinforce_ratio)
		return

	# Priority 3: Attack weakest adjacent enemy anyway
	if best_target != null:
		graph_map.send_units_from(city, best_target, attack_ratio)

## Returns true if an active city-battle (enemy already at city walls) targets this city.
func _city_is_under_siege(city: City) -> bool:
	if graph_map == null or graph_map.battles_node == null:
		return false
	for child in graph_map.battles_node.get_children():
		if child is Battle:
			var b: Battle = child as Battle
			if b.attacker_owner != AI_OWNER and b.target_city == city:
				return true
	return false

## Returns true if an enemy unit is currently marching along road toward target_city.
func _enemy_marching_toward(road: RoadData, target_city: City) -> bool:
	if graph_map == null or graph_map.units_node == null or road == null:
		return false
	for child in graph_map.units_node.get_children():
		if child is Unit:
			var u: Unit = child as Unit
			if u.unit_owner == AI_OWNER:
				continue
			if u.road == null:
				continue
			var same: bool = (u.road.a_id == road.a_id and u.road.b_id == road.b_id) \
				or (u.road.a_id == road.b_id and u.road.b_id == road.a_id)
			if same and u.target_city == target_city:
				return true
	return false

func _get_ai_cities() -> Array[City]:
	var result: Array[City] = []
	if graph_map == null:
		return result
	for c in graph_map.get_all_cities():
		if c is City and c.data != null and c.data.owner == AI_OWNER:
			result.append(c as City)
	return result
