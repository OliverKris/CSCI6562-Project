extends Control

var graph_map: GraphMap = null
var _selected_city: City = null
var _paused: bool = false

# ====================
# Dynamic UI Variables
# ====================

# Gold Counter
@onready var gold_label: Label = $TopLeftGroup/Control/TopBar/HBoxContainer/GoldContainer/Gold
@onready var gold_icon: TextureRect = $TopLeftGroup/Control/TopBar/HBoxContainer/GoldContainer/IconPanel/GoldIcon
@export var gold_icon_sheet: Texture2D
var _gold_icon_frames: Array[AtlasTexture] = []
const GOLD_ICON_COUNT := 8
const GOLD_ICON_SIZE := Vector2i(32, 32)

# Troop Counter
@onready var troops_label: Label = $TopLeftGroup/Control/TopBar/HBoxContainer/TroopContainer/Troops

# Speed Controls
@onready var speed_label: Label = $TimerBox/MarginContainer/VBoxContainer/SpeedRow/SpeedLabel
@onready var speed_slower_btn: TextureButton = $TimerBox/MarginContainer/VBoxContainer/SpeedRow/SlowCenterContainer/SlowDown
@onready var speed_faster_btn: TextureButton = $TimerBox/MarginContainer/VBoxContainer/SpeedRow/SpeedCenterContainer/SpeedUp
var _speed_index: int = 1  # default 1x
const SPEEDS: Array = [0.5, 1.0, 2.0, 4.0]
const SPEED_LABELS: Array = ["0.5x", "1x", "2x", "4x"]

@onready var tick_number: Label = $TimerBox/MarginContainer/VBoxContainer/ClockSection/TickLabel
var current_tick = 1

# Pause Controls
@onready var pause_btn: TextureButton = $TimerBox/MarginContainer/VBoxContainer/PauseContainer/Pause


@onready var side_panel = $SidePanel

# Slider Controls

@onready var send_slider: HSlider = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/SendSlider
@onready var send_percent: Label = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/SendInfoRow/PercentLabel
@onready var send_amount: Label = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/SendInfoRow/TroopPreviewLabel

@onready var send_button_25: Control  = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/Quarter
@onready var send_button_50: Control  = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/Half
@onready var send_button_75: Control  = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/ThreeQuarters
@onready var send_button_max: Control  = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/Max

# City Identifier
@export var friendly_faction = Texture2D
@export var neutral_faction = Texture2D
@export var enemy_faction = Texture2D

@onready var city_name_label: Label = $SidePanel/VBoxContainer/HeaderSection/CityTitle/Top/CityNameLabel
@onready var faction_icon: TextureRect = $SidePanel/VBoxContainer/HeaderSection/CityTitle/Top/OwnerIcon
@onready var owner_label: Label = $SidePanel/VBoxContainer/HeaderSection/CityTitle/Bottom/OwnerLabel

@onready var friendly_primary: Color = Color("0096db")
@onready var friendly_secondary: Color = Color("124e89")
@onready var enemy_primary: Color = Color("e43b44")
@onready var enemy_secondary: Color = Color("a22633")
@onready var neutral_primary: Color = Color("5a6988")
@onready var neutral_secondary: Color = Color("262b44")

# Upgrade UI
@export var production_upgrade_icon: Texture2D
@export var gold_upgrade_icon: Texture2D
@export var defense_upgrade_icon: Texture2D

@onready var production_upgrade: Control = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade
@onready var gold_upgrade: Control = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade
@onready var defense_upgrade: Control = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade

@onready var production_upgrade_level_label: Label = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade/MarginContainer/HBoxContainer/InfoColumn/LevelRow/LevelLabel
@onready var gold_upgrade_level_label: Label = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade/MarginContainer/HBoxContainer/InfoColumn/LevelRow/LevelLabel
@onready var defense_upgrade_level_label: Label = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade/MarginContainer/HBoxContainer/InfoColumn/LevelRow/LevelLabel

@onready var production_upgrade_counters = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade/MarginContainer/HBoxContainer/InfoColumn/LevelRow/UpgradeCounters
@onready var gold_upgrade_counters = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade/MarginContainer/HBoxContainer/InfoColumn/LevelRow/UpgradeCounters
@onready var defense_upgrade_counters = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade/MarginContainer/HBoxContainer/InfoColumn/LevelRow/UpgradeCounters

@onready var production_upgrade_icon_node: TextureRect = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade/MarginContainer/HBoxContainer/IconCenter/IconFrame/UpgradeIcon
@onready var gold_upgrade_icon_node: TextureRect = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade/MarginContainer/HBoxContainer/IconCenter/IconFrame/UpgradeIcon
@onready var defense_upgrade_icon_node: TextureRect = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade/MarginContainer/HBoxContainer/IconCenter/IconFrame/UpgradeIcon

@onready var production_upgrade_name: Label = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade/MarginContainer/HBoxContainer/InfoColumn/UpgradeName
@onready var production_upgrade_button: BaseButton = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade/MarginContainer/HBoxContainer/RightColumnCenter/RightColumn/ButtonCenter/UpgradeButton
@onready var production_upgrade_cost: Label = $SidePanel/VBoxContainer/UpgradeSection/ProductionUpgrade/MarginContainer/HBoxContainer/RightColumnCenter/RightColumn/CostCenter/MarginContainer/CostRow/CostLabel

@onready var gold_upgrade_name: Label = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade/MarginContainer/HBoxContainer/InfoColumn/UpgradeName
@onready var gold_upgrade_button: BaseButton = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade/MarginContainer/HBoxContainer/RightColumnCenter/RightColumn/ButtonCenter/UpgradeButton
@onready var gold_upgrade_cost: Label = $SidePanel/VBoxContainer/UpgradeSection/GoldUpgrade/MarginContainer/HBoxContainer/RightColumnCenter/RightColumn/CostCenter/MarginContainer/CostRow/CostLabel

@onready var defense_upgrade_name: Label = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade/MarginContainer/HBoxContainer/InfoColumn/UpgradeName
@onready var defense_upgrade_button: BaseButton = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade/MarginContainer/HBoxContainer/RightColumnCenter/RightColumn/ButtonCenter/UpgradeButton
@onready var defense_upgrade_cost: Label = $SidePanel/VBoxContainer/UpgradeSection/DefenseUpgrade/MarginContainer/HBoxContainer/RightColumnCenter/RightColumn/CostCenter/MarginContainer/CostRow/CostLabel

# Production cards
@export var current_troops_icon: Texture2D
@export var troop_production_icon: Texture2D
@export var gold_production_icon: Texture2D
@export var defense_icon: Texture2D

@onready var current_troops_icon_node: TextureRect = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/CurrentTroops/MarginContainer/HBoxContainer/Icon
@onready var troop_production_icon_node: TextureRect = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/TroopProduction/MarginContainer/HBoxContainer/Icon
@onready var gold_production_icon_node: TextureRect = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/GoldProduction/MarginContainer/HBoxContainer/Icon
@onready var defense_icon_node: TextureRect = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/Defense/MarginContainer/HBoxContainer/Icon

@onready var current_troops_card: Control = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/CurrentTroops
@onready var troop_production_card: Control = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/TroopProduction
@onready var gold_production_card: Control = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/GoldProduction
@onready var defense_card: Control = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/Defense

@onready var current_troops_value: Label = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/CurrentTroops/MarginContainer/HBoxContainer/StatValue
@onready var troop_production_value: Label = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/TroopProduction/MarginContainer/HBoxContainer/StatValue
@onready var gold_production_value: Label = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/GoldProduction/MarginContainer/HBoxContainer/StatValue
@onready var defense_value: Label = $SidePanel/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/GridContainer/Defense/MarginContainer/HBoxContainer/StatValue


@onready var game_over_panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/VBoxContainer/Label
@onready var main_menu_btn_go: TextureButton = $GameOverPanel/VBoxContainer/MainMenuButton

@onready var pause_panel = $PausePanel
@onready var resume_btn: TextureButton = $PausePanel/VBoxContainer/ResumeButton
@onready var main_menu_btn_pause: TextureButton = $PausePanel/VBoxContainer/MainMenuButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.size_changed.connect(_on_window_resized)

	if side_panel != null:
		side_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if pause_panel != null:
		pause_panel.visible = false

	if production_upgrade_button != null:
		production_upgrade_button.pressed.connect(_on_upgrade_production)
	if gold_upgrade_button != null:
		gold_upgrade_button.pressed.connect(_on_upgrade_gold)
	if defense_upgrade_button != null:
		defense_upgrade_button.pressed.connect(_on_upgrade_defense)
	
	if send_slider != null:
		send_slider.min_value = 0.1
		send_slider.max_value = 1.0
		send_slider.step = 0.05
		send_slider.value = 0.5
		send_slider.value_changed.connect(_on_send_slider_changed)
	if send_button_25 != null:
		send_button_25.pressed.connect(_on_send_25_pressed)
	if send_button_50 != null:
		send_button_50.pressed.connect(_on_send_50_pressed)
	if send_button_75 != null:
		send_button_75.pressed.connect(_on_send_75_pressed)
	if send_button_max != null:
		send_button_max.pressed.connect(_on_send_max_pressed)	
	
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

	CycleClock.cycle_ticked.connect(_increment_tick)

	if FactionState != null:
		FactionState.gold_changed.connect(_on_gold_changed)
	
	# Create gold icon animations and set current icon
	_build_gold_icon_frames()
	_refresh_top_bar()
	
	_apply_speed_index()

func _increment_tick() -> void:
	current_tick += 1
	tick_number.text = "Tick %d" % current_tick

func _on_send_25_pressed() -> void:
	if send_slider != null:
		send_slider.value = 0.25

func _on_send_50_pressed() -> void:
	if send_slider != null:
		send_slider.value = 0.5

func _on_send_75_pressed() -> void:
	if send_slider != null:
		send_slider.value = 0.75

func _on_send_max_pressed() -> void:
	if send_slider != null:
		send_slider.value = 1.0

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

func _set_upgrade_entry(
	entry_root: Control,
	name_label: Label,
	level_label: Label,
	counters_node: UpgradeCounters,
	icon_node: TextureRect,
	cost_label: Label,
	button: BaseButton,
	visible: bool,
	upgrade_name: String,
	current_level: int,
	max_level: int,
	upgrade_icon: Texture2D,
	cost: int,
	maxed: bool,
	can_afford: bool
) -> void:
	if entry_root != null:
		entry_root.visible = visible

	if not visible:
		return

	if name_label != null:
		name_label.text = upgrade_name

	if level_label != null:
		level_label.text = "Lv. %d/%d" % [current_level, max_level]

	if counters_node != null:
		counters_node.current_level = current_level

	if icon_node != null:
		icon_node.texture = upgrade_icon

	if cost_label != null:
		cost_label.text = "MAX" if maxed else str(cost)

		if maxed:
			cost_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
		elif can_afford:
			cost_label.modulate = Color(1, 1, 1, 1)
		else:
			cost_label.modulate = Color(1, 0.35, 0.35, 1.0)

	if button != null:
		var locked := maxed or not can_afford
		button.disabled = locked
		button.modulate = Color(0.5, 0.5, 0.5, 1.0) if locked else Color(1, 1, 1, 1)

func _set_production_card(
	card_root: Control,
	icon_node: TextureRect,
	value_label: Label,
	visible: bool,
	icon_texture: Texture2D,
	value_text: String
) -> void:
	if card_root != null:
		card_root.visible = visible

	if not visible:
		return

	if icon_node != null:
		icon_node.texture = icon_texture

	if value_label != null:
		value_label.text = value_text

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
	var troop_rate := 0
	for city in graph_map.get_all_cities():
		if city.data != null and city.data.owner == 1:
			total_troops += city.data.army
			troop_rate += city.data.production_per_cycle
		
	_update_gold_display(FactionState.get_gold(1) if FactionState != null else 0.0)

	if troops_label != null:
		troops_label.text = "Troops: %d (+%d)" % [total_troops, troop_rate]

func _get_player_production_totals() -> Dictionary:
	var gold_rate := 0
	var troop_rate := 0

	if graph_map == null:
		return { "gold": 0, "troops": 0 }

	for city in graph_map.get_all_cities():
		var d: CityData = city.data
		if d.owner == 1:
			gold_rate += d.gold_per_cycle
			troop_rate += d.production_per_cycle

	return {
		"gold": gold_rate,
		"troops": troop_rate
	}

func _update_gold_display(amount: float) -> void:
	var gold_int := int(amount)
	var rates := _get_player_production_totals()
	var gold_rate : int = rates['gold']

	if gold_label != null:
		gold_label.text = "Gold: %d (+%d)" % [gold_int, gold_rate]

	if gold_icon != null and _gold_icon_frames.size() == GOLD_ICON_COUNT:
		var frame_index := _get_gold_icon_index(gold_int)
		gold_icon.texture = _gold_icon_frames[frame_index]


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
		
	if faction_icon != null:
		match owner_name:
			"Player": faction_icon.texture = friendly_faction
			"Enemy": faction_icon.texture = enemy_faction
			"Neutral": faction_icon.texture = neutral_faction

	if city_name_label != null:
		city_name_label.text = d.name
		
	if owner_label != null:
		match owner_name:
			"Player": 
				owner_label.text = "Blue (You)"
				owner_label.add_theme_color_override("font_color", friendly_primary)
				owner_label.add_theme_color_override("font_outline_color", friendly_secondary)
			"Enemy": 
				owner_label.text = "Red (Enemy)"
				owner_label.add_theme_color_override("font_color", enemy_primary)
				owner_label.add_theme_color_override("font_outline_color", enemy_secondary)
			"Neutral":
				owner_label.text = "Grey (Neutral)"
				owner_label.add_theme_color_override("font_color", neutral_primary)
				owner_label.add_theme_color_override("font_outline_color", neutral_secondary)

	var is_player_city := d.owner == 1
	var pool: float = FactionState.get_gold(1)

	# Production Cards
	_set_production_card(
		current_troops_card,
		current_troops_icon_node,
		current_troops_value,
		true,
		current_troops_icon,
		str(d.army)
	)

	_set_production_card(
		troop_production_card,
		troop_production_icon_node,
		troop_production_value,
		true,
		troop_production_icon,
		"+%d/tick" % d.production_per_cycle
	)

	_set_production_card(
		gold_production_card,
		gold_production_icon_node,
		gold_production_value,
		true,
		gold_production_icon,
		"+%d/tick" % d.gold_per_cycle
	)

	_set_production_card(
		defense_card,
		defense_icon_node,
		defense_value,
		true,
		defense_icon,
		"x%.1f" % d.get_defense_multiplier()
	)
	
	# Production Upgrade
	var prod_cost := d.get_production_upgrade_cost()
	var prod_maxed := d.production_level >= 3
	_set_upgrade_entry(
		production_upgrade,
		production_upgrade_name,
		production_upgrade_level_label,
		production_upgrade_counters,
		production_upgrade_icon_node,
		production_upgrade_cost,
		production_upgrade_button,
		is_player_city,
		"Production",
		d.production_level,
		3,
		production_upgrade_icon,
		prod_cost,
		prod_maxed,
		pool >= prod_cost
	)

	# Gold upgrade
	var gold_cost := d.get_gold_upgrade_cost()
	var gold_maxed := d.gold_level >= 3
	_set_upgrade_entry(
		gold_upgrade,
		gold_upgrade_name,
		gold_upgrade_level_label,
		gold_upgrade_counters,
		gold_upgrade_icon_node,
		gold_upgrade_cost,
		gold_upgrade_button,
		is_player_city,
		"Gold",
		d.gold_level,
		3,
		gold_upgrade_icon,
		gold_cost,
		gold_maxed,
		pool >= gold_cost
	)

	# Defense upgrade
	var def_cost := d.get_defense_upgrade_cost()
	var def_maxed := d.defense_level >= 3
	_set_upgrade_entry(
		defense_upgrade,
		defense_upgrade_name,
		defense_upgrade_level_label,
		defense_upgrade_counters,
		defense_upgrade_icon_node,
		defense_upgrade_cost,
		defense_upgrade_button,
		is_player_city,
		"Defense",
		d.defense_level,
		3,
		defense_upgrade_icon,
		def_cost,
		def_maxed,
		pool >= def_cost
	)
	
	if send_slider != null:
		send_slider.visible = is_player_city
	if send_percent != null:
		send_percent.visible = is_player_city
	if send_amount != null:
		send_amount.visible = is_player_city
		if is_player_city and send_slider != null:
			_on_send_slider_changed(send_slider.value)

func _on_send_slider_changed(value: float) -> void:
	if graph_map != null:
		graph_map.player_send_ratio = value
	if send_percent != null and send_amount != null and _selected_city != null and _selected_city.data != null:
		var pct := int(value * 100)
		var preview := int(_selected_city.data.army * value)
		send_percent.text = "%d%%" % pct
		send_amount.text = "(%d troops)" % preview

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
