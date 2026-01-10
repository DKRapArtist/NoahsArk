extends CanvasLayer

@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var dialogue_label: RichTextLabel = $Panel/VBoxContainer/DialogueLabel
@onready var continue_hint: Label = $Panel/VBoxContainer/ContinueHint

var can_advance := false

func _ready() -> void:
	visible = false
	set_process_input(true)


func show_line(text: String, speaker_name: String = "") -> void:
	visible = true
	layer = 128

	name_label.text = speaker_name
	dialogue_label.text = text

	# Prevent the same key press from advancing
	can_advance = false
	await get_tree().process_frame
	can_advance = true


func hide_dialogue() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if not visible or not can_advance:
		return

	if event.is_action_pressed("interact"):
		DialogueManager.next_line()
