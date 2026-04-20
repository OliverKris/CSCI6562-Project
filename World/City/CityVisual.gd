extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_ring: Sprite2D = $"../SelectionRing"

@export var base_scale: Vector2 = Vector2.ONE
@export var selected_scale_multiplier: float = 1.1

@export var player_color: Color = Color(0.2, 0.7, 1.0, 1.0)
@export var enemy_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var neutral_color: Color = Color(0.6, 0.6, 0.6, 1.0)

var current_owner: int = 0

func _ready() -> void:
	scale = base_scale

func set_faction(owner: int) -> void:
	current_owner = owner

	if sprite == null:
		return

	match owner:
		1:
			sprite.modulate = player_color
		2:
			sprite.modulate = enemy_color
		_:
			sprite.modulate = neutral_color

func set_selected(selected: bool) -> void:
	selection_ring.visible = selected
	
func get_radius() -> float:
	if sprite == null or sprite.texture == null:
		return 24.0

	var tex_size: Vector2 = sprite.texture.get_size()
	var effective_size: Vector2 = tex_size * sprite.scale * scale
	return max(effective_size.x, effective_size.y) * 0.5
