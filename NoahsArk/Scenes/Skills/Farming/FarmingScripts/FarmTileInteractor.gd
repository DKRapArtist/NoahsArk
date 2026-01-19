extends Node
class_name FarmTileInteractor

func get_facing_farm_cell(player: CharacterBody2D) -> Dictionary:
	var world := player.get_tree().get_first_node_in_group("world") as World
	if world == null:
		return {}

	if world.current_area == null or world.current_area.get_child_count() == 0:
		return {}

	var area := world.current_area.get_child(0) as Node
	if area == null:
		return {}

	var tilemaps := area.find_children("*", "TileMapLayer", true, false)

	for tilemap in tilemaps:
		var cell := _get_facing_cell(player, tilemap)
		var data: TileData = tilemap.get_cell_tile_data(cell)
		if data == null:
			continue
		if not data.has_custom_data("tile_type"):
			continue

		var tile_type: String = str(data.get_custom_data("tile_type"))
		if tile_type == "farm":
			return {
				"tilemap": tilemap,
				"cell": cell
			}

	return {}


# -------------------------------------------------
# Helpers
# -------------------------------------------------

func _get_facing_cell(player: CharacterBody2D, tilemap: TileMapLayer) -> Vector2i:
	var tile_size := Vector2(tilemap.tile_set.tile_size)
	var facing := _get_facing_dir(player)

	var origin := player.global_position
	var offset := tile_size * 0.6

	match player.last_direction:
		"Down":
			origin += Vector2(0, offset.y)
		"Up":
			origin += Vector2(0, -offset.y)
		"Right":
			origin += Vector2(offset.x, offset.y * 0.2)
		"Left":
			origin += Vector2(-offset.x, offset.y * 0.2)

	var check_pos := origin + facing * tile_size
	return tilemap.local_to_map(tilemap.to_local(check_pos))

func _get_facing_dir(player: CharacterBody2D) -> Vector2:
	match player.last_direction:
		"Left":
			return Vector2.LEFT
		"Right":
			return Vector2.RIGHT
		"Up":
			return Vector2.UP
		"Down":
			return Vector2.DOWN
	return Vector2.DOWN
