extends Node
class_name PlayerProgression

signal level_up(skill: String, new_level: int)
signal xp_changed(skill: String, xp: int)

# ===============================
# SKILLS
# ===============================
const SKILLS := ["combat", "mining", "smithing", "fishing", "cooking", "farming", "crafting", "woodcutting", "alchemy", "enchantment"]

# ===============================
# DATA
# ===============================
var skill_xp := {}
var skill_level := {}

func _ready():
	for skill in SKILLS:
		skill_xp[skill] = 0
		skill_level[skill] = 1

# ===============================
# XP API (CALLED BY GAMEPLAY)
# ===============================
func add_xp(skill: String, amount: int) -> void:
	if not skill_xp.has(skill):
		push_warning("Unknown skill: " + skill)
		return

	skill_xp[skill] += amount
	print("[XP] +", amount, skill, "XP →", skill_xp[skill])

	while skill_xp[skill] >= _xp_to_next(skill_level[skill]):
		skill_xp[skill] -= _xp_to_next(skill_level[skill])
		skill_level[skill] += 1
		print("⭐ LEVEL UP:", skill, "→", skill_level[skill])
		level_up.emit(skill, skill_level[skill])

	xp_changed.emit(skill, skill_xp[skill])

# ===============================
# XP CURVE
# ===============================
func _xp_to_next(level: int) -> int:
	return int(25 + pow(level, 1.6) * 10)
