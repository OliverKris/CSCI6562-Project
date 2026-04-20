extends Resource
class_name CitySpawnData

@export var id: int = 0
@export var city_name: String = ""
@export var hex_coord: Vector2 = Vector2.ZERO
@export var owner: int = 0
@export var army: int = 10
@export var defense_level: int = 0  # 0–3, mirrors CityData.defense_level
