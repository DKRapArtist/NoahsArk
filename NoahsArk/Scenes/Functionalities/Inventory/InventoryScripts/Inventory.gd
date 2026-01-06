extends Resource
class_name Inv

signal inventory_changed

@export var slot_count: int = 40
@export var slots: Array[InvSlot] = []

func ensure_clean_slots():
	# Enforce correct size
	slots.resize(slot_count)

	# Convert "fake empty" slots into real nulls
	for i in range(slots.size()):
		if slots[i] != null:
			if slots[i].item == null or slots[i].amount <= 0:
				slots[i] = null

func notify_changed():
	inventory_changed.emit()
