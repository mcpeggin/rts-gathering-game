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

enum TYPES {WOOD, STONE, FOOD}
@export var type: TYPES

var is_gathered := false
var gatherer = null

# label above good
var qty_available: int
var max_capacity: int

func _ready():
	super._ready() # call AbstractSelectableStatic first, so shit works
	add_to_group("goods")
	add_to_group("trees")
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
		if gatherer != null and gatherer.cur_state == gatherer.STATES.GATHERING:
			gatherer.on_good_depleted()
		stop_gathering()
		body.visible = false
		dead_body.visible = true
		resource_counter.visible = false
		turn_off_area()

func _on_area_entered(collider):
	if collider.get_parent() is Villager:
		is_gathered = true
		gatherer = collider.get_parent()
		gather_timer.start()

func _on_area_exited(collider):
	if collider.get_parent() == gatherer:
		stop_gathering()

# this logically belongs to the villager cause thats what he does actively

func stop_gathering():
	is_gathered = false
	gather_timer.stop()
	gatherer = null

func _on_gather_tick():
	if not is_gathered or gatherer == null:
		stop_gathering()
		return
		
	if qty_available > 0 and gatherer.qty_gathered < gatherer.max_capacity:
		qty_available -= 1
		gatherer.qty_gathered += 1
		gatherer.update_gathered_resource_label()
		update_available_resource_label()
	else:
		if gatherer != null and gatherer.cur_state == gatherer.STATES.GATHERING:
			gatherer.go_to_storage()
		stop_gathering()
