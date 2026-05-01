extends Node
class_name TutorialManager

const TUTORIAL_POPUP_SCENE := preload("res://UI/TutorialPopup/TutorialPopup.tscn")
const MISSION_POPUP_SCENE := preload("res://UI/TutorialPopup/MissionPopup.tscn")

# ---------------------------------------------------------
# Video Paths
# ---------------------------------------------------------
const VIDEO_UI := "res://UI/TutorialVideos/TutorialUI.ogv"
const VIDEO_UPGRADE := "res://UI/TutorialVideos/TutorialUpgrade.ogv"
const VIDEO_SEND := "res://UI/TutorialVideos/TutorialBattle.ogv"
const VIDEO_CONQUER := "res://UI/TutorialVideos/TutorialWin.ogv"

# ---------------------------------------------------------
# Tutorial Step Definitions
# ---------------------------------------------------------
const STEPS := [
	{
		"id": "time_controls",
		"title": "Learn Time Controls",
		"text": "Click on the Speed Dials and Pause Buttons to navigate time!",
		"video": VIDEO_UI,
		"goals": [
			{ "id": "speed_interacted", "text": "Use a speed control" },
			{ "id": "paused", "text": "Pause the game" },
			{ "id": "resumed", "text": "Resume the game" }
		]
	},
	{
		"id": "upgrades",
		"title": "Upgrade a City",
		"text": "Select one of your cities and use gold to purchase all three upgrade types!\nYou can see how much gold you have in the top left!\nTip: You can increase speed to finish this step sooner!",
		"video": VIDEO_UPGRADE,
		"goals": [
			{ "id": "upgrade_production", "text": "Buy a production upgrade" },
			{ "id": "upgrade_gold", "text": "Buy a gold upgrade" },
			{ "id": "upgrade_defense", "text": "Buy a defense upgrade" }
		]
	},
	{
		"id": "capture_city",
		"title": "Capture a City",
		"text": "Select a ratio and send troops by left-clicking a city and dragging to an adjacent enemy city to capture it!",
		"video": VIDEO_SEND,
		"goals": [
			{ "id": "captured_city", "text": "Capture an enemy city" }
		]
	},
	{
		"id": "finish_game",
		"title": "Win the Mission",
		"text": "Play around with the Interface and Mechanics!\nWhen you feel confident, beat the game by capturing the final enemy city!",
		"video": VIDEO_CONQUER,
		"goals": [
			{ "id": "won_game", "text": "Capture the final enemy city" }
		]
	}
]

# ---------------------------------------------------------
# References
# ---------------------------------------------------------
var game_ui = null
var graph_map = null

# ---------------------------------------------------------
# State
# ---------------------------------------------------------
var is_tutorial_active: bool = false
var _current_step_index: int = -1
var _completed_goals: Dictionary = {}

var _current_popup = null
var _mission_popup = null

var _is_transitioning: bool = false
var _waiting_for_popup_close: bool = false

@export var step_complete_hold_duration: float = 1.0

# ---------------------------------------------------------
# Setup / Lifecycle
# ---------------------------------------------------------
func setup(ui, map) -> void:
	game_ui = ui
	graph_map = map

func _ready() -> void:
	await get_tree().process_frame

	if not _should_run_tutorial():
		return

	is_tutorial_active = true
	_connect_signals()
	await start_tutorial()

func _should_run_tutorial() -> bool:
	if game_ui == null or graph_map == null:
		return false
	if graph_map.level_data == null:
		return false
	return "Tutorial" in graph_map.level_data.level_name

func _connect_signals() -> void:
	if game_ui == null:
		return

	if not game_ui.speed_interacted.is_connected(_on_speed_interacted):
		game_ui.speed_interacted.connect(_on_speed_interacted)

	if not game_ui.game_paused.is_connected(_on_paused):
		game_ui.game_paused.connect(_on_paused)

	if not game_ui.game_resumed.is_connected(_on_resumed):
		game_ui.game_resumed.connect(_on_resumed)

	if not game_ui.upgrade_purchased.is_connected(_on_upgrade_purchased):
		game_ui.upgrade_purchased.connect(_on_upgrade_purchased)

	if not game_ui.player_city_count_changed.is_connected(_on_player_city_count_changed):
		game_ui.player_city_count_changed.connect(_on_player_city_count_changed)

# ---------------------------------------------------------
# Tutorial Flow
# ---------------------------------------------------------
func start_tutorial() -> void:
	if STEPS.is_empty():
		return

	await get_tree().create_timer(1.0).timeout

	_current_step_index = 0
	_reset_current_step_progress()
	_show_tutorial_popup_for_current_step()

func advance_step() -> void:
	await _handle_step_completed()

func finish_tutorial() -> void:
	is_tutorial_active = false
	_current_step_index = -1
	_completed_goals.clear()

	if _mission_popup != null and is_instance_valid(_mission_popup):
		if _mission_popup.has_method("hide_popup"):
			_mission_popup.hide_popup()

# ---------------------------------------------------------
# Step Helpers
# ---------------------------------------------------------
func _get_current_step() -> Dictionary:
	if _current_step_index < 0 or _current_step_index >= STEPS.size():
		return {}
	return STEPS[_current_step_index]

func _reset_current_step_progress() -> void:
	_completed_goals.clear()

	var step := _get_current_step()
	for goal in step.get("goals", []):
		var goal_id := str(goal.get("id", ""))
		if goal_id != "":
			_completed_goals[goal_id] = false

func _is_current_step_complete() -> bool:
	if _completed_goals.is_empty():
		return false

	for value in _completed_goals.values():
		if value == false:
			return false

	return true

# ---------------------------------------------------------
# Popup Control
# ---------------------------------------------------------
func _show_tutorial_popup_for_current_step() -> void:
	var step := _get_current_step()
	if step.is_empty():
		return

	_show_popup(step["text"], step["video"])

func _show_popup(text: String, video_path: String) -> void:
	if game_ui == null:
		return

	var popup = TUTORIAL_POPUP_SCENE.instantiate()
	if popup == null:
		push_error("TutorialManager: Failed to instantiate TutorialPopup.")
		return

	game_ui.add_child(popup)
	_current_popup = popup
	_waiting_for_popup_close = true

	if not popup.has_method("set_content"):
		push_error("TutorialManager: Popup instance is missing set_content().")
		return

	popup.set_content(text, video_path)

	if popup.has_signal("dismissed") and not popup.dismissed.is_connected(_on_popup_dismissed):
		popup.dismissed.connect(_on_popup_dismissed)

	get_tree().paused = true

func _on_popup_dismissed() -> void:
	_current_popup = null
	_waiting_for_popup_close = false

	if game_ui != null and not game_ui._paused:
		get_tree().paused = false

	await get_tree().process_frame
	_show_mission_popup_for_current_step()

# ---------------------------------------------------------
# Mission Popup Control
# ---------------------------------------------------------
func _show_mission_popup_for_current_step() -> void:
	if not is_tutorial_active:
		return

	if game_ui == null:
		return

	var step := _get_current_step()
	if step.is_empty():
		return

	if _mission_popup == null or not is_instance_valid(_mission_popup):
		_mission_popup = MISSION_POPUP_SCENE.instantiate()

		if _mission_popup == null:
			push_error("TutorialManager: Failed to instantiate MissionPopup.")
			return

		game_ui.add_child(_mission_popup)

	if _mission_popup.has_method("set_mission_data"):
		_mission_popup.set_mission_data(step["title"], step["goals"])
	else:
		push_error("TutorialManager: MissionPopup is missing set_mission_data().")
		return

	if _mission_popup.has_method("show_popup"):
		_mission_popup.show_popup()
	else:
		push_error("TutorialManager: MissionPopup is missing show_popup().")

func _hide_mission_popup_for_transition() -> void:
	if _mission_popup == null or not is_instance_valid(_mission_popup):
		return

	if _mission_popup.has_method("hide_popup_and_wait"):
		await _mission_popup.hide_popup_and_wait()
	elif _mission_popup.has_method("hide_popup"):
		_mission_popup.hide_popup()
		await get_tree().create_timer(0.3).timeout

# ---------------------------------------------------------
# Goal Tracking
# ---------------------------------------------------------
func _mark_goal_complete(goal_id: String) -> void:
	if not is_tutorial_active:
		return

	if _is_transitioning:
		return

	if _waiting_for_popup_close:
		return

	if not _completed_goals.has(goal_id):
		return

	if _completed_goals[goal_id]:
		return

	_completed_goals[goal_id] = true

	if _mission_popup != null and is_instance_valid(_mission_popup):
		if _mission_popup.has_method("mark_objective_complete"):
			_mission_popup.mark_objective_complete(goal_id)

	if _is_current_step_complete():
		await _handle_step_completed()
	if not is_tutorial_active:
		return

	if _is_transitioning:
		return

	if _waiting_for_popup_close:
		return

	if not _completed_goals.has(goal_id):
		return

	if _completed_goals[goal_id]:
		return

	_completed_goals[goal_id] = true

	if _mission_popup != null and is_instance_valid(_mission_popup):
		if _mission_popup.has_method("mark_objective_complete"):
			_mission_popup.mark_objective_complete(goal_id)

	if _is_current_step_complete():
		await advance_step()

func _handle_step_completed() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	# Let the player briefly see the completed objectives.
	await get_tree().create_timer(step_complete_hold_duration).timeout

	# Slide the mission popup away.
	await _hide_mission_popup_for_transition()

	_current_step_index += 1

	if _current_step_index >= STEPS.size():
		finish_tutorial()
		_is_transitioning = false
		return

	_reset_current_step_progress()

	# Small pause before the next tutorial popup appears.
	await get_tree().create_timer(0.5).timeout
	_show_tutorial_popup_for_current_step()

	_is_transitioning = false

# ---------------------------------------------------------
# Signal Handlers
# ---------------------------------------------------------
func _on_speed_interacted() -> void:
	_mark_goal_complete("speed_interacted")

func _on_paused() -> void:
	_mark_goal_complete("paused")

func _on_resumed() -> void:
	_mark_goal_complete("resumed")

func _on_upgrade_purchased(type: String) -> void:
	match type:
		"production":
			_mark_goal_complete("upgrade_production")
		"gold":
			_mark_goal_complete("upgrade_gold")
		"defense":
			_mark_goal_complete("upgrade_defense")

func _on_player_city_count_changed(new_count: int) -> void:
	var step := _get_current_step()
	if step.is_empty():
		return

	var step_id := str(step.get("id", ""))

	if step_id == "capture_city":
		if new_count > 1:
			_mark_goal_complete("captured_city")
	elif step_id == "finish_game":
		if graph_map != null and graph_map.has_method("get_all_cities"):
			var all_cities = graph_map.get_all_cities()
			var enemy_exists := false

			for city in all_cities:
				if city != null and city.data != null and city.data.owner == 2:
					enemy_exists = true
					break

			if not enemy_exists:
				_mark_goal_complete("won_game")
