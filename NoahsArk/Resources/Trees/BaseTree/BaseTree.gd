extends Node2D
class_name BaseTree

@export var health := 3
@export var required_tool := "axe"
@export var wood_item: InvItem
@export var wood_amount := 2

func interact(tool: InvItem) -> void:
	if tool == null:
		return
	if tool.item_type != InvItem.ItemType.TOOL:
		return
	if tool.tool_type != required_tool:
		return

	health -= tool.power
	print("Log health:", health)

	if health <= 0:
		chop_down()

func chop_down() -> void:
	for i in range(wood_amount):
		spawn_wood()

	queue_free()

func spawn_wood() -> void:
	var pickup := preload("res://PickUps/PickUpScenes/ItemPickUp.tscn").instantiate()
	pickup.item = wood_item
	pickup.amount = 1
	pickup.use_auto_pickup_delay = false  # 👈 IMPORTANT
	get_parent().add_child(pickup)
	pickup.global_position = global_position + Vector2(
		randf_range(-8, 8),
		randf_range(-8, 8)
	)
