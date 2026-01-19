extends Node2D

const MUSIC_TRACK_INDEX := 3

@export var area_id: String = "chef_house_interior"

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
