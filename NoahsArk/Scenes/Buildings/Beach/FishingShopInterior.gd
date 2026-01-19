extends Node2D

@export var area_id: String = "fishing_shop_interior"

const MUSIC_TRACK_INDEX := 2

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
