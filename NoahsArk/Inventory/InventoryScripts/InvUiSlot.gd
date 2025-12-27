# SlotUI.gd (same file as above)
extends Panel

@export var index: int = -1
@export var hotkey_text: String = ""

@onready var item_display: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var amount_text: Label = $CenterContainer/Panel/Label
@onready var hotkey_label: Label = $CenterContainer/Panel/HotKeyLabel

func _ready() -> void:
	if hotkey_label:
		hotkey_label.text = hotkey_text

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
	if slot == null or slot.item == null or slot.amount <= 0:
		item_display.visible = false
		amount_text.visible = false
		amount_text.text = ""   # important: clear old number
	else:
		item_display.visible = true
		item_display.texture = slot.item.texture

		if slot.amount > 1:
			amount_text.visible = true
			amount_text.text = str(slot.amount)
		else:
			amount_text.visible = false
			amount_text.text = ""   # keep text in sync

func set_item_visible(show_item: bool) -> void:
	item_display.visible = show_item
	amount_text.visible = show_item

func set_hotkey_text(text: String) -> void:
	if hotkey_label:
		hotkey_label.text = text
		hotkey_label.visible = text != ""

func set_hotkey_color(color: Color) -> void:
	if hotkey_label:
		hotkey_label.modulate = color
