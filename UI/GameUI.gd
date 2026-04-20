extends Control

# =========================================================
# Game UI
# Event-driven rewrite:
# - No per-frame UI refresh
# - Refreshes only when game state changes
# - Cleaner organization and comments
# =========================================================

# ---------------------------------------------------------
# References / State
# ---------------------------------------------------------

var graph_map: GraphMap = null
var _selected_city: City = null
var _paused: bool = false

var _side_panel_visible: bool = false
var _side_panel_tween: Tween = null

var _speed_index: int = 1 # default 1x
var current_tick: int = 1

# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------

const SPEEDS: Array = [0.5, 1.0, 2.0, 4.0]
const SPEED_LABELS: Array = ["0.5x", "1x", "2x", "4x"]

const GOLD_ICON_COUNT := 8
const GOLD_ICON_SIZE := Vector2i(32, 32)

# ---------------------------------------------------------
# Top Bar
# ---------------------------------------------------------

@onready var gold_label: Label = $TopLeftGroup/Control/TopBar/HBoxContainer/GoldContainer/Gold
@onready var gold_icon: TextureRect = $TopLeftGroup/Control/TopBar/HBoxContainer/GoldContainer/IconPanel/GoldIcon
@onready var troops_label: Label = $TopLeftGroup/Control/TopBar/HBoxContainer/TroopContainer/Troops

@export var gold_icon_sheet: Texture2D
var _gold_icon_frames: Array[AtlasTexture] = []

# ---------------------------------------------------------
# Timer / Pause
# ---------------------------------------------------------

@onready var speed_label: Label = $TimerBox/MarginContainer/VBoxContainer/SpeedRow/SpeedLabel
@onready var speed_slower_btn: TextureButton = $TimerBox/MarginContainer/VBoxContainer/SpeedRow/SlowCenterContainer/SlowDown
@onready var speed_faster_btn: TextureButton = $TimerBox/MarginContainer/VBoxContainer/SpeedRow/SpeedCenterContainer/SpeedUp
@onready var tick_number: Label = $TimerBox/MarginContainer/VBoxContainer/ClockSection/TickLabel
@onready var pause_btn: TextureButton = $TimerBox/MarginContainer/VBoxContainer/PauseContainer/Pause

# ---------------------------------------------------------
# Side Panel
# ---------------------------------------------------------

@onready var side_panel: Control = $SidePanel
@onready var side_panel_content: Control = $SidePanel/VBoxContainer

@export var side_panel_slide_duration: float = 0.28
@export var side_panel_hidden_margin: float = 24.0

# Slider Controls
@onready var send_slider: HSlider = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/SendSlider
@onready var send_percent: Label = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/SendInfoRow/PercentLabel
@onready var send_amount: Label = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/SendInfoRow/TroopPreviewLabel

@onready var send_button_25: BaseButton = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/Quarter
@onready var send_button_50: BaseButton = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/Half
@onready var send_button_75: BaseButton = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/ThreeQuarters
@onready var send_button_max: BaseButton = $SidePanel/VBoxContainer/SendSection/MarginContainer/VBoxContainer/PresetRow/Max

# City Header
@export var friendly_faction: Texture2D
@export var neutral_faction: Texture2D
@export var enemy_faction: Texture2D

@onready var city_name_label: Label = $SidePanel/VBoxContainer/HeaderSection/CityTitle/Top/CityNameLabel
@onready var faction_icon: TextureRect = $SidePanel/VBoxContainer/HeaderSection/CityTitle/Top/OwnerIcon
@onready var owner_label: Label = $SidePanel/VBoxContainer/HeaderSection/CityTitle/Bottom/OwnerLabel

@export var friendly_primary: Color = Color("0096db")
@export var friendly_secondary: Color = Color("124e89")
@export var enemy_primary: Color = Color("e43b44")
@export var enemy_secondary: Color = Color("a22633")
@export var neutral_primary: Color = Color("5a6988")
@export var neutral_secondary: Color = Color("262b44")

# Upgrades
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

# Production Cards
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

# ---------------------------------------------------------
# Overlays / Menus
# ---------------------------------------------------------

@onready var game_over_panel: Control = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/VBoxContainer/Label
@onready var main_menu_btn_go: TextureButton = $GameOverPanel/VBoxContainer/MainMenuButton

@onready var pause_panel: Control = $PausePanel
@onready var resume_btn: TextureButton = $PausePanel/VBoxContainer/ResumeButton
@onready var main_menu_btn_pause: TextureButton = $PausePanel/VBoxContainer/MainMenuButton

# =========================================================
# READY / SETUP
# =========================================================

func _ready() -> void:
	z_index = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	get_tree().root.size_changed.connect(_on_window_resized)

	_setup_panels()
	_setup_gold_icons()
	_setup_slider()
	_connect_buttons()
	_connect_global_signals()

	_apply_speed_index()
	_refresh_all_ui()

# ---------------------------------------------------------
# Setup Helpers
# ---------------------------------------------------------

func _setup_panels() -> void:
	if side_panel != null:
		_setup_side_panel_position()

	if side_panel_content != null:
		side_panel_content.modulate.a = 1.0

	if game_over_panel != null:
		game_over_panel.visible = false

	if pause_panel != null:
		pause_panel.visible = false

func _setup_gold_icons() -> void:
	_gold_icon_frames.clear()

	if gold_icon_sheet == null:
		push_error("No gold_icon_sheet assigned.")
		return

	for i in range(GOLD_ICON_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = gold_icon_sheet
		atlas.region = Rect2(i * GOLD_ICON_SIZE.x, 0, GOLD_ICON_SIZE.x, GOLD_ICON_SIZE.y)
		_gold_icon_frames.append(atlas)

func _setup_slider() -> void:
	if send_slider == null:
		return

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

func _connect_buttons() -> void:
	if production_upgrade_button != null:
		production_upgrade_button.pressed.connect(_on_upgrade_production)
	if gold_upgrade_button != null:
		gold_upgrade_button.pressed.connect(_on_upgrade_gold)
	if defense_upgrade_button != null:
		defense_upgrade_button.pressed.connect(_on_upgrade_defense)

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

func _connect_global_signals() -> void:
	CycleClock.cycle_ticked.connect(_on_cycle_ticked)

	if FactionState != null:
		FactionState.gold_changed.connect(_on_gold_changed)

# =========================================================
# PUBLIC API
# =========================================================

func set_graph_map(gm: GraphMap) -> void:
	graph_map = gm
	_refresh_top_bar()
	_refresh_selected_city_ui()

func on_city_selected(city: City) -> void:
	var previous_city := _selected_city
	_selected_city = city

	if city == null:
		_hide_side_panel()
		return

	if previous_city == null or not _side_panel_visible:
		_refresh_selected_city_ui()
		_show_side_panel()
		return

	_refresh_selected_city_ui()

func refresh_selected_city() -> void:
	_refresh_selected_city_ui()

func refresh_all() -> void:
	_refresh_all_ui()

# =========================================================
# EVENT HANDLERS
# =========================================================

func _on_cycle_ticked() -> void:
	current_tick += 1

	if tick_number != null:
		tick_number.text = "Tick %d" % current_tick

	_refresh_top_bar()
	_refresh_selected_city_ui()

func _on_gold_changed(owner: int, new_amount: float) -> void:
	if owner != 1:
		return

	_update_gold_display_and_rate(new_amount)
	_refresh_selected_city_ui()

func _on_window_resized() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if side_panel == null:
		return

	if _side_panel_visible:
		side_panel.position.x = _get_side_panel_shown_x()
	else:
		side_panel.position.x = _get_side_panel_hidden_x()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

# =========================================================
# FULL REFRESH
# =========================================================

func _refresh_all_ui() -> void:
	_refresh_tick_label()
	_refresh_top_bar()
	_refresh_selected_city_ui()

func _refresh_tick_label() -> void:
	if tick_number != null:
		tick_number.text = "Tick %d" % current_tick

# =========================================================
# TOP BAR
# =========================================================

func _refresh_top_bar() -> void:
	if graph_map == null:
		return

	var totals := _calculate_player_totals()
	var gold_amount := FactionState.get_gold(1) if FactionState != null else 0.0

	if troops_label != null:
		troops_label.text = "Troops: %d (+%d)" % [totals.troops, totals.troop_rate]

	_update_gold_display(gold_amount, totals.gold_rate)

func _calculate_player_totals() -> Dictionary:
	var result := {
		"troops": 0,
		"troop_rate": 0,
		"gold_rate": 0
	}

	if graph_map == null:
		return result

	for city in graph_map.get_all_cities():
		if city == null or city.data == null:
			continue
		if city.data.owner != 1:
			continue

		result.troops += city.data.army
		result.troop_rate += city.data.production_per_cycle
		result.gold_rate += city.data.gold_per_cycle

	return result

func _update_gold_display_and_rate(amount: float) -> void:
	var totals := _calculate_player_totals()
	_update_gold_display(amount, totals.gold_rate)

func _update_gold_display(amount: float, gold_rate: int) -> void:
	var gold_int := int(amount)

	if gold_label != null:
		gold_label.text = "Gold: %d (+%d)" % [gold_int, gold_rate]

	if gold_icon != null and _gold_icon_frames.size() == GOLD_ICON_COUNT:
		gold_icon.texture = _gold_icon_frames[_get_gold_icon_index(gold_int)]

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
	return 7

# =========================================================
# SIDE PANEL
# =========================================================

func _refresh_selected_city_ui() -> void:
	if _selected_city == null or not is_instance_valid(_selected_city):
		return
	if _selected_city.data == null:
		return

	var d: CityData = _selected_city.data
	var is_player_city := d.owner == 1
	var pool: float = FactionState.get_gold(1) if FactionState != null else 0.0

	_refresh_city_header(d)
	_refresh_production_cards(d)
	_refresh_upgrade_entries(d, is_player_city, pool)
	_refresh_send_ui(d, is_player_city)

func _refresh_city_header(d: CityData) -> void:
	if city_name_label != null:
		city_name_label.text = d.name

	if faction_icon != null:
		match d.owner:
			1:
				faction_icon.texture = friendly_faction
			2:
				faction_icon.texture = enemy_faction
			_:
				faction_icon.texture = neutral_faction

	if owner_label != null:
		match d.owner:
			1:
				owner_label.text = "Blue (You)"
				owner_label.add_theme_color_override("font_color", friendly_primary)
				owner_label.add_theme_color_override("font_outline_color", friendly_secondary)
			2:
				owner_label.text = "Red (Enemy)"
				owner_label.add_theme_color_override("font_color", enemy_primary)
				owner_label.add_theme_color_override("font_outline_color", enemy_secondary)
			_:
				owner_label.text = "Grey (Neutral)"
				owner_label.add_theme_color_override("font_color", neutral_primary)
				owner_label.add_theme_color_override("font_outline_color", neutral_secondary)

func _refresh_production_cards(d: CityData) -> void:
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

func _refresh_upgrade_entries(d: CityData, is_player_city: bool, pool: float) -> void:
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

func _refresh_send_ui(d: CityData, is_player_city: bool) -> void:
	if send_slider != null:
		send_slider.visible = is_player_city
	if send_percent != null:
		send_percent.visible = is_player_city
	if send_amount != null:
		send_amount.visible = is_player_city

	if is_player_city and send_slider != null:
		_update_send_preview(send_slider.value, d.army)

func _update_send_preview(value: float, army_count: int) -> void:
	if graph_map != null:
		graph_map.player_send_ratio = value

	if send_percent != null:
		send_percent.text = "%d%%" % int(value * 100)

	if send_amount != null:
		send_amount.text = "(%d troops)" % int(army_count * value)

# ---------------------------------------------------------
# Shared UI Entry Helpers
# ---------------------------------------------------------

func _set_upgrade_entry(
	entry_root: Control,
	name_label: Label,
	level_label: Label,
	counters_node,
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

# =========================================================
# SIDE PANEL ANIMATION
# =========================================================

func _setup_side_panel_position() -> void:
	if side_panel == null:
		return

	side_panel.visible = false
	side_panel.position.x = _get_side_panel_hidden_x()
	_side_panel_visible = false

func _show_side_panel() -> void:
	if side_panel == null:
		return

	_kill_side_panel_tween()

	side_panel.visible = true
	side_panel.position.x = _get_side_panel_hidden_x()

	_side_panel_tween = create_tween()
	_side_panel_tween.set_trans(Tween.TRANS_CUBIC)
	_side_panel_tween.set_ease(Tween.EASE_OUT)
	_side_panel_tween.tween_property(side_panel, "position:x", _get_side_panel_shown_x(), side_panel_slide_duration)

	_side_panel_visible = true

func _hide_side_panel() -> void:
	if side_panel == null:
		return

	_kill_side_panel_tween()

	_side_panel_tween = create_tween()
	_side_panel_tween.set_trans(Tween.TRANS_CUBIC)
	_side_panel_tween.set_ease(Tween.EASE_IN)
	_side_panel_tween.tween_property(side_panel, "position:x", _get_side_panel_hidden_x(), side_panel_slide_duration)
	_side_panel_tween.tween_callback(func():
		side_panel.visible = false
	)

	_side_panel_visible = false

func _get_side_panel_shown_x() -> float:
	return get_viewport_rect().size.x - side_panel.size.x

func _get_side_panel_hidden_x() -> float:
	return get_viewport_rect().size.x

func _kill_side_panel_tween() -> void:
	if _side_panel_tween != null and is_instance_valid(_side_panel_tween):
		_side_panel_tween.kill()
	_side_panel_tween = null

# =========================================================
# SEND CONTROLS
# =========================================================

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

func _on_send_slider_changed(value: float) -> void:
	if _selected_city == null or _selected_city.data == null:
		if graph_map != null:
			graph_map.player_send_ratio = value
		return

	_update_send_preview(value, _selected_city.data.army)

# =========================================================
# UPGRADES
# =========================================================

func _on_upgrade_production() -> void:
	if _selected_city != null:
		_selected_city.try_upgrade_production()
		_refresh_top_bar()
		_refresh_selected_city_ui()

func _on_upgrade_gold() -> void:
	if _selected_city != null:
		_selected_city.try_upgrade_gold()
		_refresh_top_bar()
		_refresh_selected_city_ui()

func _on_upgrade_defense() -> void:
	if _selected_city != null:
		_selected_city.try_upgrade_defense()
		_refresh_selected_city_ui()

# =========================================================
# SPEED / PAUSE
# =========================================================

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
	get_tree().paused = false

	if pause_btn != null and pause_btn.has_method("set_toggled_state"):
		pause_btn.set_toggled_state(false)

	if pause_panel != null:
		pause_panel.visible = false

# =========================================================
# SCENE NAVIGATION / GAME OVER
# =========================================================

func _on_main_menu() -> void:
	CycleClock.resume_clock()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")

func show_game_over(player_won: bool) -> void:
	if game_over_panel != null:
		game_over_panel.visible = true
	if game_over_label != null:
		game_over_label.text = "Victory!" if player_won else "Defeated!"
