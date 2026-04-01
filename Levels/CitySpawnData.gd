extends Resource
class_name CitySpawnData

@export var id: int
@export var city_name: String = ""
# Hex grid coordinate (col, row) — GraphMap converts to world position
@export var hex_coord: Vector2i = Vector2i(0, 0)
@export var owner: int = 0
@export var army: int = 10
