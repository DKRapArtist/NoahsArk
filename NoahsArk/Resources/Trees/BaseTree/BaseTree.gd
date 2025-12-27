extends Area2D
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
		print("Wrong tool")
		return

	health -= tool.power

	if health <= 0:
		chop_down()

func chop_down():
	for i in wood_amount:
		var pickup := preload("res://PickUps/PickUpScenes/ItemPickUp.tscn").instantiate()
		pickup.item = wood_item
		get_parent().add_child(pickup)
		pickup.global_position = global_position + Vector2(randf()*8, randf()*8)

	queue_free()
