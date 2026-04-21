extends Node

#var hover_sound: AudioStream = preload("res://Audio/hover.wav")
var click_sound: AudioStream = preload("res://Audio/SelectSound.wav")

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer

func _ready() -> void:
	_hover_player = AudioStreamPlayer.new()
	_click_player = AudioStreamPlayer.new()

	_hover_player.bus = "SFX"
	_click_player.bus = "SFX"

	add_child(_hover_player)
	add_child(_click_player)

#func play_hover() -> void:
	#if hover_sound == null:
		#return
#
	## Prevent ugly hover spam if desired
	#if _hover_player.playing:
		#return
#
	#_hover_player.stream = hover_sound
	#_hover_player.play()

func play_click() -> void:
	if click_sound == null:
		return

	_click_player.stream = click_sound
	_click_player.play()
