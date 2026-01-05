extends CanvasLayer
class_name UIRoot

@onready var drag_icon: TextureRect = $DragIcon
@onready var drag_amount_label: Label = $DragIcon/AmountLabel

var is_dragging: bool = false
var picked_slot_index: int = -1

func _ready() -> void:
	add_to_group("ui_root")
	drag_icon.visible = false

func start_drag(slot_index: int, slot: InvSlot) -> void:
	if slot == null or slot.item == null:
		return

	picked_slot_index = slot_index
	drag_icon.texture = slot.item.texture
	drag_icon.visible = true
	is_dragging = true

	set_drag_amount(1)
	_update_drag_icon_position()

func stop_drag() -> void:
	drag_icon.visible = false
	is_dragging = false
	picked_slot_index = -1

func _process(_delta: float) -> void:
	if is_dragging:
		_update_drag_icon_position()

func _update_drag_icon_position() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	drag_icon.global_position = mouse_pos - drag_icon.size * 0.5

func set_drag_amount(amount: int) -> void:
	if drag_amount_label:
		drag_amount_label.visible = amount > 1
		drag_amount_label.text = str(amount)
