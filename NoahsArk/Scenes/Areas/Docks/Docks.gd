extends Node2D
class_name Docks

@export var water_tilemap: TileMapLayer

const MUSIC_TRACK_INDEX := 5

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
