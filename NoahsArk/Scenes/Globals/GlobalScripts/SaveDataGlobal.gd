extends Node
class_name SaveData

var dropped_items: Array = []
var chests := {}  # Dictionary: chest_id -> Array of slot data
var placed_chests: Array = []

func add_dropped_item(data: Dictionary) -> void:
	dropped_items.append(data)

func remove_dropped_item(predicate: Callable) -> void:
	dropped_items = dropped_items.filter(func(d): return not predicate.call(d))

func generate_chest_id() -> String:
	return "chest_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
