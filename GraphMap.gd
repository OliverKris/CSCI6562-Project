extends Node2D
class_name GraphMap

@onready var cities_node: Node = $Cities
@onready var road_layer: RoadLayer = $RoadLayer

@export var roads: Array[RoadData] = []

# Graph state
var cities_by_id: Dictionary = {}
var adj: Dictionary = {}

# Selection state
var selected_city: City = null

func _ready() -> void:
	_register_cities()
	_build_adjacency_from_roads()
	
	road_layer.set_graph(self)
	road_layer.queue_redraw()

func _register_cities() -> void:
	cities_by_id.clear()
	
	for child in cities_node.get_children():
		if child is City:
			if child.data == null:
				push_warning("City '%s' has no CityData assigned." % child.name)
				continue
			
			var id: int = child.data.id
			
			if cities_by_id.has(id):
				push_warning("Duplicate city id %s (city '%s)." % [str(id), child.name])
				continue
				
			cities_by_id[id] = child
			child.clicked.connect(_on_city_clicked)

func get_road_segments() -> Array:
	var segments: Array = []
	for r in roads:
		if not cities_by_id.has(r.a_id) or not cities_by_id.has(r.b_id):
			continue
		var a_pos = cities_by_id[r.a_id].global_position
		var b_pos = cities_by_id[r.b_id].global_position
		segments.append([a_pos, b_pos])
	return segments

func _on_city_clicked(city: City):
	if selected_city == city:
		_set_selected_city(null)
	else:
		_set_selected_city(city)
		
func _set_selected_city(city: City):
	if selected_city:
		selected_city.set_selected(false)
	
	selected_city = city
	
	if selected_city:
		selected_city.set_selected(true)
		print("Selected: ", selected_city.data.name if selected_city.data else selected_city.name)
	else:
		print("Selected: none")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_selected_city(null)

func _build_adjacency_from_roads():
	adj.clear()
	
	for id in cities_by_id.keys():
		adj[id] = []
		
	for r in roads:
		if not cities_by_id.has(r.a_id) or not cities_by_id.has(r.b_id):
			continue
		adj[r.a_id].append(r.b_id)
		adj[r.b_id].append(r.a_id)
