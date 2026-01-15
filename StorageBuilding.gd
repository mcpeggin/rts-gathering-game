@tool
class_name StorageBuilding extends AbstractSelectableStatic

@onready var resource_counter: Label = $Body/ResourceCounter
@onready var dispense_timer: Timer = $DispenseTimer

@export var qty: int:
	set(value):
		qty = value
		max_capacity = qty
		if is_node_ready():
			update_stored_resource_label()

enum TYPES {
	WOOD, 
	STONE, 
	WHEET,
	ANY
}

@export var type: TYPES

var is_gathered := false
var gatherers = []

# label above good
var qty_stored: int = 0
var max_capacity: int

func _ready():
	super._ready() # call AbstractSelectableStatic first, so shit works
	add_to_group('storages') # i did it via engine, but to be sure
	max_capacity = qty
	
	update_stored_resource_label()
	
	area.connect("area_entered", _on_area_entered)
	area.connect("area_exited", _on_area_exited)
	
	dispense_timer.timeout.connect(_on_gather_tick)

func _input(event):
	super._input(event)
	
	if get_tree().get_nodes_in_group('selected_villagers').size() > 0:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if is_hover:
				var selected = get_tree().get_nodes_in_group('selected_villagers')
				for villager in selected:
					villager.assign_storage(self)

func update_stored_resource_label():
	resource_counter.text = "%d / %d" % [qty_stored, max_capacity]
	
	if qty_stored == max_capacity:
		for gatherer in gatherers:
			if gatherer.cur_state == gatherer.STATES.STORING:
				gatherer.return_to_good_or_idle()
		gatherers.clear()
		stop_storing()

func _on_area_entered(collider):
	if collider.get_parent() is Villager:
		var villager = collider.get_parent()
		if villager.assigned_good == null:
			return
		if type != villager.assigned_good.type and type != TYPES.ANY:
			return
		
		if villager not in gatherers:
			gatherers.append(villager)
		if not dispense_timer.is_stopped():
			return
		is_gathered = true
		dispense_timer.start()

func _on_area_exited(collider):
	if collider.get_parent() is Villager:
		gatherers.erase(collider.get_parent())
		if gatherers.is_empty():
			stop_storing()

# this logically belongs to the villager cause thats what he does actively

func stop_storing():
	is_gathered = false
	dispense_timer.stop()

func _on_gather_tick():
	if gatherers.is_empty():
		stop_storing()
		return
	
	var gatheres_to_remove = []
	for gatherer in gatherers:
		if qty_stored >= max_capacity:
			break
		if gatherer.qty_gathered > 0:
			qty_stored += 1
			gatherer.qty_gathered -= 1
			gatherer.update_gathered_resource_label()
		else:
			if gatherer.cur_state == gatherer.STATES.STORING:
				gatherer.return_to_good_or_idle()
			gatheres_to_remove.append(gatherer)
			
	for gatherer in gatheres_to_remove:
		gatherers.erase(gatherer)
		
	update_stored_resource_label()
