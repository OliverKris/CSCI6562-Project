extends Node2D

@export var radius: float = 24.0
@export var fill_color: Color = Color(0.2, 0.6, 0.9, 1.0)
@export var outline_color: Color = Color(0.05, 0.05, 0.08, 1.0)
@export var outline_width: float = 2.0

func _draw():
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, outline_color, outline_width)

func set_selected(selected: bool):
	outline_color = Color(0.9, 0.8, 0.2, 1.0) if selected else Color(0.05, 0.05, 0.08, 1.0)
	queue_redraw()

func set_faction(owner: int):
	match owner:
		1: fill_color = Color(0.2, 0.7, 1.0) # player
		2: fill_color = Color(1.0, 0.3, 0.3) # enemy
		_: fill_color = Color(0.6, 0.6, 0.6) # neutral
	queue_redraw()
