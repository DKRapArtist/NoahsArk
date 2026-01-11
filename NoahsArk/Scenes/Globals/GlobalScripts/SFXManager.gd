extends Node
class_name SFXManager

var sounds: Dictionary = {}
var initialized := false

func _ready() -> void:
	if initialized:
		return
	initialized = true

	# 🎣 Fishing SFX
	sounds["fishing1"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Fishing/Short Water (Pitch 1).wav")
	sounds["fishing2"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Fishing/Short Water (Pitch 2).wav")
	sounds["fishing3"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Fishing/Short Water (Pitch 3).wav")
	sounds["fishingbite"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Fishing/FishingBiteSFX.wav")
	sounds["fishcaught"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Fishing/FishSplash.wav")

	#Cooking SFX
	sounds["cooking"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Cooking/Sizzle.wav")
	sounds["burnt"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Cooking/Burnt.wav")
	sounds["cooked"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Cooking/CookingComplete.wav")

	# 🎁 Pickups
	sounds["pickup1"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Collecting/Collect (Pitch 1).wav")
	sounds["pickup2"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Collecting/Collect (Pitch 2).wav")
	sounds["pickup3"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Collecting/Collect (Pitch 3).wav")
	sounds["pickup4"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Collecting/Collect (Pitch 4).wav")

	# 🪓 Woodcutting
	sounds["chopping1"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Woodcutting/WoodCutting1.wav")
	sounds["chopping2"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Woodcutting/WoodCutting2.wav")
	sounds["treefalling"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Woodcutting/Tree Chop (Complete).wav")

	#door
	sounds["door"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Building/Door Sound.wav")

	#WalkingGrass
	sounds["walkgrass1"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Walking/Grass1.wav")
	sounds["walkgrass2"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Walking/Grass2.wav")
	sounds["walkgrass3"] = load("res://Assets/SoundDesign/Arsha SFX Pack/Walking/Grass3.wav")

func play(sfx_id: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not sounds.has(sfx_id):
		push_warning("SFX not found: " + sfx_id)
		return

	var player := AudioStreamPlayer.new()
	player.stream = sounds[sfx_id]
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch

	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
