extends Area2D
class_name ItemPickup

@export var item: InvItem : set = _set_item
@export var amount: int = 1
@export var pickup_delay: float = 0.2
@export var auto_pickup_time: float = 3.0
@export var use_auto_pickup_delay: bool = true
@export var magnet_radius: float = 30.0
@export var magnet_speed: float = 250.0   # how fast the item flies to player

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var can_pickup: bool = false
var is_magnetized: bool = false

func _ready() -> void:
	_update_visual()

	# Find player once
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D

	# Only start the 3s timer if this instance wants it
	if use_auto_pickup_delay:
		_start_auto_pickup_timer()
	else:
		can_pickup = true  # world items are pickable immediately

func _physics_process(delta: float) -> void:
	if not can_pickup:
		return
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)

	if dist <= magnet_radius:
		is_magnetized = true

	if is_magnetized:
		var dir := (player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta

		if dist <= 8.0:
			try_pickup()

func _start_auto_pickup_timer() -> void:
	can_pickup = false
	await get_tree().create_timer(auto_pickup_time).timeout
	if not is_inside_tree():
		return
	can_pickup = true

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

func try_pickup() -> void:
	if item == null:
		return

	var inv_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui == null:
		return

	var inv: Inv = inv_ui.inv
	var remaining := amount

	# 1️⃣ STACK INTO EXISTING STACKS
	for i in range(inv.slots.size()):
		if remaining <= 0:
			break

		var slot := inv.slots[i]
		if slot == null:
			continue

		if slot.item == item:
			var space := item.max_stack - slot.amount
			if space > 0:
				var to_add = min(space, remaining)
				slot.amount += to_add
				remaining -= to_add

	# 2️⃣ FIRST AVAILABLE EMPTY SLOT
	for i in range(inv.slots.size()):
		if remaining <= 0:
			break

		if inv.slots[i] == null:
			var new_slot := InvSlot.new()
			new_slot.item = item
			new_slot.amount = min(item.max_stack, remaining)
			inv.slots[i] = new_slot
			remaining -= new_slot.amount

	# 3️⃣ FINISH UP
	if remaining <= 0:
		SFXManagerGlobal.play(
			"pickup" + str(randi_range(1, 4)),
			-4.0,
			randf_range(0.9, 1.1)
		)

		inv.notify_changed()
		queue_free()
	else:
		amount = remaining
		inv.notify_changed()
