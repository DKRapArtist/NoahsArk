extends CanvasLayer

signal on_transition_finished

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	if anim_name == "FadeToBlack":
		on_transition_finished.emit()
		animation_player.play("FadeToNormal")
	elif anim_name == "FadeToNormal":
		color_rect.visible = false
	

func transition():
	color_rect.visible = true
	animation_player.play("FadeToBlack")

func fade_in_from_black():
	color_rect.visible = true
	# Ensure it starts fully black – set alpha to 1 in the Animation or here
	animation_player.play("FadeToNormal")
