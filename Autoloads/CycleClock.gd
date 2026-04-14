extends Node

# Global cycle clock. Everything that happens "per cycle" subscribes to this signal.
# The speed_scale is controlled by the UI speed dial.

signal cycle_ticked

const BASE_INTERVAL: float = 1.0  # seconds per cycle at 1x speed

var speed_scale: float = 1.0  # multiplier: 0.5, 1.0, 2.0, 4.0
var _timer: float = 0.0
var _paused: bool = false

func set_speed(scale: float) -> void:
	speed_scale = max(scale, 0.01)

func pause_clock() -> void:
	_paused = true

func resume_clock() -> void:
	_paused = false

func _process(delta: float) -> void:
	if _paused:
		return
	# Clamp delta to avoid multi-firing on lag spikes (e.g. after a freeze)
	var clamped_delta: float = min(delta, BASE_INTERVAL)
	_timer += clamped_delta * speed_scale
	if _timer >= BASE_INTERVAL:
		_timer = fmod(_timer, BASE_INTERVAL)
		emit_signal("cycle_ticked")
