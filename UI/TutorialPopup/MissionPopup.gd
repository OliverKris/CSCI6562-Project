extends Control
class_name MissionPopup

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderLabel
@onready var objectives_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ObjectivesContainer

const MISSION_ROW_SCENE := preload("res://UI/TutorialPopup/MissionRow.tscn")

@export var slide_duration: float = 0.28
@export var left_margin: float = 24.0
@export var bottom_margin: float = 24.0

var _slide_tween: Tween = null
var _is_visible_on_screen: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	await get_tree().process_frame

	visible = true
	panel.visible = true
	panel.position = Vector2(_get_hidden_x(), _get_shown_y())

func _setup_position() -> void:
	if panel == null:
		return

	panel.position = Vector2(_get_hidden_x(), _get_shown_y())

func _get_shown_x() -> float:
	return left_margin

func _get_hidden_x() -> float:
	if panel == null:
		return -500.0
	return -panel.size.x - left_margin

func _get_shown_y() -> float:
	var viewport_h := get_viewport_rect().size.y
	return viewport_h - panel.size.y - bottom_margin

func _kill_tween() -> void:
	if _slide_tween != null and is_instance_valid(_slide_tween):
		_slide_tween.kill()
	_slide_tween = null

func set_mission_data(title: String, goals: Array) -> void:
	title_label.text = title

	for child in objectives_container.get_children():
		child.queue_free()

	for goal in goals:
		var row = MISSION_ROW_SCENE.instantiate()
		objectives_container.add_child(row)

		if row.has_method("setup"):
			row.setup({
				"id": goal.get("id", ""),
				"text": goal.get("text", ""),
				"completed": false
			})

func mark_objective_complete(goal_id: String) -> void:
	for child in objectives_container.get_children():
		if child.has_method("set_completed") and child.objective_id == goal_id:
			child.set_completed(true)
			return

func show_popup() -> void:
	_kill_tween()

	visible = true
	panel.visible = true

	# Let Godot resolve the layout now that the popup is visible.
	await get_tree().process_frame

	# Recompute with the real final size.
	panel.position = Vector2(_get_hidden_x(), _get_shown_y())

	_slide_tween = create_tween()
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.set_ease(Tween.EASE_OUT)
	_slide_tween.tween_property(panel, "position:x", _get_shown_x(), slide_duration)

	await _slide_tween.finished

func hide_popup() -> void:
	if panel == null:
		return

	_kill_tween()

	_slide_tween = create_tween()
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.set_ease(Tween.EASE_IN)
	_slide_tween.tween_property(panel, "position:x", _get_hidden_x(), slide_duration)
	_slide_tween.tween_callback(func(): visible = false)

	_is_visible_on_screen = false

func hide_popup_and_wait() -> void:
	if panel == null:
		return

	_kill_tween()

	_slide_tween = create_tween()
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.set_ease(Tween.EASE_IN)
	_slide_tween.tween_property(panel, "position:x", _get_hidden_x(), slide_duration)
	await _slide_tween.finished
	visible = false
	_is_visible_on_screen = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if panel == null:
			return

		panel.position.y = _get_shown_y()

		if _is_visible_on_screen:
			panel.position.x = _get_shown_x()
		else:
			panel.position.x = _get_hidden_x()
