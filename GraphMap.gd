extends Node2D
class_name GraphMap

@onready var cities_node: Node = $Cities

var selected_city: City = null

func _ready() -> void:
	for child in cities_node.get_children():
		if child is City:
			child.clicked.connect(_on_city_clicked)

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
