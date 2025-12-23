extends Control

@onready var inv: Inv = preload("res://Inventory/PlayerInventory.tres")
@onready var slots: Array = []

var is_open = false

func _ready() -> void:
	slots.clear()
	slots.append_array($TextureRect/GridContainer.get_children())
	slots.append_array($TextureRect/GridContainer2.get_children())

	update_slots()
	close()

func update_slots() -> void:
	for i in slots.size():
		var ui_slot = slots[i]
		var slot_data: InvSlot = null

		if i < inv.slots.size():
			slot_data = inv.slots[i] as InvSlot

		ui_slot.update(slot_data)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		if is_open:
			close()
		else:
			open()

func open():
	visible = true
	is_open = true

func close():
	visible = false
	is_open = false
