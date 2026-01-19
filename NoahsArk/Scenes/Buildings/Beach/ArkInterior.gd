extends Node2D

const MUSIC_TRACK_INDEX := 12
@export var area_id: String = "ark_interior"

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
