@tool
extends TextureRect
class_name UpgradeCounters

@export var sprite_sheet: Texture2D
@export var frame_width: int = 50
@export var frame_height: int = 16
@export var scale_factor: int = 1

var _current_level: int = 0

@export_range(0, 3) var current_level: int:
	get:
		return _current_level
	set(value):
		_current_level = clamp(value, 0, 3)
		_update_frame()

func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_SCALE
	_update_frame()

func _update_frame() -> void:
	if sprite_sheet == null:
		texture = null
		return

	var atlas := AtlasTexture.new()
	atlas.atlas = sprite_sheet
	atlas.region = Rect2(_current_level * frame_width, 0, frame_width, frame_height)
	texture = atlas

	custom_minimum_size = Vector2(frame_width, frame_height) * scale_factor
