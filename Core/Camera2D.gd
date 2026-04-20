extends Camera2D

var is_panning: bool = false
var pan_origin_mouse: Vector2 = Vector2.ZERO
var pan_origin_camera: Vector2 = Vector2.ZERO
var pan_button: int = -1

@export var zoom_step: float = 0.15
@export var zoom_min: float = 0.7
@export var zoom_max: float = 2.5
@export var gesture_zoom_strength: float = 0.25

func _ready() -> void:
	pass  # Position is set by GameController after the level is built.

func _unhandled_input(event: InputEvent) -> void:
	_handle_pan(event)
	_handle_zoom(event)

func _handle_pan(event: InputEvent) -> void:
	# Right click drag pans
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_begin_pan(event.position, MOUSE_BUTTON_RIGHT)
		elif is_panning and pan_button == MOUSE_BUTTON_RIGHT:
			_end_pan()

	# Space + left click drag pans
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Input.is_key_pressed(KEY_SPACE):
				_begin_pan(event.position, MOUSE_BUTTON_LEFT)
		else:
			if is_panning and pan_button == MOUSE_BUTTON_LEFT:
				_end_pan()

	# If space is released during a left-pan, stop panning immediately
	if event is InputEventKey and event.keycode == KEY_SPACE and not event.pressed:
		if is_panning and pan_button == MOUSE_BUTTON_LEFT:
			_end_pan()

	if event is InputEventMouseMotion and is_panning:
		var delta: Vector2 = (event.position - pan_origin_mouse) / zoom.x
		position = pan_origin_camera - delta

func _handle_zoom(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_toward_mouse(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_toward_mouse(-zoom_step)
	elif event is InputEventMagnifyGesture:
		var delta: float = (event.factor - 1.0) * gesture_zoom_strength
		_zoom_toward_mouse(delta)

func _zoom_toward_mouse(step: float) -> void:
	var before: Vector2 = get_global_mouse_position()

	var new_zoom: float = clamp(zoom.x + step, zoom_min, zoom_max)
	zoom = Vector2(new_zoom, new_zoom)

	var after: Vector2 = get_global_mouse_position()
	position -= after - before

func _begin_pan(mouse_pos: Vector2, button: int) -> void:
	is_panning = true
	pan_origin_mouse = mouse_pos
	pan_origin_camera = position
	pan_button = button

func _end_pan() -> void:
	is_panning = false
	pan_button = -1

func start_left_pan(mouse_pos: Vector2) -> void:
	_begin_pan(mouse_pos, MOUSE_BUTTON_LEFT)

func stop_left_pan() -> void:
	if is_panning and pan_button == MOUSE_BUTTON_LEFT:
		_end_pan()

func is_left_panning() -> bool:
	return is_panning and pan_button == MOUSE_BUTTON_LEFT
