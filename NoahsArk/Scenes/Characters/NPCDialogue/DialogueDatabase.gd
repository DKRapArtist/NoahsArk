extends Node
class_name DialogueDatabase

@export var dialogues: Array[DialogueData]

var _map := {}

func _ready():
	for d in dialogues:
		_map[d.id] = d
		add_to_group("dialogue_database")

func get_dialogue(id: String) -> DialogueData:
	return _map.get(id)
