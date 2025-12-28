extends Resource
class_name InvItem

@export var name: String = ""
@export var texture: Texture2D
@export var max_stack: int = 100
@export var amount: int = 5

enum ItemType { GENERIC, TOOL, CONSUMABLE }
@export var item_type: ItemType = ItemType.GENERIC
@export var tool_type: String = ""
@export var power: int = 1
