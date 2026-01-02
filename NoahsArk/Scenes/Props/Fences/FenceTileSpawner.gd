extends TileMapLayer

@export var fence_scenes := {
	Vector2i(3, 13): preload("res://Scenes/Props/Fences/LeftEdgeFence.tscn"),
	Vector2i(4, 13): preload("res://Scenes/Props/Fences/Fence.tscn"),
	Vector2i(4, 10): preload("res://Scenes/Props/Fences/Fence.tscn"),
	Vector2i(5, 13): preload("res://Scenes/Props/Fences/RightEdgeFence.tscn"),
	Vector2i(3, 10): preload("res://Scenes/Props/Fences/LeftCornerFence.tscn"),
	Vector2i(5, 10): preload("res://Scenes/Props/Fences/RightCornerFence.tscn"),
}

func _ready() -> void:
	await get_tree().process_frame
	_spawn_fences()

func _spawn_fences() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return

	var ysort := world.get_node_or_null("YSort")
	if ysort == null:
		return

	var tile_size := tile_set.tile_size

	for cell in get_used_cells():
		var atlas_coords := get_cell_atlas_coords(cell)
		if not fence_scenes.has(atlas_coords):
			continue

		var fence = fence_scenes[atlas_coords].instantiate()
		var base_pos := to_global(map_to_local(cell))
		fence.global_position = base_pos + Vector2(0, tile_size.y * 0.5)
		ysort.add_child(fence)

	clear()
