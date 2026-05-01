extends Area2D
class_name Unit

signal arrived(unit: Unit, target_city: City)

@export var pixels_per_road_unit: float = 150.0
@export var radius: float = 8.0

# -------------------------------------------------
# Visual / Animation
# -------------------------------------------------
@export var animation_strip: Texture2D
@export var frame_width: int = 16
@export var frame_height: int = 16

@export var walk_start: int = 0
@export var walk_frames: int = 4
@export var walk_fps: float = 8.0

@export var attack_start: int = 4
@export var attack_frames: int = 7
@export var attack_fps: float = 10.0

@export var arrival_fade_time: float = 0.2
var _is_arrival_fading: bool = false

@export var death_start: int = 11
@export var death_frames: int = 4
@export var death_fps: float = 10.0

@export var player_tints: Array[Color] = [
	Color("2aa8e0"), # base blue
	Color("1f90c4"), # slightly darker
	Color("4fc2ee")  # slightly lighter
]

@export var enemy_tints: Array[Color] = [
	Color("e24a4a"), # base red
	Color("c23a3a"), # slightly darker
	Color("f06a6a")  # slightly lighter
]

@export var neutral_tints: Array[Color] = [
	Color("7a7f87"), # base gray
	Color("656a72"), # darker gray
	Color("9aa0a8")  # lighter gray
]

var _chosen_tint: Color = Color.WHITE

@export var attack_impact_frame: int = 3
var _attack_sound_played_this_cycle: bool = false

@export var sprite_faces_right: bool = true
@export var death_hold_time: float = 1.0
@export var death_fade_time: float = 0.25

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var _walk_frame_textures: Array[AtlasTexture] = []
var _attack_frame_textures: Array[AtlasTexture] = []
var _death_frame_textures: Array[AtlasTexture] = []

enum UnitAnimState {
	WALK,
	ATTACK,
	DEATH
}

var _anim_state: int = UnitAnimState.WALK
var _anim_time: float = 0.0
var _anim_frame_index: int = 0
var _death_finished: bool = false

# -------------------------------------------------
# Gameplay
# -------------------------------------------------
var source_city: City
var target_city: City
var road: RoadData

var unit_owner: int = 0
var amount: int = 0

var _start_pos: Vector2
var _end_pos: Vector2
var _travel_time: float = 1.0
var _elapsed: float = 0.0
var _in_battle: bool = false
var _is_dying: bool = false
var _parked: bool = false
var _has_arrived: bool = false

# ── Field battle ──────────────────────────────────────────────────────────────
var _field_battle_opponent: Unit = null
var _is_battle_manager: bool = false

func _ready() -> void:
	randomize()
	area_entered.connect(_on_area_entered)
	_build_animation_frames()

	if sprite != null:
		sprite.texture = null

	_apply_owner_visuals()
	_update_label()
	_play_walk()

func setup(from_city: City, to_city: City, road_data: RoadData, send_amount: int, faction_owner: int) -> void:
	source_city = from_city
	target_city = to_city
	road = road_data
	amount = send_amount
	unit_owner = faction_owner
	_has_arrived = false
	_is_arrival_fading = false
	
	_chosen_tint = _pick_unit_tint()

	var dir: Vector2 = (to_city.global_position - from_city.global_position).normalized()
	_start_pos = from_city.global_position + dir * from_city.get_radius()
	_end_pos = to_city.global_position - dir * to_city.get_radius()
	global_position = _start_pos

	_apply_owner_visuals()
	_update_label()
	_play_walk()

	var dist: float = _start_pos.distance_to(_end_pos)
	var road_len: float = 1.0
	if road != null:
		road_len = max(road.length, 0.1)

	var computed_time: float = (dist / pixels_per_road_unit) * road_len
	_travel_time = max(computed_time, 0.05)

func _pick_unit_tint() -> Color:
	randomize()
	var palette: Array[Color] = neutral_tints

	match unit_owner:
		1:
			palette = player_tints
		2:
			palette = enemy_tints
		_:
			palette = neutral_tints

	if palette.is_empty():
		return Color.WHITE

	return palette[randi() % palette.size()]

func _build_animation_frames() -> void:
	_walk_frame_textures.clear()
	_attack_frame_textures.clear()
	_death_frame_textures.clear()

	if animation_strip == null:
		push_error("Unit: animation_strip is not assigned.")
		return

	_walk_frame_textures = _build_frame_range(walk_start, walk_frames)
	_attack_frame_textures = _build_frame_range(attack_start, attack_frames)
	_death_frame_textures = _build_frame_range(death_start, death_frames)

func _build_frame_range(start_index: int, count: int) -> Array[AtlasTexture]:
	var result: Array[AtlasTexture] = []

	if animation_strip == null:
		return result

	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = animation_strip
		atlas.region = Rect2(
			(start_index + i) * frame_width,
			0,
			frame_width,
			frame_height
		)
		result.append(atlas)

	return result

func _apply_owner_visuals() -> void:
	if _chosen_tint == Color.WHITE:
		_chosen_tint = _pick_unit_tint()

	if sprite != null:
		sprite.modulate = _chosen_tint

func _update_label() -> void:
	if label == null:
		return

	label.text = str(amount)
	label.modulate = Color(1, 1, 1, 1)
	await get_tree().process_frame
	label.position = Vector2(-label.size.x * 0.5, 12)

# -------------------------------------------------
# Animation control
# -------------------------------------------------
func _play_walk() -> void:
	if _is_dying:
		return
	if _anim_state == UnitAnimState.WALK:
		return

	_anim_state = UnitAnimState.WALK
	_anim_time = 0.0
	_anim_frame_index = 0
	_attack_sound_played_this_cycle = false	
	_death_finished = false
	_apply_current_frame()

func _play_attack() -> void:
	if _is_dying:
		return
	if _anim_state == UnitAnimState.ATTACK:
		return

	_anim_state = UnitAnimState.ATTACK
	_anim_time = 0.0
	_anim_frame_index = 0
	_attack_sound_played_this_cycle = false	
	_apply_current_frame()

func _play_death() -> void:
	if _anim_state == UnitAnimState.DEATH:
		return

	_anim_state = UnitAnimState.DEATH
	_anim_time = 0.0
	_anim_frame_index = 0
	_attack_sound_played_this_cycle = false	
	_death_finished = false
	_apply_current_frame()

func fade_out_into_friendly_city() -> void:
	if _is_dying or _is_arrival_fading:
		return

	_is_arrival_fading = true
	_has_arrived = true
	_parked = false
	_in_battle = false
	set_process(false)
	monitoring = false
	monitorable = false

	if label != null:
		label.visible = false

	var tween := create_tween()
	if sprite != null:
		tween.tween_property(sprite, "modulate:a", 0.0, arrival_fade_time)
	else:
		tween.tween_property(self, "modulate:a", 0.0, arrival_fade_time)

	await tween.finished
	queue_free()

func _get_current_frame_array() -> Array[AtlasTexture]:
	match _anim_state:
		UnitAnimState.WALK:
			return _walk_frame_textures
		UnitAnimState.ATTACK:
			return _attack_frame_textures
		UnitAnimState.DEATH:
			return _death_frame_textures
	return []

func _get_current_fps() -> float:
	match _anim_state:
		UnitAnimState.WALK:
			return walk_fps
		UnitAnimState.ATTACK:
			return attack_fps
		UnitAnimState.DEATH:
			return death_fps
	return 1.0

func _try_play_attack_sound() -> void:
	if _anim_state != UnitAnimState.ATTACK:
		return

	if _attack_sound_played_this_cycle:
		return

	if _anim_frame_index == attack_impact_frame:
		_attack_sound_played_this_cycle = true
		AudioManager.play_unit_attack()

func _apply_current_frame() -> void:
	if sprite == null:
		return

	var frames := _get_current_frame_array()
	if frames.is_empty():
		return

	_anim_frame_index = clamp(_anim_frame_index, 0, frames.size() - 1)
	sprite.texture = frames[_anim_frame_index]

func _update_animation(delta: float) -> void:
	var frames := _get_current_frame_array()
	if frames.is_empty():
		return

	var fps: float = max(_get_current_fps(), 0.01)
	var frame_duration: float = 1.0 / fps

	_anim_time += delta
	while _anim_time >= frame_duration:
		_anim_time -= frame_duration
		_anim_frame_index += 1

		if _anim_state == UnitAnimState.DEATH:
			if _anim_frame_index >= frames.size():
				_anim_frame_index = frames.size() - 1
				_death_finished = true
				break
		else:
			if _anim_frame_index >= frames.size():
				_anim_frame_index = 0

				if _anim_state == UnitAnimState.ATTACK:
					_attack_sound_played_this_cycle = false

		_try_play_attack_sound()

	_apply_current_frame()

# -------------------------------------------------
# Helpers
# -------------------------------------------------
func get_progress() -> float:
	return min(_elapsed / _travel_time, 1.0)

func is_opposing(other: Unit) -> bool:
	if _in_battle or other._in_battle:
		return false
	if unit_owner == other.unit_owner:
		return false
	if road == null or other.road == null:
		return false

	var same_road: bool = (
		(road.a_id == other.road.a_id and road.b_id == other.road.b_id) or
		(road.a_id == other.road.b_id and road.b_id == other.road.a_id)
	)
	if not same_road:
		return false

	return source_city == other.target_city and target_city == other.source_city

# ── Field battle ──────────────────────────────────────────────────────────────
func _resolve_field_battle(other: Unit) -> void:
	if _in_battle or other._in_battle or _is_dying or other._is_dying:
		return

	_in_battle = true
	other._in_battle = true
	_field_battle_opponent = other
	other._field_battle_opponent = self
	_is_battle_manager = true
	other._is_battle_manager = false

	_play_attack()
	other._play_attack()

	if not CycleClock.cycle_ticked.is_connected(_on_field_battle_tick):
		CycleClock.cycle_ticked.connect(_on_field_battle_tick)

func _on_field_battle_tick() -> void:
	if not _is_battle_manager:
		return

	if _field_battle_opponent == null or not is_instance_valid(_field_battle_opponent):
		_disconnect_tick()
		_finish_as_winner()
		return

	var self_damage: int = maxi(1, int(sqrt(float(_field_battle_opponent.amount))))
	var opp_damage: int = maxi(1, int(sqrt(float(amount))))

	amount -= self_damage
	_field_battle_opponent.amount -= opp_damage

	_update_label()
	_field_battle_opponent._update_label()

	var self_dead: bool = amount <= 0
	var opp_dead: bool = _field_battle_opponent.amount <= 0

	if self_dead and opp_dead:
		var opp := _field_battle_opponent
		_disconnect_tick()
		_field_battle_opponent = null
		if opp != null:
			opp._field_battle_opponent = null
			opp._die()
		_die()

	elif self_dead:
		var opp := _field_battle_opponent
		_disconnect_tick()
		_field_battle_opponent = null
		if opp != null:
			opp._field_battle_opponent = null
			opp._finish_as_winner()
		_die()

	elif opp_dead:
		var opp := _field_battle_opponent
		_disconnect_tick()
		_field_battle_opponent = null
		if opp != null:
			opp._field_battle_opponent = null
			opp._die()
		_finish_as_winner()

func _disconnect_tick() -> void:
	if CycleClock.cycle_ticked.is_connected(_on_field_battle_tick):
		CycleClock.cycle_ticked.disconnect(_on_field_battle_tick)

func _finish_as_winner() -> void:
	_in_battle = false
	_is_battle_manager = false
	_field_battle_opponent = null
	_disconnect_tick()

	if _travel_time > 0.0:
		var current_dist: float = global_position.distance_to(_end_pos)
		var total_dist: float = _start_pos.distance_to(_end_pos)
		var remaining_frac: float = current_dist / max(total_dist, 0.001)
		_elapsed = _travel_time * (1.0 - remaining_frac)

	_play_walk()

func _die() -> void:
	if _is_dying:
		return

	AudioManager._play_sound(AudioManager.death_sfx, 0.0)

	_is_dying = true
	_in_battle = false
	_is_battle_manager = false
	_parked = false
	visible = true
	_disconnect_tick()

	if label != null:
		label.visible = false

	_play_death()
	await _death_sequence()
	queue_free()

func _death_sequence() -> void:
	while not _death_finished:
		await get_tree().process_frame

	await get_tree().create_timer(death_hold_time).timeout

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, death_fade_time)
	await tween.finished

func _exit_tree() -> void:
	_disconnect_tick()

# ── Physics collision ─────────────────────────────────────────────────────────
func _on_area_entered(other_area: Area2D) -> void:
	if not (other_area is Unit):
		return

	var other: Unit = other_area as Unit
	if not is_opposing(other):
		return

	if get_progress() >= other.get_progress():
		_resolve_field_battle(other)

# ── Parked (at city during city battle) ───────────────────────────────────────
func park_at_city() -> void:
	_parked = true
	visible = true
	begin_city_attack()

# Call this when the unit is attacking a city / structure
func begin_city_attack() -> void:
	if _is_dying:
		return
	_in_battle = true
	_play_attack()

func end_city_attack() -> void:
	if _is_dying:
		return
	_in_battle = false
	_play_walk()

# ── Movement / animation update ───────────────────────────────────────────────
func _process(delta: float) -> void:
	# Always let animations run, even for parked units and dying units.
	_update_animation(delta)

	if _is_dying:
		return

	if _parked:
		return

	if _in_battle:
		return

	if target_city == null or not is_instance_valid(target_city):
		queue_free()
		return

	_elapsed += delta * CycleClock.speed_scale
	var t: float = min(_elapsed / _travel_time, 1.0)
	global_position = _start_pos.lerp(_end_pos, t)

	if sprite != null:
		var dir := _end_pos - _start_pos
		if abs(dir.x) > 0.01:
			if sprite_faces_right:
				sprite.flip_h = dir.x > 0.0
			else:
				sprite.flip_h = dir.x < 0.0

	if t >= 1.0 and not _has_arrived:
		_has_arrived = true
		emit_signal("arrived", self, target_city)

func die_in_battle() -> void:
	_die()

# ── Drawing ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	pass
