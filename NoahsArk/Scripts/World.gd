extends Node2D
class_name World

@onready var current_area = $CurrentArea

func _ready():
	add_to_group("world")

func load_area(scene_path: String, spawn_id: String):
	# Remove old area
	for child in current_area.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Load new area
	var area = load(scene_path).instantiate()
	current_area.add_child(area)

	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	var spawn = _find_spawn_in_area(area, spawn_id)

	if player and spawn:
		player.velocity = Vector2.ZERO
		player.global_position = spawn.global_position
	else:
		push_warning("Spawn not found in area: " + spawn_id)

func _find_spawn_in_area(area: Node, spawn_id: String) -> SpawnPoint:
	print("=== SEARCHING IN:", area.name, "FOR:", spawn_id)

	for child in area.get_children():
		print("Node:", child.name, "Type:", child.get_class())

		if child is SpawnPoint:
			print("  -> spawn_id =", child.spawn_id)

			if child.spawn_id == spawn_id:
				print("  ✅ MATCH")
				return child

		if child.get_child_count() > 0:
			var found = _find_spawn_in_area(child, spawn_id)
			if found:
				return found

	print("❌ NO MATCH IN:", area.name)
	return null
