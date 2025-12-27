extends Control
class_name HotBarUI

@export var inv: Inv
@onready var slots := $Background/GridContainer.get_children()

var active_index := -1

func _ready():
	add_to_group("hotbar_ui")

	if inv == null:
		push_error("HotbarUI.inv not assigned")
		return

	inv.inventory_changed.connect(update_hotbar)

	var inv_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		inv_ui.inventory_opened.connect(_on_inventory_opened)
		inv_ui.inventory_closed.connect(_on_inventory_closed)

	update_hotbar()

func update_hotbar():
	for i in slots.size():
		var slot_data: InvSlot = null
		if i < inv.slots.size():
			slot_data = inv.slots[i]

		slots[i].update(slot_data)
		slots[i].set_hotkey_text(str((i + 1) % 10))

func set_active_slot(index: int):
	active_index = index

	for i in slots.size():
		slots[i].set_hotkey_color(Color.WHITE)

	if index >= 0 and index < slots.size():
		slots[index].set_hotkey_color(Color.RED)

func _on_inventory_opened():
	visible = false

func _on_inventory_closed():
	visible = true
