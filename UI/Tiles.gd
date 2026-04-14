extends Node2D

@export var grass_textures: Array[Texture2D]

const HEX_SIZE := 64.0

func hex_to_local(hex: Vector2i) -> Vector2:
	var x := HEX_SIZE * 1.5 * float(hex.x)
	var y := HEX_SIZE * sqrt(3.0) * (float(hex.y) + 0.5 * float(hex.x))
	return Vector2(x, y)

func spawn_hex_tile(hex: Vector2i, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = hex_to_local(hex)
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	print("Spawned hex at", hex, "->", sprite.position)

func _ready() -> void:
	z_index = -10

	if grass_textures.is_empty():
		push_error("No grass textures assigned.")
		return

	print("Hex ground test starting. Texture count:", grass_textures.size())

	for q in range(-5, 6):
		for r in range(-5, 6):
			var tex := grass_textures[randi() % grass_textures.size()]
			spawn_hex_tile(Vector2i(q, r), tex)
