extends CanvasLayer

signal dismissed

# Correct paths relative to the VBoxContainer in your .tscn
@onready var text_label: Label = $Panel/VBoxContainer/Label
@onready var ok_button: Button = $Panel/VBoxContainer/Button
@onready var video_player: VideoStreamPlayer = $Panel/VBoxContainer/VideoStreamPlayer

var _pending_text: String = ""
var _pending_video: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS 
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Apply content if it was set before ready
	if _pending_text != "":
		apply_content(_pending_text, _pending_video)

func set_content(text: String, video_path: String = ""):
	if not is_inside_tree():
		_pending_text = text
		_pending_video = video_path
		return
	apply_content(text, video_path)

func apply_content(text: String, video_path: String):
	text_label.text = text
	if video_path != "" and video_player:
		var stream = load(video_path)
		if stream:
			video_player.stream = stream
			video_player.process_mode = Node.PROCESS_MODE_ALWAYS
			# Force the player to update its texture
			video_player.show() 
			video_player.play()
			

func _on_ok_pressed() -> void:
	dismissed.emit()
	queue_free()
