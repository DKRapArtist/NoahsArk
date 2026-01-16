extends Panel

@onready var item_name: Label = $MarginContainer/VBoxContainer/ItemName
@onready var stars: HBoxContainer = $MarginContainer/VBoxContainer/Stars
@onready var item_type: Label = $MarginContainer/VBoxContainer/ItemType
@onready var description: Label = $MarginContainer/VBoxContainer/Description

const STAR_TEXTURES := {
	InvItem.Rarity.COMMON: preload("res://Assets/HomeMadeAssets/UI/RarityStars/GreenStar.png"),
	InvItem.Rarity.UNCOMMON: preload("res://Assets/HomeMadeAssets/UI/RarityStars/BlueStar.png"),
	InvItem.Rarity.RARE: preload("res://Assets/HomeMadeAssets/UI/RarityStars/PurpleStar.png"),
	InvItem.Rarity.LEGENDARY: preload("res://Assets/HomeMadeAssets/UI/RarityStars/YellowStar.png")
}

const RARITY_STARS := {
	InvItem.Rarity.COMMON: 1,
	InvItem.Rarity.UNCOMMON: 2,
	InvItem.Rarity.RARE: 3,
	InvItem.Rarity.LEGENDARY: 4
}

func show_item(item: InvItem, pos: Vector2):
	item_name.text = item.name
	description.text = item.description
	item_type.text = "Type: %s" % InvItem.ItemType.keys()[item.item_type]

	# Clear stars
	for c in stars.get_children():
		c.queue_free()

	# ✅ ONLY SHOW STARS IF ITEM HAS RARITY
	if item.rarity != InvItem.Rarity.COMMON:
		stars.visible = true

		for i in RARITY_STARS[item.rarity]:
			var star := TextureRect.new()
			star.texture = STAR_TEXTURES[item.rarity]
			star.custom_minimum_size = Vector2(16, 16)
			stars.add_child(star)
	else:
		stars.visible = false

	global_position = pos
	visible = true

func hide_tooltip():
	visible = false
