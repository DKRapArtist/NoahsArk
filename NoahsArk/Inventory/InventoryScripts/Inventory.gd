extends Resource
class_name Inv

signal inventory_changed

@export var slots: Array[InvSlot]

func notify_changed():
	inventory_changed.emit()
