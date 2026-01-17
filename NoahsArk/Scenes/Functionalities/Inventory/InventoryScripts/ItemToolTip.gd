extends PanelContainer
class_name ItemTooltip

@onready var item_name: RichTextLabel = $Panel/VBoxContainer/ItemName
@onready var stars: HBoxContainer = $Panel/VBoxContainer/TypeRow/Stars
@onready var item_type: RichTextLabel = $Panel/VBoxContainer/TypeRow/ItemType
@onready var description: RichTextLabel = $Panel/VBoxContainer/Description

const STAR_TEXTURES := {
	InvItem.Rarity.COMMON: preload("res://Assets/HomeMadeAssets/UI/RarityStars/GreenStar.png"),
	InvItem.Rarity.UNCOMMON: preload("res://Assets/HomeMadeAssets/UI/RarityStars/BlueStar.png"),
	InvItem.Rarity.RARE: preload("res://Assets/HomeMadeAssets/UI/RarityStars/PurpleStar.png"),
	InvItem.Rarity.LEGENDARY: preload("res://Assets/HomeMadeAssets/UI/RarityStars/YellowStar.png")
}

const RARITY_STARS := {
	InvItem.Rarity.COMMON: 1,
	InvItem.Rarity.UNCOMMON: 1,
	InvItem.Rarity.RARE: 1,
	InvItem.Rarity.LEGENDARY: 1
}

func show_item(item: InvItem, _pos: Vector2):
	if not is_instance_valid(item_name):
		return

	item_name.text = item.name
	item_type.text = "Type: %s" % InvItem.ItemType.keys()[item.item_type]

	# -----------------------------
	# DESCRIPTION 
	# -----------------------------
	if item.description.strip_edges() == "":
		description.visible = false
	else:
		description.visible = true
		description.text = item.description

	# -----------------------------
	# RARITY / STARS 
	# -----------------------------
	for c in stars.get_children():
		c.queue_free()
	stars.visible = false

	var rarity = FishDatabaseGlobal.item_to_rarity.get(item, -1)

	if rarity != -1:
		stars.visible = true
		for i in RARITY_STARS[rarity]:
			var star := TextureRect.new()
			star.texture = STAR_TEXTURES[rarity]
			star.custom_minimum_size = Vector2(16, 16)
			stars.add_child(star)

	const TOOLTIP_OFFSET := Vector2(8,8)

	# =============================
	# POSITIONING
	# =============================
	await get_tree().process_frame

	var viewport_rect := get_viewport().get_visible_rect()
	var tooltip_size := size

	# Use REAL mouse position so we don't double-offset
	var mouse_pos := get_global_mouse_position()
	var target_pos := mouse_pos + TOOLTIP_OFFSET

	# Clamp X (flip left if too close to right edge)
	if target_pos.x + tooltip_size.x > viewport_rect.end.x:
		target_pos.x = mouse_pos.x - tooltip_size.x - TOOLTIP_OFFSET.x

	# Clamp Y (flip up if too close to bottom edge)
	if target_pos.y + tooltip_size.y > viewport_rect.end.y:
		target_pos.y = mouse_pos.y - tooltip_size.y - TOOLTIP_OFFSET.y

	global_position = target_pos
	visible = true


func hide_tooltip():
	visible = false
