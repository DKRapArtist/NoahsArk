extends Node2D

@export var water_tilemap: TileMapLayer
@export var area_id: String = "oakvale"

const MUSIC_TRACK_INDEX := 0

func _ready() -> void:
	MusicManagerGlobal.play_track(MUSIC_TRACK_INDEX)
