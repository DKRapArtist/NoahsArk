extends Control
class_name InventoryUI

signal drop_item_to_world(item: InvItem, amount: int)
signal inventory_opened
signal inventory_closed

var inv: Inv
@onready var player_slots: Array = []
@onready var chest_slots: Array = []

var is_open = false
var picked_slot_index: int = -1  # -1 = nothing in hand
var held_amount: int = 0
var held_item: InvItem = null
var held_total: int = 0  # total stack in hand
var is_split_drag: bool = false
var split_total: int = 0
var split_preview_remainder
var player_inv: Inv
var container_inv: Inv = null
var is_container_open := false

func _ready() -> void:
	# --- PLAYER INVENTORY ---
	player_inv = preload("res://Scenes/Functionalities/Inventory/PlayerInventory.tres")
	set_inventory(player_inv)

	add_to_group("inventory_ui")

	# --- SLOT COLLECTION ---
	player_slots.clear()
	chest_slots.clear()

	# Player inventory slots
	player_slots.append_array($TextureRect/PlayerGrid.get_children())
	player_slots.append_array($TextureRect/HotbarGrid.get_children())

	# Chest inventory slots
	chest_slots.append_array($ChestBackground/ChestGrid.get_children())

	# --- TOOLTIP ---
	var tooltip := $ItemToolTip
	for slot in player_slots:
		slot.tooltip = tooltip
		slot.is_chest_slot = false

	for slot in chest_slots:
		slot.tooltip = tooltip
		slot.is_chest_slot = true
		slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# --- SLOT INDEXING ---
	for i in player_slots.size():
		player_slots[i].index = i

	for i in chest_slots.size():
		chest_slots[i].index = i

	update_slots()
	close()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		if is_open:
			close()
		else:
			open()

func update_slots() -> void:
	# --------------------
	# PLAYER INVENTORY (HOTBAR + MAIN)
	# --------------------
	for i in player_slots.size():
		var ui_slot = player_slots[i]
		var slot_data: InvSlot = null

		if player_inv and i < player_inv.slots.size():
			slot_data = player_inv.slots[i]

		ui_slot.update(slot_data)

		# Hotbar numbers (first 10 slots only)
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

	# --------------------
	# CHEST INVENTORY
	# --------------------
	for i in chest_slots.size():
		var ui_slot = chest_slots[i]
		var slot_data: InvSlot = null

		if is_container_open and container_inv and i < container_inv.slots.size():
			slot_data = container_inv.slots[i]

		ui_slot.update(slot_data)

func open():
	visible = true
	is_open = true
	inventory_opened.emit()

func close():
	visible = false
	is_open = false

	var tooltip := $ItemToolTip
	if tooltip:
		tooltip.hide_tooltip()

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root:
		ui_root.stop_drag()

	# 🔁 CLOSE CHEST MODE
	if is_container_open:
		if container_inv and container_inv.inventory_changed.is_connected(update_slots):
			container_inv.inventory_changed.disconnect(update_slots)

		container_inv = null
		is_container_open = false
		$ChestBackground.visible = false

	inventory_closed.emit()

func on_slot_clicked(slot_index: int, ui_slot = null) -> void:
	# 🔁 SHIFT-CLICK QUICK TRANSFER (ONLY when not holding anything)
	if picked_slot_index == -1 and Input.is_key_pressed(KEY_SHIFT):
		# Only do quick transfer if a chest/container is actually open
		if is_container_open and container_inv != null and ui_slot != null:
			if ui_slot.is_chest_slot:
				# Chest → Player
				_transfer_slot_between_inventories(
					container_inv,
					player_inv,
					slot_index
				)
				return
			else:
				# Player → Chest
				_transfer_slot_between_inventories(
					player_inv,
					container_inv,
					slot_index
				)
				return
		# If no chest is open, SHIFT-click should behave like a normal click (so we do NOT return)

	var target_inv: Inv

	# --------------------
	# DETERMINE INVENTORY
	# --------------------
	if ui_slot and ui_slot.is_chest_slot:
		if not is_container_open or container_inv == null:
			return
		target_inv = container_inv
	else:
		target_inv = player_inv

	if slot_index < 0 or slot_index >= target_inv.slots.size():
		return

	var ui_root := get_tree().get_first_node_in_group("ui_root") as UIRoot
	if ui_root == null:
		return

	var clicked_slot: InvSlot = target_inv.slots[slot_index]

	# 1️⃣ NOTHING IN HAND → PICK UP
	if picked_slot_index == -1:
		if clicked_slot == null:
			return

		picked_slot_index = slot_index
		held_item = clicked_slot.item
		held_total = clicked_slot.amount
		held_amount = held_total

		target_inv.slots[slot_index] = null
		ui_root.start_drag(slot_index, clicked_slot)
		ui_root.set_drag_amount(held_amount)
		target_inv.notify_changed()
		return

	# 2️⃣ HOLDING SOMETHING
	if held_item == null or held_total <= 0:
		return

	var target_slot := target_inv.slots[slot_index]

	# 🟩 EMPTY SLOT → PLACE
	if target_slot == null:
		var new_slot := InvSlot.new()
		new_slot.item = held_item
		new_slot.amount = held_total
		target_inv.slots[slot_index] = new_slot

		ui_root.stop_drag()
		picked_slot_index = -1
		held_item = null
		held_total = 0
		held_amount = 0

		target_inv.notify_changed()
		return

	# 🟨 SAME ITEM → STACK
	if target_slot.item == held_item:
		var space := held_item.max_stack - target_slot.amount
		if space > 0:
			var move = min(space, held_total)
			target_slot.amount += move
			held_total -= move

			if held_total <= 0:
				ui_root.stop_drag()
				picked_slot_index = -1
				held_item = null
				held_total = 0
				held_amount = 0
			else:
				held_amount = held_total
				ui_root.set_drag_amount(held_amount)

			target_inv.notify_changed()
		return

	# 🔁 TRUE SLOT-TO-SLOT SWAP
	var original_slot := InvSlot.new()
	original_slot.item = held_item
	original_slot.amount = held_total

	var temp_slot := target_slot

	target_inv.slots[picked_slot_index] = temp_slot
	target_inv.slots[slot_index] = original_slot

	picked_slot_index = -1
	held_item = null
	held_total = 0
	held_amount = 0

	if ui_root:
		ui_root.stop_drag()

	target_inv.notify_changed()

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
	# Reset hotbar colors (first 10 player slots)
	for i in range(min(10, player_slots.size())):
		player_slots[i].set_hotkey_color(Color.WHITE)

	# Highlight selected
	if index >= 0 and index < min(10, player_slots.size()):
		player_slots[index].set_hotkey_color(Color.RED)

func _change_held_amount(delta: int) -> void:
	if not is_split_drag:
		return

	if held_item == null or picked_slot_index < 0 or picked_slot_index >= inv.slots.size():
		return

	var slot := inv.slots[picked_slot_index]
	if slot == null or slot.item != held_item:
		return

	var new_hand = clamp(held_amount + delta, 1, split_total - 1)
	if new_hand == held_amount:
		return

	held_amount = new_hand
	held_total = held_amount

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

	split_total = slot.amount
	is_split_drag = true

	var take := int(ceil(split_total / 2.0))

	picked_slot_index = slot_index
	held_item = slot.item
	held_total = take
	held_amount = take

	slot.amount = split_total - take
	if slot.amount <= 0:
		inv.slots[slot_index] = null

	inv.notify_changed()

	var drag_slot := InvSlot.new()
	drag_slot.item = held_item
	drag_slot.amount = held_total
	ui_root.start_drag(slot_index, drag_slot)
	ui_root.set_drag_amount(held_amount)

func combine_item_stacks(slot_index: int) -> void:
	if picked_slot_index != -1:
		return

	if slot_index < 0 or slot_index >= inv.slots.size():
		return

	var base_slot := inv.slots[slot_index]
	if base_slot == null:
		return

	var item := base_slot.item
	var max_stack := item.max_stack

	var total := 0
	for i in range(inv.slots.size()):
		var slot := inv.slots[i]
		if slot != null and slot.item == item:
			total += slot.amount
			inv.slots[i] = null

	var remaining := total

	var first_amount = min(max_stack, remaining)
	var new_base := InvSlot.new()
	new_base.item = item
	new_base.amount = first_amount
	inv.slots[slot_index] = new_base
	remaining -= first_amount

	for i in range(inv.slots.size()):
		if remaining <= 0:
			break
		if inv.slots[i] != null:
			continue

		var to_add = min(max_stack, remaining)
		var new_slot := InvSlot.new()
		new_slot.item = item
		new_slot.amount = to_add
		inv.slots[i] = new_slot
		remaining -= to_add

	inv.notify_changed()

func set_inventory(new_inv: Inv) -> void:
	if inv:
		inv.inventory_changed.disconnect(update_slots)

	inv = new_inv
	inv.ensure_clean_slots()
	inv.inventory_changed.connect(update_slots)
	update_slots()

func _update_inventory_slots(source_inv: Inv, ui_slots: Array) -> void:
	for i in ui_slots.size():
		var slot_data: InvSlot = null
		if source_inv and i < source_inv.slots.size():
			slot_data = source_inv.slots[i]
		ui_slots[i].update(slot_data)

func open_container(container: Inv) -> void:
	container_inv = container
	is_container_open = true

	container_inv.ensure_clean_slots()
	container_inv.inventory_changed.connect(update_slots)

	update_slots()
	open()

func open_chest(container: Inv) -> void:
	container_inv = container
	is_container_open = true

	$ChestBackground.visible = true

	container_inv.ensure_clean_slots()
	container_inv.inventory_changed.connect(update_slots)

	update_slots()
	open()

func _transfer_slot_between_inventories(
	from_inv: Inv,
	to_inv: Inv,
	slot_index: int
) -> void:
	if from_inv == null or to_inv == null:
		return
	if slot_index < 0 or slot_index >= from_inv.slots.size():
		return

	var slot := from_inv.slots[slot_index]
	if slot == null:
		return

	var item := slot.item
	var amount := slot.amount

	# 1️⃣ Try stacking first
	for i in range(to_inv.slots.size()):
		var target := to_inv.slots[i]
		if target and target.item == item:
			var space := item.max_stack - target.amount
			if space > 0:
				var move = min(space, amount)
				target.amount += move
				amount -= move
				if amount <= 0:
					from_inv.slots[slot_index] = null
					from_inv.notify_changed()
					to_inv.notify_changed()
					return

	# 2️⃣ Put remaining into empty slots
	for i in range(to_inv.slots.size()):
		if to_inv.slots[i] == null:
			var new_slot := InvSlot.new()
			new_slot.item = item
			new_slot.amount = amount
			to_inv.slots[i] = new_slot
			from_inv.slots[slot_index] = null
			from_inv.notify_changed()
			to_inv.notify_changed()
			return
