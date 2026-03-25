extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.size_changed.connect(_on_window_resized)

func _on_window_resized() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
