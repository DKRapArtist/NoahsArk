extends Area2D

@export var target_scene_path: String
@export var target_spawn_name: String

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var world = get_tree().get_first_node_in_group("world")
		if world:
			world.load_area(target_scene_path, target_spawn_name)
