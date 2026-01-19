extends Node2D

const MUSIC_TRACK_INDEX := 1

@export var area_id: String = "farm_house_interior"

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
