extends Node2D
class_name House

@onready var roof: Sprite2D = $Roof
@onready var roof_trigger: Area2D = $RoofTrigger

const FADE_ALPHA := 0.35
const FADE_SPEED := 8.0

var target_alpha := 1.0

func _ready():
	roof_trigger.body_entered.connect(_on_body_entered)
	roof_trigger.body_exited.connect(_on_body_exited)

func _process(delta):
	roof.modulate.a = lerp(
		roof.modulate.a,
		target_alpha,
		delta * FADE_SPEED
	)

func _on_body_entered(body):
	if body.is_in_group("player"):
		target_alpha = FADE_ALPHA

func _on_body_exited(body):
	if body.is_in_group("player"):
		target_alpha = 1.0
