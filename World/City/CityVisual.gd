extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_ring: Sprite2D = $"../SelectionRing"

@export var base_scale: Vector2 = Vector2.ONE
@export var selected_scale_multiplier: float = 1.1

@export var player_colors: Array[Color] = [
	Color("2aa8e0"),
	Color("1f90c4"),
	Color("4fc2ee")
]

@export var enemy_colors: Array[Color] = [
	Color("e24a4a"),
	Color("c23a3a"),
	Color("f06a6a")
]

@export var neutral_colors: Array[Color] = [
	Color("7a7f87"),
	Color("656a72"),
	Color("9aa0a8")
]

var current_owner: int = 0
var chosen_color: Color = Color.WHITE

func _ready() -> void:
	randomize()
	scale = base_scale

func set_faction(owner: int) -> void:
	current_owner = owner
	chosen_color = _pick_city_color(owner)

	if sprite == null:
		return

	sprite.modulate = chosen_color

func _pick_city_color(owner: int) -> Color:
	randomize()
	var palette: Array[Color] = neutral_colors

	match owner:
		1:
			palette = player_colors
		2:
			palette = enemy_colors
		_:
			palette = neutral_colors

	if palette.is_empty():
		return Color.WHITE

	var idx : int = abs(name.hash()) % palette.size()
	return palette[idx]

func set_selected(selected: bool) -> void:
	selection_ring.visible = selected

func get_radius() -> float:
	if sprite == null or sprite.texture == null:
		return 24.0

	var tex_size: Vector2 = sprite.texture.get_size()
	var effective_size: Vector2 = tex_size * sprite.scale * scale
	return max(effective_size.x, effective_size.y) * 0.5
