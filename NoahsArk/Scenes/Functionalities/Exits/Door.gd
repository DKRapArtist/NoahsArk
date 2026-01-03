extends Exits
class_name Door

@export var door_sfx_id := "door"
@export var sfx_delay := 0.15

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	# 🚪 Door sound
	SFXManagerGlobal.play(door_sfx_id, -4.0)

	# Let sound start before scene change
	await get_tree().create_timer(sfx_delay).timeout

	super._on_body_entered(body)
