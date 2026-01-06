extends Node2D
class_name SeedTilePreview

@export var valid_color := Color(0.3, 1.0, 0.3, 0.9)
@export var invalid_color := Color(1.0, 0.3, 0.3, 0.9)

@onready var sprite := $Sprite2D

func show_at(tilemap: TileMapLayer, cell: Vector2i, can_plant: bool) -> void:
	global_position = tilemap.to_global(tilemap.map_to_local(cell))
	sprite.modulate = valid_color if can_plant else invalid_color
	visible = true

func hide_preview() -> void:
	visible = false
