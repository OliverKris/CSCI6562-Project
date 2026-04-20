extends Node

@onready var sprite: Sprite2D = $ClockSprite

@export var total_frames: int = 8

var current_frame: int = 0

func _ready() -> void:
	sprite.frame = 0
	CycleClock.cycle_ticked.connect(_on_cycle_ticked)

func _on_cycle_ticked() -> void:
	current_frame = (current_frame + 1) % total_frames
	sprite.frame = current_frame
