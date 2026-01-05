extends Control

const MUSIC_TRACK_INDEX := 8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("Intro")
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/World/World.tscn")
