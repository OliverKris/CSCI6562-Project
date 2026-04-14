extends Control

var graph_map: GraphMap = null
var _selected_city: City = null
var _paused: bool = false

# ====================
# Dynamic UI Variables
# ====================

# Gold Counter
@onready var gold_label: Label = $TopBar/HBoxContainer/GoldContainer/Gold
@onready var gold_icon: TextureRect = $TopBar/HBoxContainer/GoldContainer/GoldIcon
@export var gold_icon_sheet: Texture2D
var _gold_icon_frames: Array[AtlasTexture] = []
const GOLD_ICON_COUNT := 8
const GOLD_ICON_SIZE := Vector2i(32, 32)

# Troop Counter
@onready var troops_label: Label = $TopBar/HBoxContainer/Troops

# Speed Controls
@onready var speed_label: Label = $TopBar/HBoxContainer/SpeedContainer/SpeedLabel
@onready var speed_slower_btn: TextureButton = $TopBar/HBoxContainer/SpeedContainer/SlowCenterContainer/SlowDown
@onready var speed_faster_btn: TextureButton = $TopBar/HBoxContainer/SpeedContainer/SpeedCenterContainer/SpeedUp
var _speed_index: int = 1  # default 1x
const SPEEDS: Array = [0.5, 1.0, 2.0, 4.0]
const SPEED_LABELS: Array = ["0.5x", "1x", "2x", "4x"]

# Pause Controls
@onready var pause_btn: TextureButton = $TopBar/HBoxContainer/PauseContainer/Pause


@onready var side_panel = $SidePanel
@onready var city_name_label: Label = $SidePanel/VBoxContainer/Selected_Node
@onready var city_troops_label: Label = $SidePanel/VBoxContainer/Troops
@onready var city_owner_label: Label = $SidePanel/VBoxContainer/Owner
@onready var send_slider: HSlider = $SidePanel/VBoxContainer/SendSlider
@onready var send_label: Label = $SidePanel/VBoxContainer/SendLabel
@onready var upgrade_prod_btn: Button = $SidePanel/VBoxContainer/UpgradeProduction
@onready var upgrade_gold_btn: Button = $SidePanel/VBoxContainer/UpgradeGold
@onready var upgrade_def_btn: Button = $SidePanel/VBoxContainer/UpgradeDefense

@onready var game_over_panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/VBoxContainer/Label
@onready var main_menu_btn_go: Button = $GameOverPanel/VBoxContainer/MainMenuButton

@onready var pause_panel = $PausePanel
@onready var resume_btn: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var main_menu_btn_pause: Button = $PausePanel/VBoxContainer/MainMenuButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.size_changed.connect(_on_window_resized)

	if side_panel != null:
		side_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if pause_panel != null:
		pause_panel.visible = false

	if upgrade_prod_btn != null:
		upgrade_prod_btn.pressed.connect(_on_upgrade_production)
	if upgrade_gold_btn != null:
		upgrade_gold_btn.pressed.connect(_on_upgrade_gold)
	if upgrade_def_btn != null:
		upgrade_def_btn.pressed.connect(_on_upgrade_defense)
	if send_slider != null:
		send_slider.min_value = 0.1
		send_slider.max_value = 1.0
		send_slider.step = 0.1
		send_slider.value = 0.5
		send_slider.value_changed.connect(_on_send_slider_changed)
	if resume_btn != null:
		resume_btn.pressed.connect(_on_resume)
	if main_menu_btn_pause != null:
		main_menu_btn_pause.pressed.connect(_on_main_menu)
	if main_menu_btn_go != null:
		main_menu_btn_go.pressed.connect(_on_main_menu)
	if speed_slower_btn != null:
		speed_slower_btn.pressed.connect(_on_speed_slower)
	if speed_faster_btn != null:
		speed_faster_btn.pressed.connect(_on_speed_faster)
	if pause_btn != null:
		pause_btn.button_down.connect(_toggle_pause)

	FactionState.gold_changed.connect(_on_gold_changed)
	
	# Create gold icon animations and set current icon
	_build_gold_icon_frames()
	_update_gold_display(FactionState.get_gold(1))
	
	_apply_speed_index()

func _build_gold_icon_frames() -> void:
	_gold_icon_frames.clear()

	if gold_icon_sheet == null:
		push_error("No gold_icon_sheet assigned.")
		return

	for i in range(GOLD_ICON_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = gold_icon_sheet
		atlas.region = Rect2(i * GOLD_ICON_SIZE.x, 0, GOLD_ICON_SIZE.x, GOLD_ICON_SIZE.y)
		_gold_icon_frames.append(atlas)
		
func _update_gold_display(amount: float) -> void:
	var gold_int := int(amount)

	if gold_label != null:
		gold_label.text = "Gold: %d" % gold_int

	if gold_icon != null and _gold_icon_frames.size() == GOLD_ICON_COUNT:
		var frame_index := _get_gold_icon_index(gold_int)
		gold_icon.texture = _gold_icon_frames[frame_index]

func _get_gold_icon_index(gold_amount: int) -> int:
	if gold_amount < 10:
		return 0
	elif gold_amount < 20:
		return 1
	elif gold_amount < 30:
		return 2
	elif gold_amount < 40:
		return 3
	elif gold_amount < 50:
		return 4
	elif gold_amount < 100:
		return 5
	elif gold_amount < 200:
		return 6
	else:
		return 7

func set_graph_map(gm: GraphMap) -> void:
	graph_map = gm

func _on_window_resized() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	_refresh_top_bar()
	if _selected_city != null and is_instance_valid(_selected_city):
		_refresh_side_panel()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	if game_over_panel != null and game_over_panel.visible:
		return
	_paused = not _paused
	if _paused:
		CycleClock.pause_clock()
	else:
		CycleClock.resume_clock()
	get_tree().paused = _paused
	if pause_panel != null:
		pause_panel.visible = _paused

func _on_resume() -> void:
	_paused = false
	CycleClock.resume_clock()
	pause_btn.set_toggled_state(_paused)
	get_tree().paused = false
	if pause_panel != null:
		pause_panel.visible = false

func _on_main_menu() -> void:
	CycleClock.resume_clock()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")

func _on_gold_changed(owner: int, new_amount: float) -> void:
	if owner == 1 and gold_label != null:
		_update_gold_display(new_amount)

func _apply_speed_index() -> void:
	var speed_value: float = SPEEDS[_speed_index]
	var speed_text: String = SPEED_LABELS[_speed_index]
	
	CycleClock.set_speed(speed_value)
	
	if speed_label != null:
		speed_label.text = speed_text
		
	print("Speed index:", _speed_index)
	print("Speed label:", speed_text)
	print("CycleClock speed set to:", speed_value)

func _on_speed_slower() -> void:
	_speed_index = max(_speed_index - 1, 0)
	_apply_speed_index()

func _on_speed_faster() -> void:
	_speed_index = min(_speed_index + 1, SPEEDS.size() - 1)
	_apply_speed_index()

func _refresh_top_bar() -> void:
	if graph_map == null:
		return
	var total_troops := 0
	for city in graph_map.get_all_cities():
		if city.data != null and city.data.owner == 1:
			total_troops += city.data.army
	
	_update_gold_display(FactionState.get_gold(1))
	
	if troops_label != null:
		troops_label.text = "Troops: %d" % total_troops

func on_city_selected(city: City) -> void:
	_selected_city = city
	if city == null:
		if side_panel != null:
			side_panel.visible = false
		return
	if side_panel != null:
		side_panel.visible = true
	_refresh_side_panel()

func refresh_selected_city() -> void:
	if _selected_city != null and is_instance_valid(_selected_city):
		_refresh_side_panel()

func _refresh_side_panel() -> void:
	if _selected_city == null or _selected_city.data == null:
		return
	var d := _selected_city.data
	var owner_name := "Neutral"
	match d.owner:
		1: owner_name = "Player"
		2: owner_name = "Enemy"

	if city_name_label != null:
		city_name_label.text = d.name
	if city_troops_label != null:
		city_troops_label.text = "Troops: %d" % d.army
	if city_owner_label != null:
		city_owner_label.text = "Owner: %s" % owner_name

	var is_player_city := d.owner == 1
	var pool: float = FactionState.get_gold(1)

	if upgrade_prod_btn != null:
		upgrade_prod_btn.visible = is_player_city
		if is_player_city:
			var cost := d.get_production_upgrade_cost()
			var maxed := d.production_level >= 3
			upgrade_prod_btn.text = "Production Lv%d  (%dg)" % [d.production_level + 1, cost] if not maxed else "Production MAX"
			upgrade_prod_btn.disabled = maxed or pool < cost

	if upgrade_gold_btn != null:
		upgrade_gold_btn.visible = is_player_city
		if is_player_city:
			var cost := d.get_gold_upgrade_cost()
			var maxed := d.gold_level >= 3
			upgrade_gold_btn.text = "Gold Lv%d  (%dg)" % [d.gold_level + 1, cost] if not maxed else "Gold MAX"
			upgrade_gold_btn.disabled = maxed or pool < cost

	if upgrade_def_btn != null:
		upgrade_def_btn.visible = is_player_city
		if is_player_city:
			var cost := d.get_defense_upgrade_cost()
			var maxed := d.defense_level >= 3
			upgrade_def_btn.text = "Defense Lv%d  (%dg)" % [d.defense_level + 1, cost] if not maxed else "Defense MAX"
			upgrade_def_btn.disabled = maxed or pool < cost

	if send_slider != null:
		send_slider.visible = is_player_city
	if send_label != null:
		send_label.visible = is_player_city
		if is_player_city and send_slider != null:
			var pct := int(send_slider.value * 100)
			var preview := int(d.army * send_slider.value)
			send_label.text = "Send: %d%% (%d troops)" % [pct, preview]

func _on_send_slider_changed(value: float) -> void:
	if graph_map != null:
		graph_map.player_send_ratio = value
	if send_label != null and _selected_city != null and _selected_city.data != null:
		var pct := int(value * 100)
		var preview := int(_selected_city.data.army * value)
		send_label.text = "Send: %d%% (%d troops)" % [pct, preview]

func _on_upgrade_production() -> void:
	if _selected_city != null:
		_selected_city.try_upgrade_production()
		_refresh_side_panel()

func _on_upgrade_gold() -> void:
	if _selected_city != null:
		_selected_city.try_upgrade_gold()
		_refresh_side_panel()

func _on_upgrade_defense() -> void:
	if _selected_city != null:
		_selected_city.try_upgrade_defense()
		_refresh_side_panel()

func show_game_over(player_won: bool) -> void:
	if game_over_panel != null:
		game_over_panel.visible = true
	if game_over_label != null:
		game_over_label.text = "Victory!" if player_won else "Defeated!"
