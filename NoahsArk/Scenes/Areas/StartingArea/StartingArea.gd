extends Node2D

@export var water_tilemap: TileMapLayer

const MUSIC_TRACK_INDEX := 0

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
