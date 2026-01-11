extends CharacterBody2D

signal player_moving_signal
signal player_stopped

@export var speed: float = 60.0
@export var move_hold_threshold: float = 0.02
@export var inv: Inv
@export var step_interval := 0.35
@export var step_start_delay := 0.15
@export var max_plant_distance := 80.0

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
var nearby_npc: NPC = null
var nearby_cooking_station: CookingStation = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D = $InteractRay


# --------------------
# MOVEMENT
# --------------------
func _physics_process(delta: float) -> void:
	var fishing := $FishingController as FishingController
	var cooking := $CookingController as CookingController

	if fishing and fishing.is_fishing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if cooking and cooking.is_cooking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_swinging:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_interact_ray_direction()
		return

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

	var is_moving := velocity.length() > 0.0

	if is_moving and not was_moving:
		player_moving_signal.emit()
	elif not is_moving and was_moving:
		player_stopped.emit()

	was_moving = is_moving

	if fishing == null or not fishing.is_fishing:
		_update_animation(input_dir)

	_update_interact_ray_direction()

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
	if grass_overlap_count > 0:
		sound_prefix = "walkgrass"

	SFXManagerGlobal.play(
		sound_prefix + str(randi_range(1, 3)),
		-6.0,
		randf_range(0.95, 1.05)
	)


# --------------------
# PROCESS
# --------------------
func _process(_delta: float) -> void:
	block_planting_this_frame = false

	if is_swinging and not has_hit_this_swing:
		if anim.frame >= 2:
			_apply_axe_hit()


# --------------------
# INPUT
# --------------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if DialogueManager.active_dialogue != null:
			return

		var cooking := $CookingController as CookingController

		if cooking and cooking.is_cooking:
			return

		if nearby_cooking_station != null and cooking:
			var item := _get_held_item()
			if item and item.is_cookable and item.cooked_version:
				anim.play("CookingStart" + last_direction)
				cooking.start_cooking(item)
				return

		if nearby_npc != null:
			nearby_npc.interact()
			return

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

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		try_use_tool()
		return


# --------------------
# TOOL USE
# --------------------
func try_use_tool() -> void:
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

	if item.item_type != InvItem.ItemType.TOOL:
		return

	var fishing := $FishingController as FishingController
	var cooking := $CookingController as CookingController

	if cooking and cooking.is_cooking:
		return

	if fishing and fishing.is_fishing and item.tool_type != "FishingRod":
		return

	match item.tool_type.to_lower():
		"axe":
			_start_axe_swing(item)
		"fishingrod":
			_start_fishing()


func _start_axe_swing(tool: InvItem) -> void:
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
# AXE HIT
# --------------------
func _apply_axe_hit() -> void:
	has_hit_this_swing = true

	if not interact_ray.is_colliding():
		return

	var target := interact_ray.get_collider()
	if target and target.has_method("interact"):
		target.interact(pending_tool)


# --------------------
# ANIMATION
# --------------------
func _on_AnimatedSprite2D_animation_finished() -> void:
	is_swinging = false
	pending_tool = null
	has_hit_this_swing = false


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
	var cooking := $CookingController as CookingController

	if (fishing and fishing.is_fishing) or (cooking and cooking.is_cooking):
		return

	var target_anim := "Idle" + last_direction if input_dir == Vector2.ZERO else "Walk" + last_direction
	if anim.animation != target_anim:
		anim.play(target_anim)


func _update_interact_ray_direction() -> void:
	var reach := 18.0
	match last_direction:
		"Left":  interact_ray.target_position = Vector2(-reach, 0)
		"Right": interact_ray.target_position = Vector2(reach, 0)
		"Up":    interact_ray.target_position = Vector2(0, -reach)
		"Down":  interact_ray.target_position = Vector2(0, reach)


# --------------------
# HOTBAR
# --------------------
func select_hotbar_slot(index: int) -> void:
	if inv == null:
		return
	if index < 0 or index >= inv.slots.size():
		return

	active_hotbar_index = index

	var hotbar := get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar:
		hotbar.set_active_slot(index)

	var inv_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		inv_ui.set_active_hotbar(index)


# --------------------
# INTERACTION AREA
# --------------------
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is NPC:
		nearby_npc = body
	elif body is CookingStation:
		nearby_cooking_station = body


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if nearby_npc == body:
		nearby_npc = null
	elif nearby_cooking_station == body:
		nearby_cooking_station = null


# --------------------
# INVENTORY
# --------------------
func _get_held_item() -> InvItem:
	if inv == null:
		return null
	if active_hotbar_index < 0 or active_hotbar_index >= inv.slots.size():
		return null

	var slot := inv.slots[active_hotbar_index]
	if slot == null or slot.item == null:
		return null

	return slot.item

func _on_grass_detector_area_entered(_area: Area2D) -> void:
	grass_overlap_count += 1

func _on_grass_detector_area_exited(_area: Area2D) -> void:
	grass_overlap_count = max(grass_overlap_count - 1, 0)
