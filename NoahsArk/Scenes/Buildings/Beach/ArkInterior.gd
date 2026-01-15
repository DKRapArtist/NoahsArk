extends Node2D

const MUSIC_TRACK_INDEX := 12

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
