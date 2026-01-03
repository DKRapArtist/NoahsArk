extends Node2D
class_name TallGrass

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var area: Area2D = $Area2D
@onready var grass_sprite: Sprite2D = $Sprite2D
@onready var overlay: Sprite2D = $Sprite2D2


const GRASS_OVERLAY_TEXTURE := preload(
	"res://Assets/TileSets/Home Made Assets/Exported/steppedgrass.png"
)

func _ready() -> void:
	overlay.visible = false
	grass_sprite.visible = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	grass_sprite.visible = false
	overlay.visible = true
	anim_player.play("Stepped", 0.0)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	anim_player.stop()
	grass_sprite.visible = true
	overlay.visible = false

func _on_stepped_finished() -> void:
	# Only blend if the player is still in the grass
	if not overlay.visible:
		return

	overlay.visible = true
	grass_sprite.visible = true
	anim_player.play("Idle", 0.15)
