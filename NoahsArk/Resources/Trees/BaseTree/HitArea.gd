extends Area2D

@export var parent_tree: Node2D

func _ready():
	if parent_tree == null:
		parent_tree = get_parent()

func interact(tool: InvItem) -> void:
	if parent_tree and parent_tree.has_method("interact"):
		parent_tree.interact(tool)
