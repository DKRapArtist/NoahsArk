extends Node2D
class_name Beach

@export var water_tilemap: TileMapLayer
@export var area_id: String = "joppa_coast"

const MUSIC_TRACK_INDEX := 2

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
