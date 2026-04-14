extends Node2D

@export var grass_textures: Array[Texture2D]
@export var extra_hex_padding := 6

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
	add_child(sprite)

func _ready() -> void:
	z_index = -10

	if grass_textures.is_empty():
		push_error("No grass textures assigned.")
		return

	_generate_background()

func _generate_background() -> void:
	var viewport_size := get_viewport_rect().size

	# Overshoot coverage so zooming/panning does not reveal empty space.
	var estimated_hex_width := HEX_SIZE * 2.0
	var estimated_hex_height := sqrt(3.0) * HEX_SIZE

	var q_radius := int(ceil(viewport_size.x / estimated_hex_width)) + extra_hex_padding
	var r_radius := int(ceil(viewport_size.y / estimated_hex_height)) + extra_hex_padding

	for q in range(-q_radius, q_radius + 1):
		for r in range(-r_radius, r_radius + 1):
			var tex := grass_textures[randi() % grass_textures.size()]
			spawn_hex_tile(Vector2i(q, r), tex)
