extends Node
class_name CropDatabase

@export var crops: Array[CropData] = []

var _crop_map := {}

func _ready():
	for crop in crops:
		_crop_map[crop.id] = crop

func get_crop(id: String) -> CropData:
	return _crop_map.get(id, null)
