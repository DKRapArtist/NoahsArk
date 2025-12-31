extends Node2D
class_name BaseTree

# ===============================
# NODES
# ===============================
@onready var canopy: Sprite2D = $Canopy
@onready var trunk: Sprite2D = $Trunk
@onready var hit_area: Area2D = $HitArea
@onready var trigger: Area2D = $CanopyTrigger
@onready var drop_point: Marker2D = $DropPoint

# ===============================
# CONFIG
# ===============================
@export var max_health := 3
@export var required_tool := "axe"
@export var wood_item: InvItem
@export var wood_amount := 2
@export var respawn_time := 10.0
@export var can_respawn := true
@export var shake_strength := 2.0
@export var shake_duration := 0.08

const FADE_ALPHA := 0.35
const FADE_SPEED := 8.0

# ===============================
# STATE
# ===============================
var health := 0
var target_alpha := 1.0
var _shake_time := 0.0
var _canopy_original_pos := Vector2.ZERO
var _trunk_original_pos := Vector2.ZERO

# ===============================
# LIFECYCLE
# ===============================
func _ready() -> void:
	health = max_health

	_canopy_original_pos = canopy.position
	_trunk_original_pos = trunk.position

	trigger.body_entered.connect(_on_canopy_entered)
	trigger.body_exited.connect(_on_canopy_exited)

	if is_in_group("trees"):
		await get_tree().process_frame
		_register_tree()

# ===============================
# UPDATE
# ===============================
func _process(delta: float) -> void:
	# Fade canopy + trunk together
	var new_alpha: float = lerp(canopy.modulate.a, target_alpha, delta * FADE_SPEED)
	canopy.modulate.a = new_alpha
	trunk.modulate.a = new_alpha

	# Shake visuals ONLY
	if _shake_time > 0.0:
		_shake_time -= delta

		var offset := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		canopy.position = _canopy_original_pos + offset
		trunk.position = _trunk_original_pos + offset * 0.5
	else:
		canopy.position = _canopy_original_pos
		trunk.position = _trunk_original_pos

# ===============================
# INTERACTION
# ===============================
func interact(tool: InvItem) -> void:
	if tool == null:
		return
	if tool.item_type != InvItem.ItemType.TOOL:
		return
	if tool.tool_type != required_tool:
		return

	health -= tool.power
	_start_shake()

	if health <= 0:
		chop_down()

# ===============================
# TREE DESTRUCTION
# ===============================
func chop_down() -> void:
	if can_respawn:
		var world := get_tree().get_first_node_in_group("world")
		if world:
			world.request_tree_respawn(
				scene_file_path,
				global_position,
				respawn_time
			)

	for i in range(wood_amount):
		_spawn_wood()

	queue_free()

func _spawn_wood() -> void:
	if wood_item == null:
		return

	var pickup := preload("res://PickUps/PickUpScenes/ItemPickUp.tscn").instantiate()
	pickup.item = wood_item
	pickup.amount = 1
	pickup.use_auto_pickup_delay = false

	var world := get_tree().get_first_node_in_group("world")
	if world:
		world.get_node("YSort").add_child(pickup)
		pickup.global_position = drop_point.global_position + Vector2(
			randf_range(-8, 8),
			randf_range(-8, 8)
		)

# ===============================
# CANOPY FADE
# ===============================
func _on_canopy_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target_alpha = FADE_ALPHA

func _on_canopy_exited(body: Node) -> void:
	if body.is_in_group("player"):
		target_alpha = 1.0

# ===============================
# TREE REGISTRATION
# ===============================
func _register_tree() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return

	var ysort := world.get_node("YSort")
	if get_parent() != ysort:
		reparent(ysort)

func _start_shake() -> void:
	_shake_time = shake_duration
