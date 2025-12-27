extends CharacterBody2D

@export var speed: float = 60.0
@export var move_hold_threshold: float = 0.02  # seconds before movement starts
@export var inv: Inv
@export var item: InvItem

var last_direction: String = "Down" # "Front", "Back", "Left", "Right"
var hold_time: float = 0.0
var last_input_dir: Vector2 = Vector2.ZERO
var active_hotbar_index: int = -1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")

	# If direction changed or released, reset hold timer.
	if input_dir == Vector2.ZERO or input_dir.normalized() != last_input_dir.normalized():
		hold_time = 0.0
	elif input_dir != Vector2.ZERO:
		hold_time += delta

	last_input_dir = input_dir

	# Only move if key has been held long enough.
	if hold_time >= move_hold_threshold:
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	_update_direction(input_dir)
	_update_animation(input_dir)

func _update_direction(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return

	# Prioritize horizontal for diagonals
	if input_dir.x < 0:
		last_direction = "Left"
	elif input_dir.x > 0:
		last_direction = "Right"
	else:
		# No horizontal input -> use vertical
		if input_dir.y > 0:
			last_direction = "Down"
		else:
			last_direction = "Up"

func _update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO or hold_time < move_hold_threshold:
		anim.play("Idle" + last_direction)
	else:
		anim.play("Walk" + last_direction)

func on_hotbar_item_selected(selected_item: InvItem, index: int) -> void:
	print("Player selected from hotbar:", selected_item.name, "slot", index)

func select_hotbar_slot(index: int) -> void:
	if index < 0 or index >= 10:
		return

	var slot := inv.slots[index]
	if slot == null or slot.item == null:
		return

	active_hotbar_index = index

	var hotbar := get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar:
		hotbar.set_active_slot(index)

	var inv_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		inv_ui.set_active_hotbar(index)

	on_hotbar_item_selected(slot.item, index)

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

func use_active_item():
	if active_hotbar_index == -1:
		return

	var slot := inv.slots[active_hotbar_index]
	if slot == null or slot.item == null:
		return

	var selected_item := slot.item

	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_areas = true

	var results := space.intersect_point(query)

	for hit in results:
		if hit.collider.has_method("interact"):
			hit.collider.interact(selected_item)
			break
