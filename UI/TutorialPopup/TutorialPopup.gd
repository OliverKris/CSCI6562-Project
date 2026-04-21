extends CanvasLayer

signal dismissed

@onready var backdrop: ColorRect = $ColorRect
@onready var panel: PanelContainer = $Panel
@onready var text_label: Label = $Panel/MarginContainer/VBoxContainer/Label
@onready var ok_button: TextureButton = $Panel/MarginContainer/VBoxContainer/Button
@onready var video_player: VideoStreamPlayer = $Panel/MarginContainer/VBoxContainer/VideoStreamPlayer

@export var backdrop_target_alpha: float = 0.6
@export var open_duration: float = 0.22
@export var close_duration: float = 0.14
@export var start_scale: Vector2 = Vector2(0.96, 0.96)
@export var end_scale: Vector2 = Vector2.ONE
@export var open_offset: Vector2 = Vector2(0, 8)
@export var close_offset: Vector2 = Vector2(0, 6)

var _pending_text: String = ""
var _pending_video: String = ""
var _is_closing: bool = false
var _panel_rest_position: Vector2
var _active_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if ok_button != null and not ok_button.pressed.is_connected(_on_ok_pressed):
		ok_button.pressed.connect(_on_ok_pressed)

	if panel != null:
		_panel_rest_position = panel.position

	if _pending_text != "" or _pending_video != "":
		_apply_content(_pending_text, _pending_video)

	_setup_initial_visual_state()
	_animate_in()

func set_content(text: String, video_path: String = "") -> void:
	if not is_inside_tree():
		_pending_text = text
		_pending_video = video_path
		return

	_apply_content(text, video_path)

func _apply_content(text: String, video_path: String) -> void:
	if text_label != null:
		text_label.text = text

	if video_player == null:
		return

	if video_path.strip_edges() == "":
		video_player.stop()
		video_player.stream = null
		video_player.hide()
		return

	var stream := load(video_path)
	if stream == null:
		push_warning("TutorialPopup: Failed to load video at path: %s" % video_path)
		video_player.stop()
		video_player.stream = null
		video_player.hide()
		return

	video_player.stream = stream
	video_player.process_mode = Node.PROCESS_MODE_ALWAYS
	video_player.show()
	video_player.play()

func _setup_initial_visual_state() -> void:
	if backdrop != null:
		backdrop.modulate.a = 0.0

	if panel != null:
		panel.modulate.a = 0.0
		panel.scale = start_scale
		panel.position = _panel_rest_position + open_offset

func _animate_in() -> void:
	_kill_active_tween()

	_active_tween = create_tween()
	_active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	if backdrop != null:
		_active_tween.parallel().tween_property(
			backdrop,
			"modulate:a",
			backdrop_target_alpha,
			open_duration
		)

	if panel != null:
		_active_tween.parallel().tween_property(
			panel,
			"modulate:a",
			1.0,
			open_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		_active_tween.parallel().tween_property(
			panel,
			"scale",
			end_scale,
			open_duration
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		_active_tween.parallel().tween_property(
			panel,
			"position",
			_panel_rest_position,
			open_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animate_out() -> void:
	if _is_closing:
		return

	_is_closing = true

	if ok_button != null:
		ok_button.disabled = true

	_kill_active_tween()

	_active_tween = create_tween()
	_active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	if backdrop != null:
		_active_tween.parallel().tween_property(
			backdrop,
			"modulate:a",
			0.0,
			close_duration
		)

	if panel != null:
		_active_tween.parallel().tween_property(
			panel,
			"modulate:a",
			0.0,
			close_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		_active_tween.parallel().tween_property(
			panel,
			"scale",
			Vector2(0.98, 0.98),
			close_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		_active_tween.parallel().tween_property(
			panel,
			"position",
			_panel_rest_position + close_offset,
			close_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await _active_tween.finished

	if video_player != null:
		video_player.stop()

	dismissed.emit()
	queue_free()

func _on_ok_pressed() -> void:
	_animate_out()

func _kill_active_tween() -> void:
	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()
	_active_tween = null
