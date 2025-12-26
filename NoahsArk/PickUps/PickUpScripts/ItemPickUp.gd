extends Area2D
class_name ItemPickup

@export var item: InvItem : set = _set_item
@export var amount: int = 1
@export var pickup_delay: float = 0.2

@onready var sprite: Sprite2D = $Sprite2D

var player_in_range: Node = null
var can_pickup: bool = false

func _ready() -> void:
	can_pickup = false
	await get_tree().create_timer(pickup_delay).timeout
	can_pickup = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

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
	if not can_pickup:
		return
	if body.is_in_group("player"):
		player_in_range = body
		try_pickup()

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
	var remaining := amount

	# 1) Try stacking onto existing slots
	for slot_data in inv.slots:
		if remaining <= 0:
			break

		var slot: InvSlot = slot_data as InvSlot
		if slot == null:
			continue

		if slot.item == item:
			var max_stack := item.max_stack
			var space := max_stack - slot.amount
			if space > 0:
				var to_add: int = min(space, remaining)
				slot.amount += to_add
				remaining -= to_add

	# 2) Fill empty slots
	for slot_data in inv.slots:
		if remaining <= 0:
			break

		var slot: InvSlot = slot_data as InvSlot
		if slot == null:
			continue

		if slot.item == null:
			slot.item = item
			var to_add: int = min(item.max_stack, remaining)
			slot.amount = to_add
			remaining -= to_add

	# 3) Finish
	if remaining <= 0:
		inv_ui.update_slots()
		queue_free()
	else:
		amount = remaining
		inv_ui.update_slots()
		print("Inventory full; still", remaining, "of", item.name, "left on ground")
