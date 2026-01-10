extends Node

var active_dialogue: DialogueData = null
var line_index: int = 0
var active_npc: Node = null


func start_dialogue(dialogue_id: String, npc: Node) -> void:
	# Prevent restarting dialogue
	if active_dialogue != null:
		print("⛔ Dialogue already active, ignoring start")
		return

	print("📢 DialogueManager.start_dialogue CALLED: id=", dialogue_id)

	# Get database
	var db := get_tree().get_first_node_in_group("dialogue_database") as DialogueDatabase
	if db == null:
		push_error("DialogueDatabase missing (not in scene or not in group)")
		return

	# Load dialogue
	active_dialogue = db.get_dialogue(dialogue_id)
	if active_dialogue == null:
		push_error("Unknown dialogue: " + dialogue_id)
		return

	active_npc = npc
	line_index = 0

	# Show first line
	_show_current_line()


func next_line() -> void:
	if active_dialogue == null:
		return

	line_index += 1
	_show_current_line()


func end_dialogue() -> void:
	print("🛑 Dialogue ended")

	active_dialogue = null
	active_npc = null

	var ui := _get_ui()
	if ui:
		ui.hide_dialogue()


# -----------------------
# Internal helpers
# -----------------------

func _show_current_line() -> void:
	if active_dialogue == null:
		return

	if line_index >= active_dialogue.lines.size():
		end_dialogue()
		return

	var line_text: String = active_dialogue.lines[line_index]
	print("📨 Showing line:", line_text)

	var ui := _get_ui()
	if ui == null:
		return

	# Final safety checks
	if not ui.has_method("show_line"):
		push_error("DialogueUI exists but has no show_line() method")
		return

	ui.show_line(line_text, active_npc.npc_name)


func _get_ui() -> CanvasLayer:
	var ui := get_node_or_null("/root/DialogueUI") as CanvasLayer
	if ui == null:
		push_error("DialogueUI not found at /root/DialogueUI (autoload missing?)")
	return ui
