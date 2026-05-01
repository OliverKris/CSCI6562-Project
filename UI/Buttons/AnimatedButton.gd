extends TextureButton
class_name AnimatedIconButton

signal activated

@onready var icon: TextureRect = $Icon

@export var sprite_sheet: Texture2D
@export var frame_count: int = 4
@export var flipped: bool = false

@export var press_in_time: float = 0.04
@export var release_time: float = 0.04
@export var toggle_off_time: float = 0.01

@export var is_toggle_button: bool = false
@export var start_toggled_on: bool = false

@export var hover_brightness: float = 1.18
@export var hover_time: float = 0.04

@export var hover_sound: AudioStream
@export var click_sound: AudioStream

@export var disabled_modulate: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var play_blocked_sound_when_disabled: bool = true

var _is_hovered: bool = false
var _hover_tween: Tween

var frame_textures: Array[AtlasTexture] = []
var _pressed_visual: bool = false
var _toggled_on: bool = false
var _anim_version: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if icon != null:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	toggle_mode = is_toggle_button
	button_pressed = start_toggled_on
	_toggled_on = start_toggled_on

	_build_frames()

	if icon != null:
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 0
		icon.offset_top = 0
		icon.offset_right = 0
		icon.offset_bottom = 0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_apply_current_visual()

	button_down.connect(_on_button_down_visual)
	if not is_toggle_button:
		button_up.connect(_on_button_up_visual)
	pressed.connect(_on_pressed_action)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_entered.connect(_on_hover_sound)
	mouse_exited.connect(_on_mouse_exited)

func _build_frames() -> void:
	frame_textures.clear()

	if sprite_sheet == null:
		push_error("%s: No sprite_sheet assigned." % name)
		return

	var sheet_size: Vector2 = sprite_sheet.get_size()
	if frame_count <= 0:
		push_error("%s: frame_count must be > 0." % name)
		return

	var frame_width: int = int(sheet_size.x / frame_count)
	var frame_height: int = int(sheet_size.y)

	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frame_textures.append(atlas)

func _set_frame(index: int) -> void:
	if icon == null:
		return
	if index < 0 or index >= frame_textures.size():
		return

	icon.texture = frame_textures[index]
	icon.flip_h = flipped

func _apply_current_visual() -> void:
	if disabled:
		_set_frame(0)
		_is_hovered = false
		if icon != null:
			icon.modulate = disabled_modulate
		return

	if _pressed_visual:
		_set_frame(2)
	elif _toggled_on:
		_set_frame(2)
	else:
		_set_frame(0)

	_apply_hover_visual()

func _on_button_down_visual() -> void:
	_pressed_visual = true
	_anim_version += 1
	var this_anim := _anim_version

	# If this is a toggle button that is already on,
	# we are starting an "unpress" click.
	if is_toggle_button and _toggled_on:
		_set_frame(1)
		return

	# Normal press-in behavior
	_set_frame(1)
	await get_tree().create_timer(press_in_time).timeout

	if this_anim != _anim_version:
		return

	if _pressed_visual:
		_set_frame(2)

func _on_button_up_visual() -> void:
	_pressed_visual = false
	_anim_version += 1
	var this_anim := _anim_version

	if is_toggle_button:
		return

	_set_frame(3)
	await get_tree().create_timer(release_time).timeout

	if this_anim != _anim_version:
		return

	_apply_current_visual()

func _on_hover_sound() -> void:
	if disabled:
		return
	AudioManager.play_hover(hover_sound)

func _on_pressed_action() -> void:
	AudioManager.play_click(click_sound)
	
	_anim_version += 1
	var this_anim := _anim_version

	if is_toggle_button:
		_pressed_visual = false
		_toggled_on = button_pressed

		if _toggled_on:
			_set_frame(2)
		else:
			_set_frame(1)
			await get_tree().create_timer(toggle_off_time).timeout

			if this_anim != _anim_version:
				return

			_set_frame(0)

		activated.emit()
		return

	activated.emit()

func set_toggled_state(value: bool) -> void:
	_anim_version += 1
	_pressed_visual = false
	_toggled_on = value
	if is_toggle_button:
		button_pressed = value
	_apply_current_visual()

func is_toggled_on() -> bool:
	return _toggled_on
	
func _on_mouse_entered() -> void:
	if disabled:
		_is_hovered = false
		_apply_hover_visual()
		return

	_is_hovered = true
	_apply_hover_visual()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_apply_hover_visual()
	
func _apply_hover_visual() -> void:
	if icon == null:
		return

	if _hover_tween != null:
		_hover_tween.kill()

	_hover_tween = create_tween()

	var target_color := Color(1, 1, 1, 1)

	if disabled:
		target_color = disabled_modulate
	elif _is_hovered:
		target_color = Color(hover_brightness, hover_brightness, hover_brightness, 1)

	_hover_tween.tween_property(icon, "modulate", target_color, hover_time)
	
func set_disabled_visual(value: bool) -> void:
	disabled = value
	_pressed_visual = false
	_is_hovered = false
	_apply_current_visual()

func _gui_input(event: InputEvent) -> void:
	if not disabled:
		return

	if not play_blocked_sound_when_disabled:
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		AudioManager.play_greyed_out()
		accept_event()
