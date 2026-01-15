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
var pending_good = null

var _just_assigned_good = false

func _ready():
	super._ready() # call AbstractSelectableUnit first, so shit works
	qty_gathered = 0
	update_gathered_resource_label()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var saved_click_pos = click_pos
	super._physics_process(delta)
	
	if _just_assigned_good:
		click_pos = saved_click_pos
	
	if Input.is_action_just_pressed("right_click") and is_selected:
		if not _just_assigned_good:
			cur_state = STATES.MOVING
			assigned_good = null
			assigned_storage = null
			pending_good = null
	
	_just_assigned_good = false
	
	if position.distance_to(click_pos) <= 3:
		_on_moved_to_goods()

func update_gathered_resource_label():
	resource_counter.text = "%d / %d" % [qty_gathered, max_capacity]

func assign_good(good):
	if qty_gathered > 0 and assigned_good != null and assigned_good.type != good.type:
		pending_good = good
		go_to_storage()
		_just_assigned_good = true
		return
	
	assigned_good = good
	pending_good = null
	cur_state = STATES.MOVING_TO_GOODS
	click_pos = good.position
	_just_assigned_good = true

func assign_storage(storage):
	assigned_storage = storage
	var good = find_nearest_good_by_type(storage)
	
	if good:
		assigned_good = good
		cur_state = STATES.MOVING_TO_GOODS
		click_pos = good.position
	else:
		cur_state = STATES.IDLE
	
	_just_assigned_good = true

func find_nearest_good_by_type(storage):
	var goods = get_tree().get_nodes_in_group('goods')
	var nearest = null
	var nearest_dist = INF
	
	for good in goods:
		if storage.type != storage.TYPES.ANY and good.type != storage.type:
			continue
		if good.qty_available <= 0:
			continue
		
		var dist = position.distance_to(good.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = good
	
	return nearest

func _on_moved_to_goods():
	match cur_state:
		STATES.MOVING_TO_GOODS:
			if assigned_good == null or assigned_good.qty_available <= 0:
				on_good_depleted()
				return
			cur_state = STATES.GATHERING
		STATES.MOVING_TO_STORAGE:
			cur_state = STATES.STORING
		_:
			pass

func find_nearest_storage():
	if assigned_good == null:
		return null
	
	var storages = get_tree().get_nodes_in_group("storages")
	var nearest = null
	var nearest_dist = INF
	
	for storage in storages:
		if storage.qty_stored >= storage.max_capacity:
			continue
		if storage.type != assigned_good.type and storage.type != storage.TYPES.ANY:
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
	if pending_good != null:
		assigned_good = pending_good
		pending_good = null
		cur_state = STATES.MOVING_TO_GOODS
		click_pos = assigned_good.position
		return
	
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
	if cur_state != STATES.GATHERING and cur_state != STATES.MOVING_TO_GOODS:
		return
	
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
