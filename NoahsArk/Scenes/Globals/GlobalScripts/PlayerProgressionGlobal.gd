extends Node
class_name PlayerProgression

signal level_up(skill: String, new_level: int)
signal xp_changed(skill: String, xp: int)

# ===============================
# SKILLS
# ===============================
const SKILLS := [
	"combat",
	"mining",
	"smithing",
	"fishing",
	"cooking",
	"farming",
	"crafting",
	"woodcutting",
	"alchemy",
	"enchantment"
]

# ===============================
# XP PER LEVEL (INDEX = LEVEL)
# index 1 = XP needed for level 1 → 2
# index 9 = XP needed for level 9 → 10
# ===============================
#@export var xp_per_level := [
#	0,      # unused (level 0)
#	100,     # 1 → 2
#	400,    # 2 → 3
#	800,    # 3 → 4
#	1300,    # 4 → 5
#	2200,    # 5 → 6
#	3400,    # 6 → 7
#	4800,    # 7 → 8
#	7000,   # 8 → 9
#	10000    # 9 → 10
#]

#TESTINGPURPOSES
@export var xp_per_level := [
	0,      # unused (level 0)
	5,     # 1 → 2
	5,    # 2 → 3
	5,    # 3 → 4
	5,    # 4 → 5
	5,    # 5 → 6
	5,    # 6 → 7
	5,    # 7 → 8
	5,   # 8 → 9ss
	5    # 9 → 10
]

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

	# Stop XP gain at max level
	if skill_level[skill] > get_max_level():
		return

	skill_xp[skill] += amount
	print("[XP] +", amount, skill, "XP →", skill_xp[skill])

	while skill_xp[skill] >= _xp_to_next(skill_level[skill]):
		skill_xp[skill] -= _xp_to_next(skill_level[skill])
		skill_level[skill] += 1
		print("⭐ LEVEL UP:", skill, "→", skill_level[skill])
		level_up.emit(skill, skill_level[skill])

		if skill_level[skill] >= get_max_level():
			skill_xp[skill] = 0
			break

	xp_changed.emit(skill, skill_xp[skill])

# ===============================
# XP LOOKUP
# ===============================
func _xp_to_next(level: int) -> int:
	if level >= xp_per_level.size():
		return 2147483647 # Max 32-bit int
	return xp_per_level[level]

func get_max_level() -> int:
	return xp_per_level.size()
