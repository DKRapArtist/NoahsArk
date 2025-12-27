extends CharacterBody2D

@export var speed: float = 60.0
@export var move_hold_threshold: float = 0.02  # seconds before movement starts
@export var inv: Inv
@export var item: InvItem

var last_direction: String = "Down" # "Front", "Back", "Left", "Right"
var hold_time: float = 0.0
var last_input_dir: Vector2 = Vector2.ZERO

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
