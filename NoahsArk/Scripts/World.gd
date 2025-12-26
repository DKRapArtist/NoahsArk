extends Node2D
class_name World

@onready var current_area := $CurrentArea
@onready var inventory_ui := $Inventory/InventoryUI
@onready var item_scene := preload("res://PickUps/PickUpScenes/ItemPickUp.tscn")
var first_load := true

func _ready() -> void:
	add_to_group("world")
	load_area("res://Scenes/Areas/Home.tscn", "BedSpawn")
	inventory_ui.drop_item_to_world.connect(_on_item_dropped_from_inventory)

func _on_item_dropped_from_inventory(item: InvItem, amount: int) -> void:
	print("Dropping item:", item.name, "amount:", amount)
	var pickup := item_scene.instantiate()
	pickup.item = item
	pickup.amount = amount

	var player := get_tree().get_first_node_in_group("player")
	if player:
		pickup.global_position = player.global_position + Vector2(0, 16)
	else:
		print("No player in group 'player'!")
		pickup.global_position = Vector2.ZERO

	add_child(pickup)

func load_area(scene_path: String, spawn_id: String) -> void:
	if first_load:
		first_load = false
		# Only play the fade-in, don't await
		TransitionScene.fade_in_from_black()
	else:
		# Normal fade-out → fade-in
		TransitionScene.transition()
		await TransitionScene.on_transition_finished

	# 2. Remove old area
	for child in current_area.get_children():
		child.queue_free()

	await get_tree().process_frame

	# 3. Load new area
	var area: Node2D = load(scene_path).instantiate()
	current_area.add_child(area)

	await get_tree().process_frame

	var player := get_tree().get_first_node_in_group("player")
	var spawn := _find_spawn_in_area(area, spawn_id)

	if player and spawn:
		player.velocity = Vector2.ZERO
		player.global_position = spawn.global_position
		_set_camera_limits_from_area(player, area)
	else:
		push_warning("Spawn not found in area: " + spawn_id)


func _set_camera_limits_from_area(player: Node, area: Node) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam == null:
		print("No Camera2D on player")
		return

	var shape_node: CollisionShape2D = area.get_node_or_null("CameraBounds/CollisionShape2D")
	if shape_node == null:
		print("No CameraBounds/CollisionShape2D in area:", area.name)
		return

	var rect_shape: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect_shape == null:
		print("CameraBounds shape is not RectangleShape2D in area:", area.name)
		return

	var size: Vector2 = rect_shape.size
	var center: Vector2 = shape_node.global_position
	var half: Vector2 = size * 0.5

	print("Camera limits for", area.name, "size:", size, "center:", center)

	cam.limit_left = int(center.x - half.x)
	cam.limit_right = int(center.x + half.x)
	cam.limit_top = int(center.y - half.y)
	cam.limit_bottom = int(center.y + half.y)


func _find_spawn_in_area(area: Node, spawn_id: String) -> SpawnPoint:
	for child in area.get_children():
		if child is SpawnPoint and child.spawn_id == spawn_id:
			return child

		if child.get_child_count() > 0:
			var found := _find_spawn_in_area(child, spawn_id)
			if found:
				return found

	return null
