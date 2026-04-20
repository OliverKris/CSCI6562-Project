extends Node

# Separate gold pool per faction.
# faction 1 = player, faction 2 = AI enemy.
# Indexed by faction int.

signal gold_changed(faction: int, new_amount: float)

var _gold: Dictionary = { 1: 0.0, 2: 0.0 }

func get_gold(faction: int) -> float:
	return _gold.get(faction, 0.0)

func add_gold(faction: int, amount: float) -> void:
	if not _gold.has(faction):
		_gold[faction] = 0.0
	_gold[faction] += amount
	emit_signal("gold_changed", faction, _gold[faction])

func spend_gold(faction: int, amount: float) -> bool:
	if not _gold.has(faction):
		return false
	if _gold[faction] < amount:
		return false
	_gold[faction] -= amount
	emit_signal("gold_changed", faction, _gold[faction])
	return true

func can_afford(faction: int, amount: float) -> bool:
	return _gold.get(faction, 0.0) >= amount

func reset() -> void:
	_gold = { 1: 0.0, 2: 0.0 }
	emit_signal("gold_changed", 1, 0.0)
	emit_signal("gold_changed", 2, 0.0)
