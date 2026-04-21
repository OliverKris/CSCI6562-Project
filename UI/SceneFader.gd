extends CanvasLayer
class_name SceneFader

@onready var fade_rect: ColorRect = $ColorRect

@export var fade_out_duration: float = 0.3
@export var fade_in_duration: float = 0.3
@export var max_alpha: float = 1.0

var _is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0

func fade_to_black(duration: float = fade_out_duration) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", max_alpha, duration)
	await tween.finished

func fade_from_black(duration: float = fade_in_duration) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished

func change_scene_faded(path: String) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_from_black()

	_is_transitioning = false
