extends Control
class_name InventoryUI

signal drop_item_to_world(item: InvItem, amount: int)
signal inventory_opened
signal inventory_closed

@onready var inv: Inv = preload("res://Inventory/PlayerInventory.tres")
@onready var slots: Array = []

var is_open = false
var picked_slot_index: int = -1  # -1 = nothing in hand

func _ready() -> void:
	slots.clear()
	slots.append_array($TextureRect/GridContainer.get_children())
	slots.append_array($TextureRect/GridContainer2.get_children())
	add_to_group("inventory_ui")

	inv.inventory_changed.connect(update_slots)

	for i in slots.size():
		slots[i].index = i

	update_slots()
	close()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		if is_open:
			close()
		else:
			open()

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()

func update_slots() -> void:
	for i in slots.size():
		var ui_slot = slots[i]
		var slot_data: InvSlot = null

		if i < inv.slots.size():
			slot_data = inv.slots[i] as InvSlot

		ui_slot.update(slot_data)

		if i == 0:
			ui_slot.set_hotkey_text("1")
		elif i == 1:
			ui_slot.set_hotkey_text("2")
		elif i == 2:
			ui_slot.set_hotkey_text("3")
		elif i == 3:
			ui_slot.set_hotkey_text("4")
		elif i == 4:
			ui_slot.set_hotkey_text("5")
		elif i == 5:
			ui_slot.set_hotkey_text("6")
		elif i == 6:
			ui_slot.set_hotkey_text("7")
		elif i == 7:
			ui_slot.set_hotkey_text("8")
		elif i == 8:
			ui_slot.set_hotkey_text("9")
		elif i == 9:
			ui_slot.set_hotkey_text("0")
		else:
			ui_slot.set_hotkey_text("")

func open():
	visible = true
	is_open = true
	inventory_opened.emit()

func close():
	visible = false
	is_open = false

	# clear drag globally
	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root:
		ui_root.stop_drag()
		picked_slot_index = -1

	inventory_closed.emit()

func on_slot_clicked(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= inv.slots.size():
		return

	var clicked_slot: InvSlot = inv.slots[slot_index]
	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root == null:
		return

	# 1) NOTHING IN HAND → PICK UP
	if picked_slot_index == -1:
		if clicked_slot == null or clicked_slot.item == null:
			return

		picked_slot_index = slot_index
		ui_root.start_drag(slot_index, clicked_slot)
		slots[picked_slot_index].set_item_visible(false)
		return

	# 2) CLICK SAME SLOT → CANCEL
	if picked_slot_index == slot_index:
		ui_root.stop_drag()
		slots[picked_slot_index].set_item_visible(true)
		picked_slot_index = -1
		return

	# 3) DRAG → DROP / SWAP
	var held_slot: InvSlot = inv.slots[picked_slot_index]
	inv.slots[picked_slot_index] = clicked_slot
	inv.slots[slot_index] = held_slot

	picked_slot_index = -1
	ui_root.stop_drag()
	inv.notify_changed()

func drop_held_item_to_world() -> void:
	if picked_slot_index == -1:
		return

	var held_slot: InvSlot = inv.slots[picked_slot_index]
	if held_slot == null or held_slot.item == null or held_slot.amount <= 0:
		return

	drop_item_to_world.emit(held_slot.item, held_slot.amount)

	held_slot.item = null
	held_slot.amount = 0

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root:
		ui_root.stop_drag()

	picked_slot_index = -1
	inv.notify_changed()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.is_pressed():
		if picked_slot_index != -1:
			drop_held_item_to_world()

func set_active_hotbar(index: int) -> void:
	_highlight_hotbar_slot(index)

func _highlight_hotbar_slot(index: int) -> void:
	for i in range(10):
		if i < slots.size():
			slots[i].set_hotkey_color(Color.WHITE)

	if index >= 0 and index < slots.size() and index < 10:
		slots[index].set_hotkey_color(Color.RED)
