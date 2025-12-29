extends Node2D
class_name BaseTree

# ===============================
# NODES
# ===============================
@onready var canopy: Sprite2D = $Canopy
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

const FADE_ALPHA := 0.35
const FADE_SPEED := 8.0

# ===============================
# STATE
# ===============================
var health := 0
var target_alpha := 1.0

# ===============================
# SETUP
# ===============================
func _ready():
	health = max_health
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

# ===============================
# UPDATE
# ===============================
func _process(delta):
	canopy.modulate.a = lerp(
		canopy.modulate.a,
		target_alpha,
		delta * FADE_SPEED
	)

# ===============================
# INTERACTION ENTRY POINT
# ===============================
func interact(tool: InvItem) -> void:
	if tool == null:
		return

	if tool.item_type != InvItem.ItemType.TOOL:
		return

	if tool.tool_type != required_tool:
		return

	health -= tool.power
	print("Tree HP:", health)

	if health <= 0:
		chop_down()

# ===============================
# TREE DESTRUCTION
# ===============================
func chop_down():
	for i in range(wood_amount):
		spawn_wood()
	queue_free()

func spawn_wood():
	if wood_item == null:
		return

	var pickup := preload("res://PickUps/PickUpScenes/ItemPickUp.tscn").instantiate()
	pickup.item = wood_item
	pickup.amount = 1
	pickup.use_auto_pickup_delay = false

	get_tree().get_first_node_in_group("world").pickups_root.add_child(pickup)
	pickup.global_position = drop_point.global_position + Vector2(
		randf_range(-8, 8),
		randf_range(-8, 8)
	)

# ===============================
# CANOPY FADE
# ===============================
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target_alpha = FADE_ALPHA

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		target_alpha = 1.0
