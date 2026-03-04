extends Resource
class_name CityData

@export var id: int = 0
@export var name: String = "City"
# 0=neutral, 1=player, 2=enemy
@export var owner: int = 0

@export var army: int = 10:
	set(value):
		army = max(value, 0)
		emit_signal("changed")

@export var production_per_sec: float = 1.0:
	set(value):
		production_per_sec = max(value, 0.0)
		emit_signal("changed")
		
@export var max_army: int = 9999:
	set(value):
		max_army = max(value, 0)
		emit_signal("changed")
