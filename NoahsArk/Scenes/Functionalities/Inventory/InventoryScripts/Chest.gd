extends Node2D
class_name Chest

@export var slot_count := 20

var chest_inventory: Inv
var is_open := false

func _ready() -> void:
	chest_inventory = Inv.new()
	chest_inventory.slot_count = slot_count

	# IMPORTANT: initialize slots array
	chest_inventory.slots.resize(slot_count)
	print("Chest slots size:", chest_inventory.slots.size())

	chest_inventory.ensure_clean_slots()

func interact(_tool = null) -> void:
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui == null:
		return

	if inv_ui.is_open and inv_ui.is_container_open:
		inv_ui.close()
	else:
		inv_ui.open_chest(chest_inventory)
