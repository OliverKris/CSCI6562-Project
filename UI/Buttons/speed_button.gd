extends TextureButton

@onready var icon: TextureRect = $Icon

@export var sprite_sheet: Texture2D
@export var frame_count: int = 4
@export var flipped := false

@export var press_in_time := 0.04
@export var release_time := 0.04

var frame_textures: Array[AtlasTexture] = []
var is_pressed_visual := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_frames()
	_set_frame(0)

	button_down.connect(_on_button_down_visual)
	button_up.connect(_on_button_up_visual)

func _build_frames() -> void:
	frame_textures.clear()

	if sprite_sheet == null:
		push_error("No sprite_sheet assigned to button.")
		return

	var sheet_size: Vector2 = sprite_sheet.get_size()
	var frame_width := int(sheet_size.x / frame_count)
	var frame_height := int(sheet_size.y)

	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frame_textures.append(atlas)

func _set_frame(index: int) -> void:
	if index < 0 or index >= frame_textures.size():
		return

	icon.texture = frame_textures[index]

	# Mirror the texture visually for the opposite button if needed.
	if flipped:
		icon.flip_h = true
	else:
		icon.flip_h = false

func _on_button_down_visual() -> void:
	print(name, " button_down visual fired")
	is_pressed_visual = true

	# Frame 1 = press-in
	_set_frame(1)

	await get_tree().create_timer(press_in_time).timeout

	# Only continue if still held down
	if is_pressed_visual:
		# Frame 2 = fully pressed
		_set_frame(2)

func _on_button_up_visual() -> void:
	is_pressed_visual = false

	# Frame 3 = release
	_set_frame(3)

	await get_tree().create_timer(release_time).timeout

	# Back to idle
	_set_frame(0)
