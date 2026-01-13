extends Node2D
@onready var camera: Camera2D = $Camera2D
var isPressed := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and isPressed:
		global_position -= event.relative
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			isPressed = event.pressed
			
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom -= Vector2(0.5, 0.5)
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom += Vector2(0.5, 0.5)
