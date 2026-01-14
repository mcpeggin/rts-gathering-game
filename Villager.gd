@tool
class_name Villager extends AbstractSelectableUnit

@onready var resource_counter: Label = $Body/ResourceCapacity

@export var max_capacity: int:
	set(value):
		max_capacity = value
		if is_node_ready():
			update_gathered_resource_label()

var qty_gathered: int

enum STATES {
	IDLE,
	MOVING,
	MOVING_TO_GOODS,
	GATHERING,
	MOVING_TO_STORAGE,
	STORING
}

var cur_state = STATES.IDLE
var assigned_good = null
var assigned_storage = null

var _just_assigned_good = false

func _ready():
	super._ready() # call AbstractSelectableUnit first, so shit works
	qty_gathered = 0
	update_gathered_resource_label()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	super._physics_process(delta)
	
	if Input.is_action_just_pressed("right_click") and is_selected:
		if not _just_assigned_good:
			cur_state = STATES.MOVING
			assigned_good = null
			assigned_storage = null
	
	_just_assigned_good = false
	
	if position.distance_to(click_pos) <= 3:
		_on_moved_to_goods()

func update_gathered_resource_label():
	resource_counter.text = "%d / %d" % [qty_gathered, max_capacity]

func assign_good(good):
	assigned_good = good
	cur_state = STATES.MOVING_TO_GOODS
	click_pos = good.position
	_just_assigned_good = true

func _on_moved_to_goods():
	match cur_state:
		STATES.MOVING_TO_GOODS:
			cur_state = STATES.GATHERING
		STATES.MOVING_TO_STORAGE:
			cur_state = STATES.STORING
		_:
			pass

func find_nearest_storage():
	var storages = get_tree().get_nodes_in_group("tree_storage")
	var nearest = null
	var nearest_dist = INF
	
	for storage in storages:
		if storage.qty_stored >= storage.max_capacity:
			continue
		
		var dist = position.distance_to(storage.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = storage
	
	return nearest

func go_to_storage():
	
	if qty_gathered == 0:
		cur_state = STATES.IDLE
		assigned_good = null
		assigned_storage = null
		return
	
	assigned_storage = find_nearest_storage()
	if assigned_storage:
		cur_state = STATES.MOVING_TO_STORAGE
		click_pos = assigned_storage.position
	else:
		cur_state = STATES.IDLE

func return_to_good_or_idle():
	if qty_gathered > 0:
		var new_storage = find_nearest_storage()
		if new_storage:
			assigned_storage = new_storage
			cur_state = STATES.MOVING_TO_STORAGE
			click_pos = assigned_storage.position
			return
	
	var new_good = find_nearest_good()
	if new_good:
		assigned_good = new_good
		cur_state = STATES.MOVING_TO_GOODS
		click_pos = assigned_good.position
	else:
		cur_state = STATES.IDLE
		assigned_good = null
		assigned_storage = null

func find_nearest_good():
	if assigned_good == null:
		return null
	
	var goods = get_tree().get_nodes_in_group('goods')
	var nearest = null
	var nearest_dist = INF
	
	for good in goods:
		if good.type != assigned_good.type:
			continue
		if good.qty_available <= 0:
			continue
		
		var dist = position.distance_to(good.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = good
			
	return nearest

func on_good_depleted():
	if qty_gathered >= max_capacity:
		go_to_storage()
		return
	
	var new_good = find_nearest_good()
	if new_good:
		assigned_good = new_good
		cur_state = STATES.MOVING_TO_GOODS
		click_pos = assigned_good.position
	elif qty_gathered > 0:
		go_to_storage()
	else:
		cur_state = STATES.IDLE
		assigned_good = null
		assigned_storage = null
