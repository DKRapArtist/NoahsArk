extends Node2D
class_name CameraBounds

@export var limits := Rect2i(0, 0, 1024, 768)

func apply_to_camera(camera: Camera2D) -> void:
	camera.limit_left   = limits.position.x
	camera.limit_top    = limits.position.y
	camera.limit_right  = limits.position.x + limits.size.x
	camera.limit_bottom = limits.position.y + limits.size.y
