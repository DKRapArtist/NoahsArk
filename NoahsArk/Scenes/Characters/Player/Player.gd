extends CharacterBody2D

signal player_moving_signal
signal player_stopped

@export var speed: float = 60.0
@export var move_hold_threshold: float = 0.02
@export var inv: Inv
@export var step_interval := 0.35
@export var step_start_delay := 0.15
@export var max_plant_distance := 32.0

var last_direction: String = "Down"
var hold_time: float = 0.0
var last_input_dir: Vector2 = Vector2.ZERO
var active_hotbar_index: int = -1
var block_planting_this_frame := false
var is_swinging := false
var pending_tool: InvItem = null
var has_hit_this_swing := false
var was_moving := false
var grass_overlap_count := 0
var grass_overlay: Sprite2D
var step_timer := step_start_delay

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D = $InteractRay

# --------------------
# MOVEMENT
# --------------------
func _physics_process(delta: float) -> void:
	var fishing := $FishingController as FishingController

	# Block movement while fishing
	if fishing and fishing.is_fishing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Block movement while swinging
	if is_swinging:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_interact_ray_direction()
		return

	# --------------------
	# MOVEMENT
	# --------------------
	var input_dir := Input.get_vector("left", "right", "up", "down")

	if input_dir == Vector2.ZERO or input_dir.normalized() != last_input_dir.normalized():
		hold_time = 0.0
	else:
		hold_time += delta

	last_input_dir = input_dir

	if hold_time >= move_hold_threshold:
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	_update_direction(input_dir)

	# --------------------
	# MOVEMENT STATE SIGNALS
	# --------------------
	var is_moving := velocity.length() > 0.0

	if is_moving and not was_moving:
		player_moving_signal.emit()
	elif not is_moving and was_moving:
		player_stopped.emit()

	was_moving = is_moving

	# --------------------
	# ANIMATION
	# --------------------
	if fishing == null or not fishing.is_fishing:
		_update_animation(input_dir)

	_update_interact_ray_direction()

	# --------------------
	# FOOTSTEP SFX (DEBOUNCED)
	# --------------------
	if velocity.length() > 0.0 and not is_swinging:
		if fishing == null or not fishing.is_fishing:
			step_timer -= delta

			if step_timer <= 0.0:
				_play_footstep()
				step_timer = step_interval
	else:
		step_timer = step_start_delay


func _play_footstep() -> void:
	var sound_prefix := "walkgrass"

	# Later you can swap this based on surface type
	if grass_overlap_count > 0:
		sound_prefix = "walkgrass"

	SFXManagerGlobal.play(
		sound_prefix + str(randi_range(1, 3)),
		-6.0,
		randf_range(0.95, 1.05)
	)

# --------------------
# AXE HIT CHECK
# --------------------
func _process(_delta: float) -> void:
	# --------------------------------
	# RESET PER-FRAME FLAGS
	# --------------------------------
	block_planting_this_frame = false

	# --------------------------------
	# AXE HIT CHECK (UNCHANGED)
	# --------------------------------
	if is_swinging and not has_hit_this_swing:
		# 🔧 Change this number to match your animation
		if anim.frame >= 2:
			_apply_axe_hit()

	# --------------------------------
	# SEED TILE PREVIEW
	# --------------------------------
	var preview := get_tree().get_first_node_in_group("seed_preview")
	if preview == null:
		return

	# Hide preview if we shouldn't show it
	if block_planting_this_frame or not _is_holding_seeds():
		preview.hide_preview()
		return

	var world := get_tree().get_first_node_in_group("world")
	if world == null or world.current_area == null:
		preview.hide_preview()
		return

	var area = world.current_area
	var mouse_pos := get_global_mouse_position()

	var tilemap: TileMapLayer = null
	var cell: Vector2i

	# --------------------------------
	# FIND FARM TILE UNDER MOUSE
	# --------------------------------
	for tm in area.find_children("*", "TileMapLayer", true, false):
		var local_pos = tm.to_local(mouse_pos)
		var test_cell = tm.local_to_map(local_pos)
		var data = tm.get_cell_tile_data(test_cell)

		if data == null:
			continue

		if data.has_custom_data("tile_type") and data.get_custom_data("tile_type") == "farm":
			tilemap = tm
			cell = test_cell
			break

	if tilemap == null:
		preview.hide_preview()
		return

	# --------------------------------
	# CHECK IF TILE IS EMPTY + IN RANGE
	# --------------------------------
	var crop_registry := world.get_node_or_null("CropRegistry")
	if crop_registry == null:
		preview.hide_preview()
		return

	var key := "%s|%s,%s" % [tilemap.get_path(), cell.x, cell.y]
	var in_range := _is_within_plant_distance(tilemap, cell)
	var is_empty = not crop_registry.planted_crops.has(key)

	# Can plant ONLY if empty AND in range
	var can_plant = is_empty and in_range

	# --------------------------------
	# SHOW PREVIEW
	# --------------------------------
	# Always show preview on farm tiles
	preview.show_at(tilemap, cell, can_plant)

# --------------------
# INPUT
# --------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if Input.is_action_just_pressed("hotbar_1"):
			select_hotbar_slot(0)
		elif Input.is_action_just_pressed("hotbar_2"):
			select_hotbar_slot(1)
		elif Input.is_action_just_pressed("hotbar_3"):
			select_hotbar_slot(2)
		elif Input.is_action_just_pressed("hotbar_4"):
			select_hotbar_slot(3)
		elif Input.is_action_just_pressed("hotbar_5"):
			select_hotbar_slot(4)
		elif Input.is_action_just_pressed("hotbar_6"):
			select_hotbar_slot(5)
		elif Input.is_action_just_pressed("hotbar_7"):
			select_hotbar_slot(6)
		elif Input.is_action_just_pressed("hotbar_8"):
			select_hotbar_slot(7)
		elif Input.is_action_just_pressed("hotbar_9"):
			select_hotbar_slot(8)
		elif Input.is_action_just_pressed("hotbar_0"):
			select_hotbar_slot(9)

	if event.is_action_pressed("interact"):
		try_use_tool()

# --------------------
# UseTool
# --------------------
func try_use_tool() -> void:
	print("🟡 try_use_tool called")

	if block_planting_this_frame:
		return

	if is_swinging:
		return

	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui and inv_ui.is_open:
		return

	if active_hotbar_index == -1 or inv == null:
		return
	if active_hotbar_index >= inv.slots.size():
		return

	var slot := inv.slots[active_hotbar_index]
	if slot == null or slot.item == null:
		return

	var item := slot.item

	# -------------------------------------------------
	# 🌱 FARM / SEED INTERACTION  (FIXED + COMPLETE)
	# -------------------------------------------------
	var world := get_tree().get_first_node_in_group("world") as World
	print("🌍 world =", world)

	if world != null:
		var area := world.current_area.get_child(0) as Node2D
		if area == null:
			print("❌ No current area found")
			return

		var farm := world.get_node_or_null("FarmTileInteractor")
		print("🌱 farm interactor =", farm)

		if farm != null:
			var farm_target: Dictionary

			# 🌱 SEEDS → mouse-based targeting
			if item.item_type == InvItem.ItemType.CONSUMABLE and item.seed_crop_id != "":
				farm_target = _get_mouse_farm_cell()
			else:
				# 🛠️ TOOLS → facing-based targeting
				farm_target = farm.get_facing_farm_cell(self)

			print("🌾 farm_target =", farm_target)

			# ⛔ If you're not facing a farm tile, we simply don't plant.
			# We DO NOT return here, because you might be using a tool (axe/fishing) elsewhere.
			if not farm_target.is_empty():
				print("🌱 Facing farm tile:", farm_target["cell"])

				# 🌱 SEED CHECK (only attempt planting if facing farm tile)
				if item.item_type == InvItem.ItemType.CONSUMABLE \
				and item.seed_crop_id != "":

					var tilemap: TileMapLayer = farm_target["tilemap"]
					var cell: Vector2i = farm_target["cell"]

					if not _is_within_plant_distance(tilemap, cell):
						print("❌ Too far away to plant")
						return


					var crop_registry := world.get_node_or_null("CropRegistry") as CropRegistry
					if crop_registry == null:
						print("❌ CropRegistry missing")
						return

					var planted: bool = crop_registry.plant_seed(
						area,
						tilemap,
						cell,
						item.seed_crop_id
					)

					if planted:
						# 🔻 Consume seed
						slot.amount -= 1
						if slot.amount <= 0:
							inv.slots[active_hotbar_index] = null

						inv.notify_changed()
						print("🌾 Seed consumed, planting successful")

						# 🌱 IMMEDIATE VISUAL FEEDBACK (STAGE 0)
						var key := crop_registry._make_key(tilemap, cell)
						var data = crop_registry.planted_crops[key]

						crop_registry.spawn_single_crop_visual(
							area,
							tilemap,
							cell,
							data
						)

						print("🌱 Seed visual spawned immediately")
					else:
						print("⚠️ Tile already planted")

					return  # ⛔ stop further tool logic ONLY when we attempted planting

	# -------------------------------------------------
	# 🛠️ TOOL INTERACTION (AXE / FISHING)
	# -------------------------------------------------
	if item.item_type != InvItem.ItemType.TOOL:
		return

	var fishing := $FishingController as FishingController

	print(
		"[PLAYER] Using tool:",
		item.tool_type,
		"is_fishing=",
		fishing != null and fishing.is_fishing
	)

	if fishing and fishing.is_fishing:
		if item.tool_type != "FishingRod":
			return

	match item.tool_type.to_lower():
		"axe":
			_start_axe_swing(item)
		"fishingrod":
			_start_fishing()
		_:
			print("[PLAYER] Unknown tool type:", item.tool_type)

func _start_axe_swing(tool: InvItem) -> void:
	print("[PLAYER] Starting axe swing")
	is_swinging = true
	has_hit_this_swing = false
	pending_tool = tool
	anim.play("Axe" + last_direction)

func _start_fishing() -> void:
	var fishing := $FishingController as FishingController
	if fishing == null:
		return

	var water_tilemap := fishing._get_water_tilemap()
	if water_tilemap == null:
		return

	if not fishing._is_facing_water(water_tilemap):
		return

	anim.play("FishingCast" + last_direction)
	fishing.start_fishing()

# --------------------
# APPLY DAMAGE
# --------------------
func _apply_axe_hit() -> void:
	has_hit_this_swing = true

	print("AXE HIT CHECK")

	if not interact_ray.is_colliding():
		print("❌ Ray is NOT colliding")
		return

	var target := interact_ray.get_collider()
	print("✅ Ray hit:", target, " type:", target.get_class())

	if target and target.has_method("interact"):
		print("🪓 Calling interact() on", target.name)
		target.interact(pending_tool)
	else:
		print("⚠️ Hit object has NO interact() method")

# --------------------
# ANIMATION FINISHED
# --------------------
func _on_AnimatedSprite2D_animation_finished() -> void:
	print("[PLAYER] animation_finished:", anim.animation)
	is_swinging = false
	pending_tool = null
	has_hit_this_swing = false

# --------------------
# HELPERS
# --------------------
func _update_direction(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return
	if input_dir.x < 0:
		last_direction = "Left"
	elif input_dir.x > 0:
		last_direction = "Right"
	elif input_dir.y > 0:
		last_direction = "Down"
	else:
		last_direction = "Up"

func _update_animation(input_dir: Vector2) -> void:
	var fishing := $FishingController as FishingController
	if fishing and fishing.is_fishing:
		print("[PLAYER] Skipping Idle/Walk override (fishing)")
		return

	var target_anim: String
	if input_dir == Vector2.ZERO:
		target_anim = "Idle" + last_direction
	else:
		target_anim = "Walk" + last_direction

	if anim.animation != target_anim:
		print("[PLAYER] Forcing animation:", target_anim)

	anim.play(target_anim)

func _update_interact_ray_direction() -> void:
	var reach := 18.0
	match last_direction:
		"Left":  interact_ray.target_position = Vector2(-reach, 0)
		"Right": interact_ray.target_position = Vector2(reach, 0)
		"Up":    interact_ray.target_position = Vector2(0, -reach)
		"Down":  interact_ray.target_position = Vector2(0, reach)

func select_hotbar_slot(index: int) -> void:
	if inv == null:
		return
	if index < 0 or index >= inv.slots.size():
		return

	active_hotbar_index = index

	# 🔴 Update HOTBAR UI (this was missing)
	var hotbar := get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar:
		hotbar.set_active_slot(index)

	# 🔴 Update INVENTORY UI
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		inv_ui.set_active_hotbar(index)

const GRASS_OVERLAY_TEXTURE := preload(
	"res://Assets/TileSets/Home Made Assets/Exported/steppedgrass.png"
)

func _ready():
	pass

func _on_grass_detector_area_entered(_area: Area2D) -> void:
	print("PLAYER: grass entered")
	grass_overlap_count += 1

func _on_grass_detector_area_exited(_area: Area2D) -> void:
	print("PLAYER: grass exited")
	grass_overlap_count = max(grass_overlap_count - 1, 0)

func _is_holding_seeds() -> bool:
	if inv == null:
		return false

	if active_hotbar_index < 0 or active_hotbar_index >= inv.slots.size():
		return false

	var slot := inv.slots[active_hotbar_index]
	if slot == null or slot.item == null:
		return false

	return (
		slot.item.item_type == InvItem.ItemType.CONSUMABLE
		and slot.item.seed_crop_id != ""
	)

func _get_mouse_farm_cell() -> Dictionary:
	var world := get_tree().get_first_node_in_group("world")
	if world == null or world.current_area == null:
		return {}

	var area = world.current_area
	var mouse_pos := get_global_mouse_position()

	for tm in area.find_children("*", "TileMapLayer", true, false):
		var local_pos = tm.to_local(mouse_pos)
		var cell = tm.local_to_map(local_pos)
		var data = tm.get_cell_tile_data(cell)

		if data == null:
			continue

		if data.has_custom_data("tile_type") and data.get_custom_data("tile_type") == "farm":
			return {
				"tilemap": tm,
				"cell": cell
			}

	return {}

func _is_within_plant_distance(tilemap: TileMapLayer, cell: Vector2i) -> bool:
	var tile_pos := tilemap.to_global(tilemap.map_to_local(cell))
	return global_position.distance_to(tile_pos) <= max_plant_distance
