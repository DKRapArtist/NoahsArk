extends Node
class_name FarmTileInteractor

func get_facing_farm_cell(player: CharacterBody2D) -> Dictionary:
	print("🧩 FarmTileInteractor called")

	var world := player.get_tree().get_first_node_in_group("world") as World
	print("🌍 interactor world =", world)

	if world == null:
		print("❌ World not found")
		return {}

	var area := world.current_area
	print("🗺️ current area =", area)

	if area == null:
		print("❌ current_area is null")
		return {}

	var tilemaps := area.find_children("*", "TileMapLayer", true, false)
	print("🧱 Found tilemaps:", tilemaps.size())

	for tilemap in tilemaps:
		var cell := _get_facing_cell(player, tilemap)
		var data: TileData = tilemap.get_cell_tile_data(cell)

		if data == null:
			print("➡️ checking cell", cell, "NO TILE DATA")
			continue

		if not data.has_custom_data("tile_type"):
			print("➡️ checking cell", cell, "NO tile_type")
			continue

		# 🔧 EXPLICIT TYPE FIX
		var tile_type: String = data.get_custom_data("tile_type")
		print("➡️ checking cell", cell, "tile_type =", tile_type)

		if tile_type == "farm":
			print("✅ FARM TILE FOUND")
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
