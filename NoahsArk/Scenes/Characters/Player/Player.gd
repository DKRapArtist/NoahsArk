extends CharacterBody2D

@export var speed: float = 60.0
@export var move_hold_threshold: float = 0.02
@export var inv: Inv

var last_direction: String = "Down"
var hold_time: float = 0.0
var last_input_dir: Vector2 = Vector2.ZERO
var active_hotbar_index: int = -1

var is_swinging := false
var pending_tool: InvItem = null
var has_hit_this_swing := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D = $InteractRay

# --------------------
# MOVEMENT
# --------------------
func _physics_process(delta: float) -> void:
	var fishing := $FishingController as FishingController

	if fishing and fishing.is_fishing:
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

	# ✅ Only update animation if NOT fishing
	if fishing == null or not fishing.is_fishing:
		_update_animation(input_dir)

	_update_interact_ray_direction()


# --------------------
# AXE HIT CHECK
# --------------------
func _process(_delta: float) -> void:
	if not is_swinging:
		return
	if has_hit_this_swing:
		return

	# 🔧 Change this number to match your animation
	if anim.frame >= 2:
		_apply_axe_hit()

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

	if slot.item.item_type != InvItem.ItemType.TOOL:
		return

	var fishing := $FishingController as FishingController

	print(
		"[PLAYER] Using tool:",
		slot.item.tool_type,
		"is_fishing=",
		fishing != null and fishing.is_fishing
	)

	if fishing and fishing.is_fishing:
		if slot.item.tool_type != "FishingRod":
			return


	match slot.item.tool_type.to_lower():
		"axe":
			_start_axe_swing(slot.item)

		"fishingrod":
			_start_fishing()

		_:
			print("[PLAYER] Unknown tool type:", slot.item.tool_type)


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
