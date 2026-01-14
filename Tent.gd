@tool
class_name Building extends AbstractSelectableStatic

@onready var resource_counter: Label = $Body/ResourceCounter
@onready var dispense_timer: Timer = $DispenseTimer

@export var qty: int:
	set(value):
		qty = value
		max_capacity = qty
		if is_node_ready():
			update_stored_resource_label()

enum TYPES {WOOD, STONE, FOOD}
@export var type: TYPES

var is_gathered := false
var gatherer = null

# label above good
var qty_stored: int = 0
var max_capacity: int

func _ready():
	super._ready() # call AbstractSelectableStatic first, so shit works
	add_to_group('tree_storage') # i did it via engine, but to be sure
	max_capacity = qty
	
	update_stored_resource_label()
	
	area.connect("area_entered", _on_area_entered)
	area.connect("area_exited", _on_area_exited)
	
	dispense_timer.timeout.connect(_on_gather_tick)

func update_stored_resource_label():
	resource_counter.text = "%d / %d" % [qty_stored, max_capacity]
	
	if qty_stored == max_capacity:
		stop_storing()

func _on_area_entered(collider):
	if collider.get_parent() is Villager:
		is_gathered = true
		gatherer = collider.get_parent()
		dispense_timer.start()

func _on_area_exited(collider):
	if collider.get_parent() == gatherer:
		stop_storing()

# this logically belongs to the villager cause thats what he does actively

func stop_storing():
	is_gathered = false
	dispense_timer.stop()
	gatherer = null

func _on_gather_tick():
	if not is_gathered or gatherer == null:
		stop_storing()
		return
		
	if qty_stored < max_capacity and gatherer.qty_gathered > 0:
		qty_stored += 1
		gatherer.qty_gathered -= 1
		gatherer.update_gathered_resource_label()
		update_stored_resource_label()
	else:
		if gatherer != null and gatherer.cur_state == gatherer.STATES.STORING:
			gatherer.return_to_good_or_idle()
		stop_storing()
