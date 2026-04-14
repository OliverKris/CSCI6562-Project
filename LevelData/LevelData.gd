extends Resource
class_name LevelData

## Defines all the data for a single level: its cities and roads.
## Create one .tres file per level (e.g. Levels/LevelData/Level1.tres).
## Assign it to GenericLevel.tscn's GraphMap.level_data export.

@export var level_name: String = "Unnamed Level"
@export var description: String = ""

## All city spawn definitions for this level.
@export var cities: Array[CitySpawnData] = []

## All road connections between cities.
@export var roads: Array[RoadData] = []
