extends Node2D
class_name Chest

@export var slot_count := 20
@export var chest_id: String = ""


var chest_inventory: Inv
var is_open := false

func _ready() -> void:
	chest_inventory = Inv.new()
	chest_inventory.slot_count = slot_count

	chest_inventory.slots.clear()
	for i in range(slot_count):
		var slot := InvSlot.new()
		slot.item = null
		slot.amount = 0
		chest_inventory.slots.append(slot)

	# Delay load until chest_id is set
	call_deferred("_deferred_load_contents")

func interact(_tool = null) -> void:
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui == null:
		return

	if inv_ui.is_open and inv_ui.is_container_open:
		save_contents()   # ✅ SAVE BEFORE CLOSING
		inv_ui.close()
	else:
		inv_ui.open_chest(chest_inventory)

func save_contents() -> void:
	if chest_id == "":
		push_warning("Chest has no chest_id set!")
		return

	var data: Array = []

	for slot in chest_inventory.slots:
		if slot == null:
			continue

		if slot.item != null and slot.amount > 0:
			data.append({
				"item_path": slot.item.resource_path,
				"amount": slot.amount
			})

	SaveDataGlobal.chests[chest_id] = data


func load_contents() -> void:
	if not SaveDataGlobal.chests.has(chest_id):
		return

	# Clear chest inventory safely
	for slot in chest_inventory.slots:
		if slot != null:
			slot.item = null
			slot.amount = 0

	# Refill from save
	for d in SaveDataGlobal.chests[chest_id]:
		var item := load(d.item_path) as InvItem
		if item == null:
			continue

		var amount := int(d.amount)

		# Find first empty slot
		for slot in chest_inventory.slots:
			if slot == null:
				continue

			if slot.item == null:
				slot.item = item
				slot.amount = amount
				break

func _deferred_load_contents() -> void:
	if chest_id == "":
		push_warning("Chest has no chest_id set!")
		return

	load_contents()
