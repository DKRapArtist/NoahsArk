extends Control
class_name InventoryUI

signal drop_item_to_world(item: InvItem, amount: int)

@onready var inv: Inv = preload("res://Inventory/PlayerInventory.tres")
@onready var slots: Array = []
@onready var drag_icon: TextureRect = $DragIcon

var is_open = false
var picked_slot_index: int = -1  # -1 = nothing in hand
var is_dragging: bool = false
var active_hotbar_index: int = -1

func _ready() -> void:
	slots.clear()
	slots.append_array($TextureRect/GridContainer.get_children())
	slots.append_array($TextureRect/GridContainer2.get_children())

	# Assign indices to UI slots to match inv.slots
	for i in slots.size():
		slots[i].index = i

	drag_icon.visible = false
	update_slots()
	close()

func _process(_delta: float) -> void:
	# Toggle with your existing action (e.g. "inventory_toggle")
	if Input.is_action_just_pressed("inventory_toggle"):
		if is_open:
			close()
		else:
			open()

	# Close with Esc (ui_cancel)
	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()

	if is_dragging:
		_update_drag_icon_position()

func update_slots() -> void:
	for i in slots.size():
		var ui_slot = slots[i]
		var slot_data: InvSlot = null

		if i < inv.slots.size():
			slot_data = inv.slots[i] as InvSlot

		ui_slot.update(slot_data)

		# Hotkey numbers only on first 10 slots (0–9)
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

func close():
	visible = false
	is_open = false
	picked_slot_index = -1
	_stop_drag_icon()

func on_slot_clicked(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= inv.slots.size():
		return

	var clicked_slot: InvSlot = inv.slots[slot_index]

	# No item in hand -> pick up
	if picked_slot_index == -1:
		if clicked_slot == null or clicked_slot.item == null:
			return

		picked_slot_index = slot_index
		_start_drag_icon(clicked_slot)

		# Hide original slot visuals ONCE
		slots[picked_slot_index].set_item_visible(false)
		return

	# Clicking the same slot -> cancel drag and show it again
	if picked_slot_index == slot_index:
		_stop_drag_icon()
		slots[picked_slot_index].set_item_visible(true)
		picked_slot_index = -1
		return

	# Different slot -> swap
	var held_slot: InvSlot = inv.slots[picked_slot_index]
	inv.slots[picked_slot_index] = clicked_slot
	inv.slots[slot_index] = held_slot

	picked_slot_index = -1
	_stop_drag_icon()
	update_slots()

func _start_drag_icon(slot: InvSlot) -> void:
	if slot == null or slot.item == null:
		return

	drag_icon.texture = slot.item.texture
	drag_icon.visible = true
	is_dragging = true
	_update_drag_icon_position()

func _stop_drag_icon() -> void:
	drag_icon.visible = false
	is_dragging = false

func _update_drag_icon_position() -> void:
	# Mouse position relative to this Control
	var mouse_pos = get_local_mouse_position()
	drag_icon.position = mouse_pos - drag_icon.size * 0.5

func drop_held_item_to_world() -> void:
	if picked_slot_index == -1:
		return

	var held_slot: InvSlot = inv.slots[picked_slot_index]
	if held_slot == null or held_slot.item == null or held_slot.amount <= 0:
		return

	# Emit signal so your world node can spawn a dropped item
	drop_item_to_world.emit(held_slot.item, held_slot.amount)

	# Clear the slot in the inventory
	held_slot.item = null
	held_slot.amount = 0

	# Reset drag state and UI
	picked_slot_index = -1
	_stop_drag_icon()
	update_slots()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse release logic should stay gated by is_open
	if is_open:
		if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed() == false:
			if picked_slot_index != -1:
				drop_held_item_to_world()

	# Hotbar keys should work regardless of inventory visibility
	if event.is_pressed():
		if Input.is_action_just_pressed("hotbar_1"):
			_use_hotbar_slot(1)
		elif Input.is_action_just_pressed("hotbar_2"):
			_use_hotbar_slot(2)
		elif Input.is_action_just_pressed("hotbar_3"):
			_use_hotbar_slot(3)
		elif Input.is_action_just_pressed("hotbar_4"):
			_use_hotbar_slot(4)
		elif Input.is_action_just_pressed("hotbar_5"):
			_use_hotbar_slot(5)
		elif Input.is_action_just_pressed("hotbar_6"):
			_use_hotbar_slot(6)
		elif Input.is_action_just_pressed("hotbar_7"):
			_use_hotbar_slot(7)
		elif Input.is_action_just_pressed("hotbar_8"):
			_use_hotbar_slot(8)
		elif Input.is_action_just_pressed("hotbar_9"):
			_use_hotbar_slot(9)
		elif Input.is_action_just_pressed("hotbar_0"):
			_use_hotbar_slot(0)

func _use_hotbar_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= inv.slots.size():
		return

	var slot: InvSlot = inv.slots[slot_index]
	if slot == null or slot.item == null or slot.amount <= 0:
		return

	active_hotbar_index = slot_index
	print("Hotbar slot", slot_index, "selected:", slot.item.name)

	# Example: call a method on the player to equip/use
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_hotbar_item_selected"):
		player.on_hotbar_item_selected(slot.item, slot_index)
