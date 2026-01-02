extends Node2D
class_name Beach

@export var water_tilemap: TileMapLayer

const MUSIC_TRACK_INDEX := 2

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
