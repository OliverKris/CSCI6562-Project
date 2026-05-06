extends Node

# Separate gold pool per faction.
# owner 1 = player, owner 2 = AI enemy.
# Indexed by owner int.

signal gold_changed(owner: int, new_amount: float)

var _gold: Dictionary = { 1: 0.0, 2: 0.0 }

func get_gold(owner: int) -> float:
	return _gold.get(owner, 0.0)

func add_gold(owner: int, amount: float) -> void:
	if not _gold.has(owner):
		_gold[owner] = 0.0
	_gold[owner] += amount
	emit_signal("gold_changed", owner, _gold[owner])

func spend_gold(owner: int, amount: float) -> bool:
	if not _gold.has(owner):
		return false
	if _gold[owner] < amount:
		return false
	_gold[owner] -= amount
	emit_signal("gold_changed", owner, _gold[owner])
	return true

func can_afford(owner: int, amount: float) -> bool:
	return _gold.get(owner, 0.0) >= amount

func reset() -> void:
	_gold = { 1: 0.0, 2: 0.0 }
	emit_signal("gold_changed", 1, 0.0)
	emit_signal("gold_changed", 2, 0.0)
