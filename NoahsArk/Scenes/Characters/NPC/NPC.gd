extends CharacterBody2D
class_name NPC

@export var npc_name: String = ""
@export var idle_direction: String = "Down"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	_play_idle()

func _play_idle():
	var anim_name := "Idle" + idle_direction
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)

func interact():
	print("Talking to", npc_name)

func _physics_process(_delta: float) -> void:
	move_and_slide()
