extends Control

@onready var skill_rows := []

func _ready():
	# ✅ ADD THESE LINES
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

	visible = false

	# Collect all SkillRow children
	for child in get_children():
		if child.has_method("set_level") and child.skill_id != "":
			skill_rows.append(child)

	update_all_skills()
	PlayerProgressionGlobal.level_up.connect(_on_skill_level_up)

func toggle() -> void:
	visible = !visible
	if visible:
		update_all_skills()

func update_all_skills():
	for row in skill_rows:
		if PlayerProgressionGlobal.skill_level.has(row.skill_id):
			row.set_level(PlayerProgressionGlobal.skill_level[row.skill_id])

func _on_skill_level_up(skill: String, new_level: int) -> void:
	for row in skill_rows:
		if row.skill_id == skill:
			row.set_level(new_level)
			break
