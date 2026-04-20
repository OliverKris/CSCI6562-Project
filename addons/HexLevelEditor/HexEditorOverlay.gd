@tool
extends RefCounted
class_name HexEditorOverlay

var plugin: EditorPlugin = null
var _graph_map: GraphMap = null
var _panel: PanelContainer = null

# Panel UI refs
var _status_label: Label = null
var _owner_option: OptionButton = null
var _army_spin: SpinBox = null
var _defense_spin: SpinBox = null
var _name_edit: LineEdit = null
var _mode_option: OptionButton = null

var _hovered_hex: Vector2i = Vector2i(9999, 9999)
var _road_first_id: int = -1

# Cached overlay control — set each draw call so input can reuse same transform
var _last_overlay: Control = null

const HEX_SIZE: float = 64.0

const COLORS := {
	"hover":         Color(0.9, 0.8, 0.3, 0.35),
	"grid":          Color(0.5, 0.5, 0.6, 0.25),
	"city_player":   Color(0.2, 0.6, 1.0, 0.85),
	"city_enemy":    Color(1.0, 0.3, 0.3, 0.85),
	"city_neutral":  Color(0.6, 0.6, 0.6, 0.85),
	"city_selected": Color(0.9, 0.8, 0.2, 1.0),
	"road":          Color(0.8, 0.75, 0.5, 0.9),
	"road_pending":  Color(0.9, 0.8, 0.2, 0.9),
}

# ── Public API ────────────────────────────────────────────────────────────────

func get_panel() -> Control:
	if _panel == null:
		_build_panel()
	return _panel

func set_graph_map(gm: GraphMap) -> void:
	_graph_map = gm
	_road_first_id = -1
	_update_status("Editing: %s" % gm.name if gm else "No GraphMap selected")
	_request_redraw()

# ── Transform helpers ─────────────────────────────────────────────────────────
# In Godot 4 EditorPlugin:
#   _forward_canvas_gui_input  → event.position is in VIEWPORT pixels
#   _forward_canvas_draw_over_viewport(overlay) → draws in overlay's local coords
#
# The overlay Control is a direct child of the editor's SubViewport for the 2D view.
# overlay.get_canvas_transform() gives the correct viewport→screen pixel transform
# that already accounts for editor camera zoom & pan.
#
# Full chain:
#   node_local → [global_transform] → world → [overlay.get_canvas_transform()] → overlay pixels
#
# We cache the overlay each draw call and use it for input too.

func _get_transform() -> Transform2D:
	if _last_overlay == null:
		return Transform2D.IDENTITY
	return _last_overlay.get_transform()

func _local_to_screen(local_pos: Vector2) -> Vector2:
	return _get_transform() * local_pos

func _screen_to_local(screen_pos: Vector2) -> Vector2:
	return _get_transform().affine_inverse() * screen_pos

# ── Hex math (pure axial, flat-top) — must match GraphMap exactly ─────────────

func _hex_to_local(hex: Vector2i) -> Vector2:
	var x: float = HEX_SIZE * 1.5 * float(hex.x)
	var y: float = HEX_SIZE * (sqrt(3.0) / 2.0 * float(hex.x) + sqrt(3.0) * float(hex.y))
	var offset: Vector2 = _get_view_center_offset()
	return Vector2(x + offset.x, y + offset.y)

func _local_to_hex(local_pos: Vector2) -> Vector2i:
	var offset: Vector2 = _get_view_center_offset()
	var px: float = local_pos.x - offset.x
	var py: float = local_pos.y - offset.y
	var q: float = (2.0 / 3.0) * px / HEX_SIZE
	var r: float = (-1.0 / 3.0 * px + sqrt(3.0) / 3.0 * py) / HEX_SIZE
	return _hex_round(q, r)

func _get_view_center_offset() -> Vector2:
	if _last_overlay == null:
		return Vector2.ZERO
	return _last_overlay.size / 2.0

func _hex_round(q: float, r: float) -> Vector2i:
	var s: float = -q - r
	var rq: int = roundi(q)
	var rr: int = roundi(r)
	var rs: int = roundi(s)
	var q_diff: float = abs(float(rq) - q)
	var r_diff: float = abs(float(rr) - r)
	var s_diff: float = abs(float(rs) - s)
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	return Vector2i(rq, rr)

func _request_redraw() -> void:
	if plugin != null:
		plugin.update_overlays()

# ── Input ─────────────────────────────────────────────────────────────────────

func handle_input(event: InputEvent) -> bool:
	if _graph_map == null or _graph_map.level_data == null:
		return false

	if event is InputEventMouseMotion:
		var local_pos := _screen_to_local(event.position)
		_hovered_hex = _local_to_hex(local_pos)
		_request_redraw()
		return false

	if event is InputEventMouseButton and event.pressed:
		var local_pos := _screen_to_local(event.position)
		var hex := _local_to_hex(local_pos)
		var mode: int = _mode_option.selected if _mode_option != null else 0

		if mode == 0:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_place_city(hex)
				return true
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_remove_city_at(hex)
				return true
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_handle_road_click(hex)
				return true
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_road_first_id = -1
				_update_status("Road selection cancelled.")
				_request_redraw()
				return true

	return false

# ── Draw overlay ──────────────────────────────────────────────────────────────

func draw_over_viewport(overlay: Control) -> void:
	if _graph_map == null or _graph_map.level_data == null:
		return

	# Cache overlay so _get_transform() works correctly for input events too
	_last_overlay = overlay

	# Zoom scale from the overlay's canvas transform (editor camera zoom only)
	var zoom: float = overlay.get_canvas_transform().get_scale().x

	# Compute hex grid bounds from placed cities + margin
	var min_q := -2; var max_q := 2
	var min_r := -2; var max_r := 2
	if not _graph_map.level_data.cities.is_empty():
		min_q = 9999; max_q = -9999; min_r = 9999; max_r = -9999
		for cd in _graph_map.level_data.cities:
			min_q = mini(min_q, cd.hex_coord.x); max_q = maxi(max_q, cd.hex_coord.x)
			min_r = mini(min_r, cd.hex_coord.y); max_r = maxi(max_r, cd.hex_coord.y)
		min_q -= 2; max_q += 2; min_r -= 2; max_r += 2

	# Draw hex grid
	for gq in range(min_q, max_q + 1):
		for gr in range(min_r, max_r + 1):
			var center_screen := _local_to_screen(_hex_to_local(Vector2i(gq, gr)))
			_draw_hex_outline_screen(overlay, center_screen, HEX_SIZE * zoom - 1.0, COLORS["grid"])

	# Hover fill
	var hover_screen := _local_to_screen(_hex_to_local(_hovered_hex))
	_draw_hex_fill_screen(overlay, hover_screen, HEX_SIZE * zoom - 1.0, COLORS["hover"])

	# Roads
	for road: RoadData in _graph_map.level_data.roads:
		if road == null:
			continue
		var sa := _find_city_spawn(road.a_id)
		var sb := _find_city_spawn(road.b_id)
		if sa == null or sb == null:
			continue
		var a_screen := _local_to_screen(_hex_to_local(Vector2i(sa.hex_coord)))
		var b_screen := _local_to_screen(_hex_to_local(Vector2i(sb.hex_coord)))
		var highlight := _road_first_id != -1 and (road.a_id == _road_first_id or road.b_id == _road_first_id)
		overlay.draw_line(a_screen, b_screen,
			COLORS["road_pending"] if highlight else COLORS["road"], 3.0, true)

	# Cities
	for city_def: CitySpawnData in _graph_map.level_data.cities:
		if city_def == null:
			continue
		var sp := _local_to_screen(_hex_to_local(Vector2i(city_def.hex_coord)))
		var r: float = HEX_SIZE * zoom * 0.30

		var col: Color
		if city_def.id == _road_first_id:
			col = COLORS["city_selected"]
		else:
			match city_def.owner:
				1: col = COLORS["city_player"]
				2: col = COLORS["city_enemy"]
				_: col = COLORS["city_neutral"]

		overlay.draw_circle(sp, r, col)
		overlay.draw_arc(sp, r, 0, TAU, 32, Color(0.05, 0.05, 0.08), 2.0)

		var font := ThemeDB.fallback_font
		overlay.draw_string(font, sp + Vector2(-r, -r - 4),
			city_def.city_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1))
		overlay.draw_string(font, sp + Vector2(-5, 5),
			str(city_def.army), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1))

		# Show defense level badge if > 0
		if city_def.get("defense_level") != null and city_def.defense_level > 0:
			overlay.draw_string(font, sp + Vector2(-5, -5),
				"D%d" % city_def.defense_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 1.0, 0.4, 1.0))

# ── Draw primitives (screen-space) ────────────────────────────────────────────

func _hex_points_screen(center: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _draw_hex_outline_screen(overlay: Control, center: Vector2, radius: float, col: Color) -> void:
	var pts := _hex_points_screen(center, radius)
	for i in range(6):
		overlay.draw_line(pts[i], pts[(i + 1) % 6], col, 1.0)

func _draw_hex_fill_screen(overlay: Control, center: Vector2, radius: float, col: Color) -> void:
	overlay.draw_colored_polygon(_hex_points_screen(center, radius), col)

# ── City operations ───────────────────────────────────────────────────────────

func _place_city(hex: Vector2i) -> void:
	if _graph_map == null or _graph_map.level_data == null:
		return
	for city_def in _graph_map.level_data.cities:
		if Vector2i(city_def.hex_coord) == hex:
			_update_status("'%s' already here. Right-click to remove." % city_def.city_name)
			return
	var spawn := CitySpawnData.new()
	spawn.id = _next_id()
	spawn.hex_coord = Vector2(hex)
	spawn.city_name = _name_edit.text if _name_edit != null and _name_edit.text != "" else ("City %d" % spawn.id)
	spawn.owner = _owner_option.selected if _owner_option != null else 0
	spawn.army = int(_army_spin.value) if _army_spin != null else 10
	spawn.defense_level = int(_defense_spin.value) if _defense_spin != null else 0
	var cities := _graph_map.level_data.cities.duplicate()
	cities.append(spawn)
	_graph_map.level_data.cities = cities
	_mark_dirty()
	_update_status("Placed '%s' at (%d,%d)" % [spawn.city_name, hex.x, hex.y])
	_request_redraw()

func _remove_city_at(hex: Vector2i) -> void:
	if _graph_map == null or _graph_map.level_data == null:
		return
	var ld := _graph_map.level_data
	for i in range(ld.cities.size()):
		if Vector2i(ld.cities[i].hex_coord) == hex:
			var removed_id: int = ld.cities[i].id
			var cities := ld.cities.duplicate()
			cities.remove_at(i)
			ld.cities = cities
			var roads := ld.roads.duplicate()
			ld.roads = roads.filter(func(r: RoadData) -> bool:
				return r.a_id != removed_id and r.b_id != removed_id)
			if _road_first_id == removed_id:
				_road_first_id = -1
			_mark_dirty()
			_update_status("Removed city at (%d,%d)" % [hex.x, hex.y])
			_request_redraw()
			return
	_update_status("No city at (%d,%d)" % [hex.x, hex.y])

# ── Road operations ───────────────────────────────────────────────────────────

func _handle_road_click(hex: Vector2i) -> void:
	var clicked := _find_city_spawn_at_hex(hex)
	if clicked == null:
		_update_status("No city here. Click a city to start a road.")
		return
	if _road_first_id == -1:
		_road_first_id = clicked.id
		_update_status("Road from '%s' — click second city to toggle." % clicked.city_name)
		_request_redraw()
		return
	if clicked.id == _road_first_id:
		_road_first_id = -1
		_update_status("Cancelled.")
		_request_redraw()
		return

	var a := _road_first_id
	var b := clicked.id
	_road_first_id = -1
	var ld := _graph_map.level_data
	for i in range(ld.roads.size()):
		var r: RoadData = ld.roads[i]
		if (r.a_id == a and r.b_id == b) or (r.a_id == b and r.b_id == a):
			var roads := ld.roads.duplicate()
			roads.remove_at(i)
			ld.roads = roads
			_mark_dirty()
			_update_status("Removed road: %s <-> %s" % [
				_find_city_spawn(a).city_name if _find_city_spawn(a) else str(a),
				_find_city_spawn(b).city_name if _find_city_spawn(b) else str(b)])
			_request_redraw()
			return

	var road := RoadData.new()
	road.a_id = a; road.b_id = b
	var sa := _find_city_spawn(a); var sb := _find_city_spawn(b)
	road.length = _hex_distance(Vector2i(sa.hex_coord), Vector2i(sb.hex_coord)) if sa and sb else 1.0
	var roads := ld.roads.duplicate()
	roads.append(road)
	ld.roads = roads
	_mark_dirty()
	_update_status("Added road: %s <-> %s (len %.2f)" % [
		sa.city_name if sa else str(a), sb.city_name if sb else str(b), road.length])
	_request_redraw()

# ── Misc helpers ──────────────────────────────────────────────────────────────

func _hex_distance(a: Vector2i, b: Vector2i) -> float:
	var dq := b.x - a.x; var dr := b.y - a.y
	return float(maxi(absi(dq), maxi(absi(dr), absi(-dq - dr))))

func _find_city_spawn_at_hex(hex: Vector2i) -> CitySpawnData:
	if _graph_map == null or _graph_map.level_data == null:
		return null
	for cd in _graph_map.level_data.cities:
		if Vector2i(cd.hex_coord) == hex:
			return cd
	return null

func _find_city_spawn(id: int) -> CitySpawnData:
	if _graph_map == null or _graph_map.level_data == null:
		return null
	for cd in _graph_map.level_data.cities:
		if cd.id == id:
			return cd
	return null

func _next_id() -> int:
	var max_id := 0
	if _graph_map != null and _graph_map.level_data != null:
		for cd in _graph_map.level_data.cities:
			if cd.id > max_id:
				max_id = cd.id
	return max_id + 1

func _mark_dirty() -> void:
	if _graph_map != null and _graph_map.level_data != null:
		plugin.get_editor_interface().mark_scene_as_unsaved()
		ResourceSaver.save(_graph_map.level_data)

func _update_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text

# ── Panel UI ──────────────────────────────────────────────────────────────────

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(210, 0)
	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Hex Level Editor"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.text = "Select a GraphMap node"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_label)
	vbox.add_child(HSeparator.new())

	var mode_label := Label.new()
	mode_label.text = "Mode:"
	vbox.add_child(mode_label)
	_mode_option = OptionButton.new()
	_mode_option.add_item("Place / Remove Cities", 0)
	_mode_option.add_item("Toggle Roads", 1)
	_mode_option.item_selected.connect(_on_mode_changed)
	vbox.add_child(_mode_option)
	vbox.add_child(HSeparator.new())

	var name_label := Label.new()
	name_label.text = "City name:"
	vbox.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "City name"
	vbox.add_child(_name_edit)

	var owner_label := Label.new()
	owner_label.text = "Owner:"
	vbox.add_child(owner_label)
	_owner_option = OptionButton.new()
	_owner_option.add_item("Neutral (0)", 0)
	_owner_option.add_item("Player (1)", 1)
	_owner_option.add_item("Enemy (2)", 2)
	vbox.add_child(_owner_option)

	var army_label := Label.new()
	army_label.text = "Starting army:"
	vbox.add_child(army_label)
	_army_spin = SpinBox.new()
	_army_spin.min_value = 0
	_army_spin.max_value = 999
	_army_spin.value = 10
	vbox.add_child(_army_spin)

	var defense_label := Label.new()
	defense_label.text = "Defense level (0–3):"
	vbox.add_child(defense_label)
	_defense_spin = SpinBox.new()
	_defense_spin.min_value = 0
	_defense_spin.max_value = 3
	_defense_spin.value = 0
	vbox.add_child(_defense_spin)

	vbox.add_child(HSeparator.new())

	var hint := Label.new()
	hint.text = "Place mode:\n  L-click: place city\n  R-click: remove city\n\nRoad mode:\n  L-click city A then B\n  to add/remove road\n  R-click: cancel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

func _on_mode_changed(_idx: int) -> void:
	_road_first_id = -1
	_request_redraw()
	match _idx:
		0: _update_status("Place mode: L-click to place, R-click to remove.")
		1: _update_status("Road mode: click two cities to toggle a road.")
