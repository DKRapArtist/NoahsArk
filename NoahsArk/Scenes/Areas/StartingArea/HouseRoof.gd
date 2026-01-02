extends Node2D
class_name HouseRoof

@onready var roof_sprite: Sprite2D = $RoofSprite
@onready var trigger: Area2D = $RoofTrigger

const FADE_ALPHA := 0.35
const FADE_SPEED := 8.0

var target_alpha := 1.0

func _ready():
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _process(delta):
	roof_sprite.modulate.a = lerp(
		roof_sprite.modulate.a,
		target_alpha,
		delta * FADE_SPEED
	)

func _on_body_entered(body):
	if body.is_in_group("player"):
		target_alpha = FADE_ALPHA

func _on_body_exited(body):
	if body.is_in_group("player"):
		target_alpha = 1.0
