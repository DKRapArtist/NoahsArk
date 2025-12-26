# SlotUI.gd (same file as above)
extends Panel

@export var index: int = -1

@onready var item_display: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var amount_text: Label = $CenterContainer/Panel/Label

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		_on_left_click()

func _on_left_click() -> void:
	var inv_ui := get_parent().get_parent().get_parent() as Control
	# Adjust the path above so it points to your inventory Control node.
	# You can also export a NodePath instead of using get_parent() chains.

	if inv_ui == null:
		return

	inv_ui.on_slot_clicked(index)

func update(slot: InvSlot):
	if slot == null or slot.item == null:
		item_display.visible = false
		amount_text.visible = false
	else:
		item_display.visible = true
		item_display.texture = slot.item.texture

		if slot.amount > 1:
			amount_text.visible = true
			amount_text.text = str(slot.amount)
		else:
			amount_text.visible = false

func set_item_visible(show_item: bool) -> void:
	item_display.visible = show_item
	amount_text.visible = show_item and amount_text.text != ""
