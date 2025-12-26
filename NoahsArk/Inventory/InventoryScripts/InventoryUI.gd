extends Control

signal drop_item_to_world(item: InvItem, amount: int)

@onready var inv: Inv = preload("res://Inventory/PlayerInventory.tres")
@onready var slots: Array = []
@onready var drag_icon: TextureRect = $DragIcon

var is_open = false
var picked_slot_index: int = -1  # -1 = nothing in hand
var is_dragging: bool = false

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
	if not is_open:
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.is_pressed() == false:
		# Mouse released outside UI (slots didn’t handle it)
		if picked_slot_index != -1:
			drop_held_item_to_world()
