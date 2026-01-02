extends Node2D
class_name BaseFence

@onready var top: Sprite2D = $Top
@onready var trigger: Area2D = $FadeTrigger

const FADE_ALPHA := 0.35
const FADE_SPEED := 8.0

var target_alpha := 1.0

func _ready() -> void:
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	top.modulate.a = lerp(top.modulate.a, target_alpha, delta * FADE_SPEED)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target_alpha = FADE_ALPHA

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		target_alpha = 1.0
