extends Node

var item_to_rarity := {}

func register_table(table: FishTable):
	for fish in table.fish:
		if not item_to_rarity.has(fish.item):
			item_to_rarity[fish.item] = _weight_to_rarity(fish.weight)

func _weight_to_rarity(weight: float) -> int:
	if weight >= 50:
		return InvItem.Rarity.COMMON
	elif weight >= 20:
		return InvItem.Rarity.UNCOMMON
	elif weight >= 5:
		return InvItem.Rarity.RARE
	else:
		return InvItem.Rarity.LEGENDARY
