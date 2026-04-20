extends Node

var game_ui = null
var graph_map = null
var tutorial_popup_scene = preload("res://UI/TutorialPopup/TutorialPopup.tscn")

# Video Paths
const VIDEO_UI = "res://UI/TutorialVideos/TutorialUI.ogv"
const VIDEO_UPGRADE = "res://UI/TutorialVideos/UpgradeTutorial.ogv"
const VIDEO_SEND = "res://UI/TutorialVideos/SendTutorial.ogv"
const VIDEO_CONQUER = "res://UI/TutorialVideos/ConquerTutorial.ogv"

var is_tutorial_active: bool = false
var current_step: int = 0

# Tracking variables [cite: 4]
var has_interacted_with_speed: bool = false
var has_paused: bool = false
var has_resumed: bool = false
var has_upgraded_prod: bool = false
var has_upgraded_gold: bool = false
var has_upgraded_def: bool = false

func setup(ui, map):
	game_ui = ui
	graph_map = map

func _ready():
	await get_tree().process_frame
	if game_ui and graph_map and "Tutorial" in graph_map.level_data.level_name:
		is_tutorial_active = true
		_connect_signals()
		_start_tutorial()

func _connect_signals():
	game_ui.speed_interacted.connect(_on_speed_interacted)
	game_ui.game_paused.connect(_on_paused)
	game_ui.game_resumed.connect(_on_resumed)
	game_ui.upgrade_purchased.connect(_on_upgrade_purchased)
	game_ui.player_city_count_changed.connect(_on_city_captured)

func _start_tutorial():
	await get_tree().create_timer(1.0).timeout
	_show_popup("Click on the Speed Dials and Pause Buttons to navigate time!", VIDEO_UI)
	current_step = 1

func _on_speed_interacted():
	has_interacted_with_speed = true
	_check_step_1_completion()

func _on_paused():
	has_paused = true
	_check_step_1_completion()

func _on_resumed():
	has_resumed = true
	_check_step_1_completion()

func _check_step_1_completion():
	if current_step == 1 and has_interacted_with_speed and has_paused and has_resumed:
		current_step = 2
		await get_tree().create_timer(1.0).timeout
		_show_popup("Select one of your cities and purchase all three upgrade types!", VIDEO_UPGRADE)

func _on_upgrade_purchased(type):
	if current_step != 2: return
	match type:
		"production": has_upgraded_prod = true
		"gold": has_upgraded_gold = true
		"defense": has_upgraded_def = true
	
	if has_upgraded_prod and has_upgraded_gold and has_upgraded_def:
		current_step = 3
		await get_tree().create_timer(1.0).timeout
		_show_popup("Select a ratio and send troops by dragging to an adjacent enemy city to capture it!", VIDEO_SEND)

func _on_city_captured(_new_count):
	if current_step == 3:
		current_step = 4
		await get_tree().create_timer(1.0).timeout
		_show_popup("Beat the game by capturing the final enemy city!", VIDEO_CONQUER)

func _show_popup(text: String, video_path: String):
	var popup = tutorial_popup_scene.instantiate()
	game_ui.add_child(popup)
	
	# If the script failed to load, this check prevents a crash
	if not popup.has_method("set_content"):
		push_error("TutorialManager: Popup instance is missing script! Check file paths.")
		return
		
	popup.set_content(text, video_path)
	get_tree().paused = true
	
	if !popup.is_connected("dismissed", _on_popup_dismissed):
		popup.dismissed.connect(_on_popup_dismissed)

func _on_popup_dismissed():
	if not game_ui._paused:
		get_tree().paused = false
