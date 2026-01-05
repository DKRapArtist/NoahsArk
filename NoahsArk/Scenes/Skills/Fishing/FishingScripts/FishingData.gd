extends Resource
class_name FishData

@export var id: String = ""
@export var display_name: String = ""
@export var base_value := 10
@export_range(0.0, 1000.0) var weight := 1.0
@export var item: InvItem
@export var fishing_xp: int = 8
