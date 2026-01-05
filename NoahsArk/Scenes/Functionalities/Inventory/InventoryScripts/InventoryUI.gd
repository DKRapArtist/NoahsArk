extends Control
class_name InventoryUI

signal drop_item_to_world(item: InvItem, amount: int)
signal inventory_opened
signal inventory_closed

@onready var inv: Inv = preload("res://Scenes/Functionalities/Inventory/PlayerInventory.tres")
@onready var slots: Array = []

var is_open = false
var picked_slot_index: int = -1  # -1 = nothing in hand
var held_amount: int = 0
var held_item: InvItem = null
var held_total: int = 0  # total stack in hand
var is_split_drag: bool = false
var split_total: int = 0
var split_preview_remainder

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

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root == null:
		return

	var clicked_slot: InvSlot = inv.slots[slot_index]

# 1) NOTHING IN HAND → PICK UP FULL STACK
	if picked_slot_index == -1:
		if clicked_slot == null or clicked_slot.item == null or clicked_slot.amount <= 0:
			return

		picked_slot_index = slot_index
		held_item = clicked_slot.item
		held_total = clicked_slot.amount
		held_amount = held_total

		# 🔒 HARD RESET SPLIT STATE
		is_split_drag = false
		split_total = 0
		split_preview_remainder = -1

		inv.slots[slot_index] = null

		ui_root.start_drag(slot_index, clicked_slot)
		ui_root.set_drag_amount(held_amount)
		inv.notify_changed()
		return

	# If we get here, we are holding something
	if held_item == null or held_total <= 0:
		return

	var target_slot: InvSlot = inv.slots[slot_index]

	# 2) CLICK SAME SLOT OR ANY SLOT → STACK / PLACE
	# Create slot if empty
	if target_slot == null or target_slot.item == null:
		target_slot = InvSlot.new()
		target_slot.item = held_item
		target_slot.amount = 0
		inv.slots[slot_index] = target_slot

	# If different item, do nothing (no swap implemented)
	if target_slot.item != held_item:
		return

	# Stack into target
	var max_stack := held_item.max_stack
	var space := max_stack - target_slot.amount
	if space <= 0:
		return

	var move = min(space, held_amount)   # place selected amount
	move = min(move, held_total)          # never exceed what we have

	target_slot.amount += move
	held_total -= move

	# adjust selected amount after placing
	if held_total <= 0:
		# hand empty → end drag
		ui_root.stop_drag()
		picked_slot_index = -1
		held_item = null
		held_total = 0
		held_amount = 0
	else:
		held_amount = clamp(held_amount, 1, held_total)
		ui_root.set_drag_amount(held_amount)

	inv.notify_changed()

func drop_held_item_to_world() -> void:
	if held_item == null or held_total <= 0 or held_amount <= 0:
		return

	var drop_amount = min(held_amount, held_total)
	drop_item_to_world.emit(held_item, drop_amount)

	held_total -= drop_amount

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root:
		if held_total <= 0:
			ui_root.stop_drag()
		else:
			held_amount = clamp(held_amount, 1, held_total)
			ui_root.set_drag_amount(held_amount)

	if held_total <= 0:
		picked_slot_index = -1
		held_item = null
		held_total = 0
		held_amount = 0

	inv.notify_changed()

func _unhandled_input(event: InputEvent) -> void:
	# MOUSE WHEEL — change held amount
	if picked_slot_index != -1 and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_change_held_amount(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_change_held_amount(-1)

	# DROP TO WORLD — ALWAYS allowed when releasing mouse
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

func _change_held_amount(delta: int) -> void:
	# ✅ Wheel ONLY works while split-dragging (right click)
	if not is_split_drag:
		return

	# Safety
	if held_item == null or picked_slot_index < 0 or picked_slot_index >= inv.slots.size():
		return

	var slot := inv.slots[picked_slot_index]
	if slot == null or slot.item != held_item:
		return

	# split_total is the original stack size (hand + slot must always equal this)
	var new_hand = clamp(held_amount + delta, 1, split_total - 1) # keep at least 1 in slot
	if new_hand == held_amount:
		return

	held_amount = new_hand
	held_total = held_amount

	# ✅ ACTUALLY update the inventory remainder
	slot.amount = split_total - held_amount
	if slot.amount <= 0:
		inv.slots[picked_slot_index] = null

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root:
		ui_root.set_drag_amount(held_amount)

	inv.notify_changed()

func on_slot_right_clicked(slot_index: int) -> void:
	if picked_slot_index != -1:
		return

	if slot_index < 0 or slot_index >= inv.slots.size():
		return

	var slot := inv.slots[slot_index]
	if slot == null or slot.item == null or slot.amount <= 1:
		return

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root == null:
		return

	# ✅ Remember original total (constant during split scroll)
	split_total = slot.amount
	is_split_drag = true

	var take := int(ceil(split_total / 2.0))

	# hand owns taken amount
	picked_slot_index = slot_index
	held_item = slot.item
	held_total = take
	held_amount = take

	# slot keeps remainder (ACTUAL inventory update)
	slot.amount = split_total - take
	if slot.amount <= 0:
		inv.slots[slot_index] = null

	inv.notify_changed()

	var drag_slot := InvSlot.new()
	drag_slot.item = held_item
	drag_slot.amount = held_total
	ui_root.start_drag(slot_index, drag_slot)
	ui_root.set_drag_amount(held_amount)
