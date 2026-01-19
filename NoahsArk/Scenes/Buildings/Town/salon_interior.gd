extends Node2D

const MUSIC_TRACK_INDEX := 3

@export var area_id: String = "salon_interior"

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
