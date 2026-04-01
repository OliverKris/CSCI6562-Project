extends Resource
class_name CityData

@export var id: int = 0
@export var name: String = "City"

# 0=neutral, 1=player, 2=enemy
@export var owner: int = 0:
	set(value):
		owner = value
		emit_changed()

@export var army: int = 10:
	set(value):
		army = max(value, 0)
		emit_changed()

@export var production_per_cycle: int = 1
@export var gold_per_cycle: int = 1
@export var max_army: int = 9999

# Upgrade tiers (0 = base, max 3)
@export var production_level: int = 0
@export var gold_level: int = 0
@export var defense_level: int = 0

func get_defense_multiplier() -> float:
	match defense_level:
		1: return 1.3
		2: return 1.6
		3: return 2.0
		_: return 1.0

const UPGRADE_BASE_COST: int = 50
const UPGRADE_COST_SCALE: float = 1.75

func get_upgrade_cost(level: int) -> int:
	return int(UPGRADE_BASE_COST * pow(UPGRADE_COST_SCALE, level))

func get_production_upgrade_cost() -> int:
	return get_upgrade_cost(production_level)

func get_gold_upgrade_cost() -> int:
	return get_upgrade_cost(gold_level)

func get_defense_upgrade_cost() -> int:
	return get_upgrade_cost(defense_level)

func apply_production_upgrade() -> bool:
	if production_level >= 3 or owner == 0:
		return false
	var cost := get_production_upgrade_cost()
	if not FactionState.spend_gold(owner, cost):
		return false
	production_level += 1
	production_per_cycle = 1 + production_level
	emit_changed()
	return true

func apply_gold_upgrade() -> bool:
	if gold_level >= 3 or owner == 0:
		return false
	var cost := get_gold_upgrade_cost()
	if not FactionState.spend_gold(owner, cost):
		return false
	gold_level += 1
	gold_per_cycle = 1 + gold_level
	emit_changed()
	return true

func apply_defense_upgrade() -> bool:
	if defense_level >= 3 or owner == 0:
		return false
	var cost := get_defense_upgrade_cost()
	if not FactionState.spend_gold(owner, cost):
		return false
	defense_level += 1
	emit_changed()
	return true
