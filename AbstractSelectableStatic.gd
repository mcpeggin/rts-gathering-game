class_name AbstractSelectableStatic extends Node2D

@onready var area = $Area
@onready var indicator = $Indicator
@onready var counter = $Body/ResourceCounter

var is_selected := false
var is_hover := false

func _ready():
	area.connect("mouse_entered", _on_mouse_entered)
	area.connect("mouse_exited", _on_mouse_exited)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_hover:
			is_selected = false
			indicator.visible = false
	
	if get_tree().get_nodes_in_group('selected_villagers').size() > 0:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if is_hover:
				is_selected = true
			else:
				is_selected = false
				indicator.visible = false

func _on_mouse_entered():
	is_hover = true
	counter.visible = true
	indicator.visible = true

func _on_mouse_exited():
	is_hover = false
	counter.visible = false
	if not is_selected:
		indicator.visible = false

func turn_off_area():
	area.monitoring = false
	area.monitorable = false
	area.input_pickable = false
	is_selected = false
	is_hover = false
	indicator.visible = false
