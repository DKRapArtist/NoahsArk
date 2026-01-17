extends Panel

@export var index: int = -1
@export var hotkey_text: String = ""
@export var is_chest_slot := false

@onready var item_display: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var amount_text: Label = $CenterContainer/Panel/Label
@onready var hotkey_label: Label = $CenterContainer/Panel/HotKeyLabel

var current_item: InvItem
var tooltip: Control = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if hotkey_label:
		hotkey_label.text = hotkey_text
		add_to_group("inventory_slot")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				_on_double_click()
			else:
				_on_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_click()

func _on_mouse_entered() -> void:
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui and inv_ui.picked_slot_index != -1:
		return

	if current_item == null:
		return

	if tooltip == null:
		return

	if not is_instance_valid(tooltip):
		return

	tooltip.show_item(
		current_item,
		get_global_mouse_position() + Vector2(16, 16)
	)

func _on_mouse_exited() -> void:
	if tooltip == null:
		return
	if not is_instance_valid(tooltip):
		return

	tooltip.hide_tooltip()

func _on_double_click() -> void:
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui:
		inv_ui.combine_item_stacks(index)

func _on_left_click() -> void:
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui == null:
		return

	inv_ui.on_slot_clicked(index, self)

func _on_right_click() -> void:
	var inv_ui := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inv_ui:
		inv_ui.on_slot_right_clicked(index)

func update(slot: InvSlot):
	if slot == null or slot.item == null or slot.amount <= 0:
		current_item = null
		item_display.visible = false
		amount_text.visible = false
		amount_text.text = ""
	else:
		current_item = slot.item
		item_display.visible = true
		item_display.texture = slot.item.texture

		if slot.amount > 1:
			amount_text.visible = true
			amount_text.text = str(slot.amount)
		else:
			amount_text.visible = false
			amount_text.text = ""

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
