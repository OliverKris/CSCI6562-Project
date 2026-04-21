extends Node

var default_hover_sound: AudioStream = preload("res://Audio/SFX/HoverSound.wav")
var default_click_sound: AudioStream = preload("res://Audio/SFX/SelectSound.wav")
var greyed_out_sfx: AudioStream = preload("res://Audio/SFX/GreyedOut.wav")

var main_menu_music: AudioStream = preload("res://Audio/Music/MainMenu.wav")
#var game_music: AudioStream = preload("res://Audio/Music/GameLoop.wav")
#var tutorial_music: AudioStream = preload("res://Audio/Music/Tutorial.wav")

var transition_out_sfx: AudioStream = preload("res://Audio/SFX/FadeOut.wav")
var transition_in_sfx: AudioStream = preload("res://Audio/SFX/FadeIn.wav")

var select_city_sfx: AudioStream = preload("res://Audio/SFX/SelectCity.wav")
var deselect_city_sfx: AudioStream = preload("res://Audio/SFX/DeselectCity.wav")

const POOL_SIZE := 8
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

var _music_player: AudioStreamPlayer
var _current_music: AudioStream = null

const SPEEDS: Array = [0.5, 1.0, 2.0, 4.0]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# SFX pool
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)

	# Dedicated music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

func _play_sound(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var player := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE

	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_hover(sound: AudioStream = null, volume_db: float = 8.0, pitch_scale: float = 1.0) -> void:
	_play_sound(sound if sound != null else default_hover_sound, volume_db, pitch_scale)

func play_click(sound: AudioStream = null, volume_db: float = 8.0, pitch_scale: float = 1.0) -> void:
	_play_sound(sound if sound != null else default_click_sound, volume_db, pitch_scale)

func play_music(stream: AudioStream, volume_db: float = 0.0, restart_if_same: bool = false) -> void:
	if stream == null:
		return

	if _current_music == stream and _music_player.playing and not restart_if_same:
		return

	_current_music = stream
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_current_music = null

func play_main_menu_music() -> void:
	play_music(main_menu_music, -8.0)

#func play_game_music() -> void:
	#play_music(game_music, -10.0)
#
#func play_tutorial_music() -> void:
	#play_music(tutorial_music, -8.0)

func set_music_volume(linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Music")
	if linear_value <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func set_sfx_volume(linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index("SFX")
	if linear_value <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func play_greyed_out() -> void:
	_play_sound(greyed_out_sfx, 0.0)

func play_transition_out() -> void:
	_play_sound(transition_out_sfx, 0.0)

func play_transition_in() -> void:
	_play_sound(transition_in_sfx, 0.0)

func play_city_select() -> void:
	_play_sound(select_city_sfx, 0.0)

func play_city_deselect() -> void:
	_play_sound(deselect_city_sfx, 0.0)

func _on_music_slider_changed(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Music")

	if value <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_sfx_slider_changed(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("SFX")

	if value <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
