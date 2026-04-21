extends HBoxContainer
class_name MissionRow

@onready var label: Label = $ObjectiveLabel
@onready var check_icon: TextureRect = $CheckBoxIcon

@export var unchecked_texture: Texture2D
@export var checked_texture: Texture2D

var objective_id: String = ""
var completed: bool = false

func setup(data: Dictionary) -> void:
	objective_id = str(data.get("id", ""))
	label.text = str(data.get("text", ""))
	set_completed(bool(data.get("completed", false)))

func set_completed(value: bool) -> void:
	completed = value

	if completed:
		check_icon.texture = checked_texture
		check_icon.modulate = Color(0.4, 1.0, 0.4, 1.0)
	else:
		check_icon.texture = unchecked_texture
		check_icon.modulate = Color(1, 1, 1, 1)
