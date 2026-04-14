@tool
extends EditorPlugin

var _panel: Control = null
var _overlay: HexEditorOverlay = null

func _enter_tree() -> void:
	# Clean up any leftover panel from a previous load (e.g. hot-reload)
	if _panel != null:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, _panel)
		_panel.queue_free()
		_panel = null

	_overlay = HexEditorOverlay.new()
	_overlay.plugin = self

	# Build the panel once and keep the reference
	_panel = _overlay.get_panel()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, _panel)

	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)

func _exit_tree() -> void:
	if _panel != null:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, _panel)
		_panel.queue_free()
		_panel = null
	_overlay = null

func _on_selection_changed() -> void:
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	for node in selected:
		if node is GraphMap:
			if _overlay != null:
				_overlay.set_graph_map(node as GraphMap)
			return

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _overlay != null:
		return _overlay.handle_input(event)
	return false

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if _overlay != null:
		_overlay.draw_over_viewport(overlay)

func _handles(object: Object) -> bool:
	return object is GraphMap

func _make_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible
