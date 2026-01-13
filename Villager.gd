class_name Villager extends AbstractSelectableUnit

@onready var resource_counter: Label = $Body/ResourceCapacity

@export var max_capacity: int

var qty_gathered: int

func _ready():
	super._ready() # call AbstractSelectableUnit first, so shit works
	qty_gathered = 0
	update_gathered_resource_label()

func update_gathered_resource_label():
	resource_counter.text = "%d / %d" % [qty_gathered, max_capacity]
