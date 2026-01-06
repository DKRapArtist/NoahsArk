extends Node
class_name CropRegistry

@export var crop_visual_scene: PackedScene
@export var crop_items: Dictionary = {}

# Key: "tilemap_path|x,y"
# Value: Dictionary with full crop data
var planted_crops: Dictionary = {}

# ===============================
# INTERNAL HELPERS
# ===============================
func _make_key(tilemap: TileMapLayer, cell: Vector2i) -> String:
	return "%s|%s,%s" % [
		tilemap.get_path(),
		cell.x,
		cell.y
	]

func _get_crop_data(crop_id: String) -> CropData:
	var crop_db := get_tree().get_first_node_in_group("crop_database") as CropDatabase
	if crop_db == null:
		push_error("❌ CropDatabase not found (group: crop_database)")
		return null

	var crop_data := crop_db.get_crop(crop_id)
	if crop_data == null:
		push_error("❌ Unknown crop id: " + crop_id)
		return null

	return crop_data

# ===============================
# PLANTING
# ===============================
func plant_seed(
	area: Node2D,
	tilemap: TileMapLayer,
	cell: Vector2i,
	seed_crop_id: String
) -> bool:
	var key := _make_key(tilemap, cell)

	if planted_crops.has(key):
		return false

	planted_crops[key] = {
		"crop_id": seed_crop_id,
		"planted_time": Time.get_unix_time_from_system(),
		"area_path": area.scene_file_path,
		"tilemap_path": tilemap.get_path(),
		"cell": cell
	}

	print("🌱 Seed planted:", planted_crops[key])
	return true

# ===============================
# AREA VISUAL SPAWNING
# ===============================
func spawn_crops_for_area(area: Node2D) -> void:
	for key in planted_crops.keys():
		var data = planted_crops[key]

		if data.get("area_path") != area.scene_file_path:
			continue

		var tilemap := area.get_node_or_null(data["tilemap_path"]) as TileMapLayer
		if tilemap == null:
			continue

		var crop_data := _get_crop_data(data["crop_id"])
		if crop_data == null:
			continue

		var crop_scene := crop_visual_scene \
			if crop_visual_scene != null \
			else preload("res://Scenes/Skills/Farming/FarmingScenes/CropVisual.tscn")

		var crop := crop_scene.instantiate() as CropVisual
		area.add_child(crop)

		crop.setup(
			crop_data,
			data["planted_time"],
			tilemap,
			data["cell"]
		)

# ===============================
# SINGLE SPAWN (IMMEDIATE PLANTING)
# ===============================
func spawn_single_crop_visual(
	area: Node2D,
	tilemap: TileMapLayer,
	cell: Vector2i,
	data: Dictionary,
) -> void:
	if crop_visual_scene == null:
		push_error("❌ Crop visual scene not assigned")
		return

	var crop_data := _get_crop_data(data["crop_id"])
	if crop_data == null:
		return

	var crop := crop_visual_scene.instantiate() as CropVisual
	area.add_child(crop)

	crop.setup(
		crop_data,
		data["planted_time"],
		tilemap,
		cell
	)
