extends CanvasLayer
class_name SceneTransition

@onready var color_rect: ColorRect = get_node_or_null("ColorRect")

@export var duration: float = .7
@export var black_hold_time: float = 0.25
@export var grid_size: float = 48.0
@export var cell_fill_portion: float = 0.28
@export var random_delay_strength: float = 0.04

var _is_running: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if color_rect == null:
		push_error("SceneTransition: missing child node 'ColorRect'")
		return

	var shader_material := color_rect.material as ShaderMaterial
	if shader_material == null:
		push_error("SceneTransition: ColorRect is missing a ShaderMaterial")
		return

	shader_material.set_shader_parameter("progress", 0.0)
	shader_material.set_shader_parameter("grid_size", grid_size)
	shader_material.set_shader_parameter("cell_fill_portion", cell_fill_portion)
	shader_material.set_shader_parameter("random_delay_strength", random_delay_strength)
	shader_material.set_shader_parameter("reveal_mode", false)

func _set_progress(value: float) -> void:
	if color_rect == null:
		return

	var shader_material := color_rect.material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("progress", clamp(value, 0.0, 1.0))

func _show_layer() -> void:
	visible = true

func _hide_layer() -> void:
	visible = false

func _set_reveal_mode(value: bool) -> void:
	if color_rect == null:
		return

	var shader_material := color_rect.material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("reveal_mode", value)

func change_scene(scene_path: String) -> void:
	if _is_running or color_rect == null:
		return

	_is_running = true
	_show_layer()

	# Fade out: top-left -> bottom-right
	_set_reveal_mode(false)
	_set_progress(0.0)

	var tween_out := create_tween()
	tween_out.set_trans(Tween.TRANS_LINEAR)
	tween_out.set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_method(_set_progress, 0.0, 1.0, duration)
	await tween_out.finished

	_set_progress(1.0)

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame

	if black_hold_time > 0.0:
		await get_tree().create_timer(black_hold_time, true, false, true).timeout

	# Fade in: also top-left -> bottom-right
	_set_reveal_mode(true)
	_set_progress(0.0)

	var tween_in := create_tween()
	tween_in.set_trans(Tween.TRANS_LINEAR)
	tween_in.set_ease(Tween.EASE_IN_OUT)
	tween_in.tween_method(_set_progress, 0.0, 1.0, duration)
	await tween_in.finished

	_hide_layer()
	_is_running = false
