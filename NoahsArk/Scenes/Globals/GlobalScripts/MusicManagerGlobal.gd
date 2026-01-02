# MusicManager.gd (autoload)
extends Node
class_name MusicManager

var tracks: Array[AudioStream] = []
var player: AudioStreamPlayer
var current_index: int = 0
var initialized := false

const SAVE_PATH := "user://music_save.cfg"

func _ready() -> void:
	if initialized:
		return
	initialized = true

	_load_last_index()

	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/StartingAreaMusic.wav")) # 0
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/FarmMusic.wav")) # 1
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/BeachMusic.wav")) # 2
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/TownMusic.wav")) # 3
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/MountainMusic.wav")) # 4
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/DocksMusic.wav")) # 5
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/SnowMusic.wav")) # 6
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/ForestMusic.wav")) # 7
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/MenuMusic.wav")) # 8
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/DesertMusic.wav")) # 9
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/SwampMusic.wav")) # 10
	tracks.append(load("res://Assets/SoundDesign/Music/Arsha Music Pack/VolcanoMusic.wav")) # 11

	player = AudioStreamPlayer.new()
	player.bus = "Master"
	add_child(player)

func _load_last_index() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		current_index = int(cfg.get_value("music", "current_index", 0))

func _save_current_index() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("music", "current_index", current_index)
	cfg.save(SAVE_PATH)

func play_track(index: int) -> void:
	if index < 0 or index >= tracks.size():
		return
	if current_index == index and player.playing:
		return
	current_index = index
	_save_current_index()
	player.stream = tracks[current_index]
	player.play()
