extends Control

@onready var skill_rows := []

func _ready():
	# Collect all SkillRow children
	for child in get_children():
		if child.has_method("set_level") and child.skill_id != "":
			skill_rows.append(child)

	# Initial sync
	update_all_skills()

	# Listen for level-ups
	PlayerProgressionGlobal.level_up.connect(_on_skill_level_up)

func update_all_skills():
	for row in skill_rows:
		if PlayerProgressionGlobal.skill_level.has(row.skill_id):
			row.set_level(PlayerProgressionGlobal.skill_level[row.skill_id])

func _on_skill_level_up(skill: String, new_level: int) -> void:
	for row in skill_rows:
		if row.skill_id == skill:
			row.set_level(new_level)
			break
