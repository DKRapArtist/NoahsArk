extends Area2D
class_name ItemPickup

@export var item: InvItem : set = _set_item

@onready var sprite: Sprite2D = $Sprite2D

var player_in_range: Node = null

func _ready() -> void:
	# Ensure the sprite matches the current item when the scene spawns.
	_update_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _set_item(new_item: InvItem) -> void:
	item = new_item
	_update_visual()

func _update_visual() -> void:
	if sprite == null:
		return
	if item == null:
		sprite.visible = false
	else:
		sprite.visible = true
		sprite.texture = item.texture

func _on_body_entered(body: Node) -> void:
	print("Pickup body_entered:", body)
	if body.is_in_group("player"):
		player_in_range = body
		try_pickup()  # ← auto-pickup

func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null

func try_pickup() -> void:
	if player_in_range == null or item == null:
		return

	var inv_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui == null:
		return

	var inv: Inv = inv_ui.inv

	# 1) First, try to stack onto existing slots with same item
	for slot_data in inv.slots:
		var slot: InvSlot = slot_data as InvSlot
		if slot == null:
			continue

		if slot.item == item:
			# If you use max_stack
			var max_stack := item.max_stack
			if slot.amount < max_stack:
				slot.amount += 1
				inv_ui.update_slots()
				queue_free()
				return
			# if full, keep looking

	# 2) If no stack found or all stacks are full, use first empty slot
	for slot_data in inv.slots:
		var slot: InvSlot = slot_data as InvSlot
		if slot == null:
			continue

		if slot.item == null:
			slot.item = item
			slot.amount = 1
			inv_ui.update_slots()
			queue_free()
			return

	# 3) No space
	print("Inventory full; cannot pick up", item.name)


	print("No empty slot for", item.name)
