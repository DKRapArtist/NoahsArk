@tool
extends HBoxContainer

@export var empty_dot_texture: Texture2D
@export var filled_dot_texture: Texture2D
@export var max_level: int = 10

@export var skill_id: String

func set_level(level: int) -> void:
	# Clamp for safety
	level = clamp(level, 0, max_level)

	# Clear dots
	for child in get_children():
		child.queue_free()

	for i in range(max_level):
		var dot := TextureRect.new()
		dot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP
		dot.texture = filled_dot_texture if i < level else empty_dot_texture
		add_child(dot)
