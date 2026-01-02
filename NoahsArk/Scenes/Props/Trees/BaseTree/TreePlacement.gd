extends TileMapLayer

@export var tree_scene: PackedScene

func _ready():
	replace_tree_tiles()

func replace_tree_tiles():
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		push_error("World not found")
		return

	var tile_size := tile_set.tile_size

	for cell in get_used_cells():
		var data := get_cell_tile_data(cell)
		if data == null:
			continue

		if data.get_custom_data("is_tree") != true:
			continue

		var local_pos := map_to_local(cell) + Vector2(tile_size) * 0.5
		var world_pos := global_transform * local_pos

		var tree := tree_scene.instantiate()
		world.add_child(tree)                # ✅ IMPORTANT
		tree.global_position = world_pos

		erase_cell(cell)
