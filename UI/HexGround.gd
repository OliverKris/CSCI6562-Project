extends Node2D

@export var grass_textures: Array[Texture2D]
@export var extra_hex_padding := 1
@export var base_radius := 7

@export var sprite_y_offset := 0

const HEX_SIZE := 64.0

func hex_to_local(hex: Vector2i) -> Vector2:
	var x := HEX_SIZE * 1.5 * float(hex.x)
	var y := HEX_SIZE * sqrt(3.0) * (float(hex.y) + 0.5 * float(hex.x))
	return Vector2(x, y)

func spawn_hex_tile(hex: Vector2i, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = hex_to_local(hex)
	sprite.centered = true
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, sprite_y_offset)
	add_child(sprite)

func _ready() -> void:
	z_index = -10

	if grass_textures.is_empty():
		push_error("No grass textures assigned.")
		return

	randomize()
	_generate_background()

func get_hexes_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []

	for q in range(-radius, radius + 1):
		var r_min : float = max(-radius, -q - radius)
		var r_max : float = min(radius, -q + radius)

		for r in range(r_min, r_max + 1):
			results.append(Vector2i(center.x + q, center.y + r))

	return results

func _generate_background() -> void:
	var radius : float = max(base_radius + extra_hex_padding, 0)
	var center_hex := Vector2i.ZERO
	var hexes := get_hexes_in_radius(center_hex, radius)

	hexes.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ay := hex_to_local(a).y
		var by := hex_to_local(b).y
		if ay == by:
			return hex_to_local(a).x < hex_to_local(b).x
		return ay < by
	)

	for hex in hexes:
		var tex := grass_textures[randi() % grass_textures.size()]
		spawn_hex_tile(hex, tex)
