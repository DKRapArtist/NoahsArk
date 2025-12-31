extends Node2D
class_name World

@onready var current_area := $AreaRoot/CurrentArea
@onready var pickups_root: Node2D = $YSort/PickupsRoot
@onready var inventory_ui := $UIRoot/InventoryUI

@onready var item_scene := preload("res://PickUps/PickUpScenes/ItemPickUp.tscn")

var first_load := true

# ✅ MOVE GROUP REGISTRATION HERE
func _enter_tree() -> void:
	add_to_group("world")

func _ready() -> void:
	load_area("res://Scenes/Areas/Home.tscn", "BedSpawn")

	inventory_ui = get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inventory_ui:
		inventory_ui.drop_item_to_world.connect(_on_item_dropped_from_inventory)
	else:
		push_error("World: InventoryUI not found in group 'inventory_ui'")


func _on_item_dropped_from_inventory(item: InvItem, amount: int) -> void:
	var pickup := item_scene.instantiate() as ItemPickup
	pickup.item = item
	pickup.amount = amount

	pickup.use_auto_pickup_delay = true
	pickup.auto_pickup_time = 3.0

	var player := get_tree().get_first_node_in_group("player")
	if player:
		pickup.global_position = player.global_position + Vector2(0, 16)
	else:
		pickup.global_position = Vector2.ZERO

	pickups_root.add_child(pickup)


func load_area(scene_path: String, spawn_id: String) -> void:
	if first_load:
		first_load = false
		TransitionScene.fade_in_from_black()
	else:
		TransitionScene.transition()
		await TransitionScene.on_transition_finished

	# Remove old area
	for child in current_area.get_children():
		child.queue_free()

	# Remove world objects from YSort (trees + houses)
	for node in $YSort.get_children():
		if node.is_in_group("trees") \
		or node.is_in_group("house_base") \
		or node.is_in_group("house_roof"):
			node.queue_free()

	await get_tree().process_frame

	# Load new area
	var area: Node2D = load(scene_path).instantiate()
	current_area.add_child(area)

	await get_tree().process_frame

	# Move buildings (base + roof) into YSort
	_move_buildings_to_world(area)

	var player := get_tree().get_first_node_in_group("player")
	var spawn := _find_spawn_in_area(area, spawn_id)

	if player and spawn:
		player.velocity = Vector2.ZERO
		player.global_position = spawn.global_position
		_set_camera_limits_from_area(player, area)
	else:
		push_warning("Spawn not found in area: " + spawn_id)

func _move_buildings_to_world(node: Node) -> void:
	for child in node.get_children():
		if child.is_in_group("houses"):
			var base := child.get_node("HouseBase")
			var roof := child.get_node("HouseRoof")

			var base_pos = base.global_position
			var roof_pos = roof.global_position

			base.reparent($YSort)
			roof.reparent($YSort)

			base.global_position = base_pos
			roof.global_position = roof_pos

			child.queue_free() # editor-only wrapper
		else:
			_move_buildings_to_world(child)


func _set_camera_limits_from_area(player: Node, area: Node) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam == null:
		return

	var shape_node: CollisionShape2D = area.get_node_or_null("CameraBounds/CollisionShape2D")
	if shape_node == null:
		return

	var rect_shape: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return

	var size: Vector2 = rect_shape.size
	var center: Vector2 = shape_node.global_position
	var half: Vector2 = size * 0.5

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

func request_tree_respawn(scene_path: String, spawn_pos: Vector2, delay: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = delay
	add_child(timer)

	timer.timeout.connect(func():
		if not FileAccess.file_exists(scene_path):
			timer.queue_free()
			return

		var tree_scene := load(scene_path)
		var tree = tree_scene.instantiate()

		$YSort.add_child(tree)
		tree.global_position = spawn_pos

		timer.queue_free()
	)

	timer.start()
