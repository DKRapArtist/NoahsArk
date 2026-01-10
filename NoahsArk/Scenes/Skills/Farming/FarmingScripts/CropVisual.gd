extends Node2D
class_name CropVisual

const TOTAL_GROW_TIME := 60.0 # seconds (1 minute for testing)
const STAGE_COUNT := 6
const HARVEST_RANGE := 80.0

@onready var sprite: Sprite2D = $Sprite2D
@export var stage_textures: Array[Texture2D] = []
@export var seed_offset_y := 0.0
@export var crop_offset_y := -10.0

var crop_id: String
var planted_time: float
var tilemap: TileMapLayer
var cell: Vector2i
var crop_data: CropData

func setup(
	_crop_data: CropData,
	_planted_time: float,
	_tilemap: TileMapLayer,
	_cell: Vector2i,
) -> void:
	crop_data = _crop_data
	crop_id = _crop_data.id
	planted_time = _planted_time
	tilemap = _tilemap
	cell = _cell

	stage_textures = _crop_data.stage_textures

	global_position = tilemap.to_global(
		tilemap.map_to_local(cell)
	)

func _get_growth_stage() -> int:
	var elapsed := Time.get_unix_time_from_system() - planted_time

	# 🌱 First stage is ALWAYS seeds
	if elapsed < 1.0:
		return 0

	var stage_duration := TOTAL_GROW_TIME / float(STAGE_COUNT - 1)
	var stage := int(elapsed / stage_duration)

	return clamp(stage, 0, STAGE_COUNT - 1)


func _process(_delta: float) -> void:
	var stage := _get_growth_stage()

	if stage_textures.size() != STAGE_COUNT:
		return

	sprite.texture = stage_textures[stage]

	if stage == 0:
		sprite.position.y = seed_offset_y
	else:
		sprite.position.y = crop_offset_y

func is_fully_grown() -> bool:
	return _get_growth_stage() == STAGE_COUNT - 1

func _ready() -> void:
	$InteractArea.input_event.connect(_on_input_event)

func _on_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# 🚫 Too far away
	if player.global_position.distance_to(global_position) > HARVEST_RANGE:
		return

	# ⛔ Stop input from reaching Player / tools
	get_viewport().set_input_as_handled()

	if not is_fully_grown():
		print("🌱 Crop not ready to harvest")
		return

	_harvest()

func _harvest() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.block_planting_this_frame = true

	print("🌾 Harvesting crop:", crop_id)

	var world := get_tree().get_first_node_in_group("world") as World
	if world == null:
		return

	var crop_registry := world.get_node_or_null("CropRegistry") as CropRegistry
	if crop_registry == null:
		return

	# Remove crop from registry
	var key := "%s|%s,%s" % [tilemap.get_path(), cell.x, cell.y]
	crop_registry.planted_crops.erase(key)

	if crop_data:
		PlayerProgressionGlobal.add_xp("farming", crop_data.farming_xp)

	# Get harvest item
	if not crop_registry.crop_items.has(crop_id):
		push_error("❌ No inventory item registered for crop: " + crop_id)
		queue_free()
		return

	var item: InvItem = crop_registry.crop_items[crop_id]

	# Spawn pickup
	var pickup_scene := preload(
		"res://Scenes/Functionalities/PickUps/PickUpScenes/ItemPickUp.tscn"
	)

	var pickup := pickup_scene.instantiate() as ItemPickup
	pickup.item = item
	pickup.amount = 1
	pickup.use_auto_pickup_delay = false

	world.get_node("YSort").add_child(pickup)
	pickup.global_position = global_position

	queue_free()
