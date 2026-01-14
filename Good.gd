@tool
class_name Good extends AbstractSelectableStatic

@onready var resource_counter: Label = $Body/ResourceCounter
@onready var gather_timer: Timer = $GatherTimer

@onready var body: Sprite2D = $Body
@onready var dead_body: Sprite2D = $DeadBody

@export var qty: int:
	set(value):
		qty = value
		max_capacity = qty
		qty_available = max_capacity
		if is_node_ready():
			update_available_resource_label()

enum TYPES {
	WOOD, 
	STONE, 
	WHEET
}

@export var type: TYPES

var is_gathered := false
var gatherers = []

# label above good
var qty_available: int
var max_capacity: int

func _ready():
	super._ready() # call AbstractSelectableStatic first, so shit works
	add_to_group("goods")
	max_capacity = qty
	qty_available = max_capacity
	
	update_available_resource_label()
	
	area.connect("area_entered", _on_area_entered)
	area.connect("area_exited", _on_area_exited)
	
	gather_timer.timeout.connect(_on_gather_tick)

# the rest of the indication logic is in abstract, this one is here cause vilalgers mentioned,
# which means it is already messed up

func _input(event):
	super._input(event)
	
	if get_tree().get_nodes_in_group('selected_villagers').size() > 0:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if is_hover:
				var selected = get_tree().get_nodes_in_group('selected_villagers')
				for villager in selected:
					villager.assign_good(self)

func update_available_resource_label():
	resource_counter.text = "%d / %d" % [qty_available, max_capacity]
	
	if qty_available == 0:
		for gatherer in gatherers:
			gatherer.on_good_depleted()
		gatherers.clear()
		stop_gathering()
		body.visible = false
		dead_body.visible = true
		resource_counter.visible = false
		turn_off_area()

func _on_area_entered(collider):
	if collider.get_parent() is Villager:
		var villager = collider.get_parent()
		if villager not in gatherers:
			gatherers.append(villager)
		is_gathered = true
		gather_timer.start()

func _on_area_exited(collider):
	if collider.get_parent() is Villager:
		gatherers.erase(collider.get_parent())
		if gatherers.is_empty():
			stop_gathering()

# this logically belongs to the villager cause thats what he does actively

func stop_gathering():
	is_gathered = false
	gather_timer.stop()

func _on_gather_tick():
	if gatherers.is_empty():
		stop_gathering()
		return
	
	var gatherers_to_remove = []
	for gatherer in gatherers:
		if qty_available <= 0:
			break
		if gatherer.qty_gathered < gatherer.max_capacity:
			qty_available -= 1
			gatherer.qty_gathered += 1
			gatherer.update_gathered_resource_label()
		else:
			if gatherer.cur_state == gatherer.STATES.GATHERING:
				gatherer.go_to_storage()
			gatherers_to_remove.append(gatherer)
		
	for gatherer in gatherers_to_remove:
		gatherers.erase(gatherer)
	
	update_available_resource_label()
