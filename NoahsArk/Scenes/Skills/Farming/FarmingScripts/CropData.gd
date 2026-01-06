extends Resource
class_name CropData

@export var id: String
@export var display_name: String
@export var seed_offset_y: float = -8.0
@export var crop_offset_y: float = 0.0

@export var total_growth_time: float = 300.0 # seconds (5 minutes)

@export var stage_textures: Array[Texture2D] = []
