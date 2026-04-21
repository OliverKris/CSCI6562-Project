extends Node2D
class_name CosmeticTileLayer

@export var grass_texture: Texture2D
@export var grass_long_texture: Texture2D
@export var grass2_long_texture: Texture2D
@export var foliage1_texture: Texture2D
@export var foliage2_texture: Texture2D

@export var sprite_scale: Vector2 = Vector2(2, 2)
@export var sprite_y_offset: float = 0.0
@export var base_z_index: int = -5

const HEX_SIZE: float = 64.0

enum TerrainTile {
	NONE = 0,
	GRASS1_LONG = 1,
	GRASS2_LONG = 2,
}

var _tile_nodes: Dictionary = {}

func _ready() -> void:
	z_index = base_z_index

func hex_to_world(hex: Vector2i) -> Vector2:
	var x := HEX_SIZE * 1.5 * float(hex.x)
	var y := HEX_SIZE * (sqrt(3.0) / 2.0 * float(hex.x) + sqrt(3.0) * float(hex.y))
	return Vector2(x, y)

func clear_tiles() -> void:
	for child in get_children():
		child.queue_free()
	_tile_nodes.clear()

func rebuild_from_map(tile_map: Dictionary) -> void:
	clear_tiles()

	for hex in tile_map.keys():
		var tile_id: int = tile_map[hex]
		if tile_id == TerrainTile.NONE:
			continue

		var texture := _get_texture_for_tile(tile_id)
		if texture == null:
			continue

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = hex_to_world(hex)
		sprite.centered = true
		sprite.scale = sprite_scale
		sprite.offset = Vector2(0, sprite_y_offset)
		sprite.z_index = 0
		add_child(sprite)
		_tile_nodes[hex] = sprite

func _get_texture_for_tile(tile_id: int) -> Texture2D:
	match tile_id:
		TerrainTile.GRASS1_LONG:
			return grass_long_texture
		TerrainTile.GRASS2_LONG:
			return grass2_long_texture
		_:
			return null
