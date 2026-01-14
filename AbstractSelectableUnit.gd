class_name AbstractSelectableUnit extends CharacterBody2D

@onready var area = $Area
@onready var indicator = $Indicator

@onready var counter = $Body/ResourceCapacity

var speed = 50
var click_pos = Vector2()
var target_pos = Vector2()

var is_selected := false
var is_hover := false

func _ready():
	click_pos = position # so it wont move to the axis center
	area.connect("mouse_entered", _on_mouse_entered)
	area.connect("mouse_exited", _on_mouse_exited)

# unit movement

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if Input.is_action_just_pressed("right_click") and is_selected:
		click_pos = get_global_mouse_position()
	
	if position.distance_to(click_pos) > 3:
		target_pos = (click_pos - position).normalized()
		velocity = target_pos * speed
		move_and_slide()

func _input(event):
	if Engine.is_editor_hint():
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_hover:
			is_selected = true
			add_to_group('selected_villagers')
		else:
			is_selected = false
			remove_from_group('selected_villagers')
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
		
