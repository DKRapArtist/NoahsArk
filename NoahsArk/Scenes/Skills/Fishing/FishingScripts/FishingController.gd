extends Node
class_name FishingController

@export var bite_time_min := 3.5
@export var bite_time_max := 7.0
@export var bite_window_duration := 0.8
@export var fishing_sfx_min_delay := 0.5
@export var fishing_sfx_max_delay := 3.0

@onready var bite_window_timer: Timer = $BiteWindowTimer
@onready var bite_timer: Timer = $BiteTimer
@onready var player := get_parent() as CharacterBody2D

enum State { IDLE, WAITING, BITE_WINDOW }

var state: State = State.IDLE
var is_fishing := false
var input_locked := false
var fishing_sfx_timer: Timer


# --------------------
# LIFECYCLE
# --------------------
func _ready():
	set_process_unhandled_input(true)

	# --- Timers already in the scene ---
	if bite_timer and not bite_timer.timeout.is_connected(_on_bite_timer_timeout):
		bite_timer.timeout.connect(_on_bite_timer_timeout)

	if bite_window_timer and not bite_window_timer.timeout.is_connected(_on_bite_window_timeout):
		bite_window_timer.timeout.connect(_on_bite_window_timeout)

	# --- Fishing SFX timer (runtime-created) ---
	fishing_sfx_timer = Timer.new()
	fishing_sfx_timer.one_shot = true
	if not fishing_sfx_timer.timeout.is_connected(_on_fishing_sfx_timer):
		fishing_sfx_timer.timeout.connect(_on_fishing_sfx_timer)
	add_child(fishing_sfx_timer)

	# --- REGISTER FISH TABLE (for rarity / tooltip lookup) ---
	var table := _get_fish_table()
	if table:
		FishDatabaseGlobal.register_table(table)


# --------------------
# INPUT
# --------------------
func _unhandled_input(_event):
	if input_locked or not is_fishing:
		return

	if Input.is_action_just_pressed("interact"):
		match state:
			State.WAITING:
				_fail()
			State.BITE_WINDOW:
				_catch()


# --------------------
# FISHING FLOW
# --------------------
func start_fishing() -> void:
	if is_fishing:
		return

# 🔒 HARD ROD GATE
	if not _can_use_equipped_rod():
		player.anim.play("Idle" + player.last_direction)
		return

	var table := _get_fish_table()
	if table:
		FishDatabaseGlobal.register_table(table)

	is_fishing = true
	input_locked = true
	state = State.WAITING

	bite_timer.stop()
	bite_window_timer.stop()

	_start_fishing_sfx_loop()
	player.anim.play("FishingIdle" + player.last_direction)

	var power := _get_effective_rod_power()
	var wait_time := randf_range(
		bite_time_min * _get_wait_multiplier(power),
		bite_time_max * _get_wait_multiplier(power)
	)

	bite_timer.start(wait_time)

	await get_tree().process_frame
	if is_fishing:
		input_locked = false


func _on_bite_timer_timeout():
	if state != State.WAITING:
		return

	state = State.BITE_WINDOW

	SFXManagerGlobal.play("fishingbite")
	player.anim.play("FishBite" + player.last_direction)

	var power := _get_effective_rod_power()
	bite_window_timer.start(
		bite_window_duration * _get_window_multiplier(power)
	)


func _on_bite_window_timeout():
	if state == State.BITE_WINDOW:
		_fail()


func _catch() -> void:
	_stop_fishing_sfx_loop()
	state = State.IDLE

	bite_timer.stop()
	bite_window_timer.stop()

	# 💦 Splash when fish is pulled in
	SFXManagerGlobal.play("fishcaught", -2.0, randf_range(0.95, 1.05))

	var table := _get_fish_table()
	var fish := _roll_fish(table)

	if fish and fish.item:
		_add_item_to_inventory(fish.item, 1)
		_play_random("pickup", 4)

		# Uses fish.fishing_xp from FishData
		PlayerProgressionGlobal.add_xp("fishing", fish.fishing_xp)

	player.anim.play("FishCaught" + player.last_direction)
	await player.anim.animation_finished

	_end_fishing()


func _fail():
	_play_random("fishing", 3)
	_end_fishing()


func _end_fishing():
	_stop_fishing_sfx_loop()

	state = State.IDLE
	is_fishing = false

	bite_timer.stop()
	bite_window_timer.stop()

	player.anim.play("Idle" + player.last_direction)


# --------------------
# FISH SELECTION (LEVEL + ROD GATES)
# --------------------
func _get_allowed_max_rarity() -> int:
	# 0=common, 1=uncommon, 2=rare, 3=legendary (based on what you described)
	var lvl := 1
	if PlayerProgressionGlobal and PlayerProgressionGlobal.skill_level.has("fishing"):
		lvl = int(PlayerProgressionGlobal.skill_level["fishing"])

	if lvl >= 9:
		return 3
	elif lvl >= 6:
		return 2
	elif lvl >= 3:
		return 1
	else:
		return 0


func _roll_fish(table: FishTable) -> FishData:
	if table == null or table.fish.is_empty():
		return null

	var fishing_level = PlayerProgressionGlobal.skill_level.get("fishing", 1)
	var rod_power := _get_effective_rod_power()

	var valid_fish: Array[FishData] = []

	for fish in table.fish:
		var xp := fish.fishing_xp

		# ---------------- LEVEL GATES ----------------
		if xp == 10 and fishing_level < 3:
			continue # Uncommon
		if xp == 25 and fishing_level < 6:
			continue # Rare
		if xp == 75 and fishing_level < 9:
			continue # Legendary

		# ---------------- ROD GATES ------------------
		if xp == 25 and rod_power < 3:
			continue # Rare needs Pro+
		if xp == 75 and rod_power < 4:
			continue # Legendary needs Master

		valid_fish.append(fish)

	# ❌ SAFETY
	if valid_fish.is_empty():
		return null

	# ---------------- WEIGHTED ROLL ----------------
	var total_weight := 0.0
	for fish in valid_fish:
		total_weight += fish.weight

	var roll := randf() * total_weight
	var acc := 0.0

	for fish in valid_fish:
		acc += fish.weight
		if roll <= acc:
			return fish

	return valid_fish.back()


# --------------------
# ROD / POWER / LEVEL REQUIREMENTS
# --------------------
func _get_equipped_rod() -> InvItem:
	if player.inv == null or player.active_hotbar_index < 0:
		return null

	if player.active_hotbar_index >= player.inv.slots.size():
		return null

	var slot = player.inv.slots[player.active_hotbar_index]
	if slot == null or slot.item == null:
		return null

	return slot.item if slot.item.tool_type == "FishingRod" else null


# Enforces: beginner 1-2, amateur 3-5, pro 6-8, master 9+
func _get_effective_rod_power() -> int:
	var rod := _get_equipped_rod()
	var lvl := 1
	if PlayerProgressionGlobal and PlayerProgressionGlobal.skill_level.has("fishing"):
		lvl = int(PlayerProgressionGlobal.skill_level["fishing"])

	if rod == null:
		return 1

	var p := int(rod.power)

	if p <= 1:
		return 1                    # Beginner: Lv 1-2 ok
	elif p == 2:
		return 2 if lvl >= 3 else 1 # Amateur: Lv 3-5
	elif p == 3:
		return 3 if lvl >= 6 else 1 # Pro: Lv 6-8
	elif p >= 4:
		return 4 if lvl >= 9 else 1 # Master: Lv 9+
	return 1


# Slower bites for low power (beginner feels "too quick" -> make it slower)
func _get_wait_multiplier(power: int) -> float:
	match power:
		1: return 1.45
		2: return 1.15
		3: return 0.80
		4: return 0.60
		_: return 1.0


# Smaller window for low power, bigger window for high power
func _get_window_multiplier(power: int) -> float:
	match power:
		1: return 0.75   # beginner (0.6s)
		2: return 0.9    # amateur
		3: return 1.1    # pro
		4: return 1.3    # master
		_: return 1.0


# --------------------
# INVENTORY
# --------------------
func _add_item_to_inventory(item: InvItem, amount := 1) -> bool:
	if player.inv == null:
		return false

	for slot in player.inv.slots:
		if slot and slot.item == item and slot.amount < item.max_stack:
			var to_add = min(item.max_stack - slot.amount, amount)
			slot.amount += to_add
			amount -= to_add
			if amount <= 0:
				player.inv.notify_changed()
				return true

	for i in range(player.inv.slots.size()):
		if player.inv.slots[i] == null or player.inv.slots[i].item == null:
			var new_slot := InvSlot.new()
			new_slot.item = item
			new_slot.amount = amount
			player.inv.slots[i] = new_slot
			player.inv.notify_changed()
			return true

	return false


# --------------------
# WATER CHECK
# --------------------
func _get_water_tilemap() -> TileMapLayer:
	var world := get_tree().get_first_node_in_group("world") as World
	if world == null or world.current_area == null:
		return null

	if world.current_area.get_child_count() == 0:
		return null

	var area := world.current_area.get_child(0)

	for tm in area.find_children("*", "TileMapLayer", true, false):
		for cell in tm.get_used_cells():
			var data = tm.get_cell_tile_data(cell)
			if data == null:
				continue

			if data.has_custom_data("tile_type") \
			and data.get_custom_data("tile_type") == "water":
				return tm

	return null


func _is_facing_water(water_tilemap: TileMapLayer) -> bool:
	if water_tilemap == null:
		return false

	var facing := _get_facing_dir()
	var tile_size := Vector2(water_tilemap.tile_set.tile_size)

	# Start from a better "interaction origin" on the player
	var origin := player.global_position

	# Tune these numbers if needed (they're in pixels)
	var x_pad := tile_size.x * 0.35
	var y_pad := tile_size.y * 0.45

	match player.last_direction:
		"Down":
			origin += Vector2(0, y_pad)
		"Up":
			origin += Vector2(0, -y_pad * 0.4)
		"Right":
			origin += Vector2(x_pad, y_pad * 0.2)
		"Left":
			origin += Vector2(-x_pad, y_pad * 0.2)

	# Check one tile forward from that origin
	var check_pos := origin + facing * tile_size

	var cell := water_tilemap.local_to_map(
		water_tilemap.to_local(check_pos)
	)

	var data := water_tilemap.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("tile_type") == "water"


func _get_facing_dir() -> Vector2:
	match player.last_direction:
		"Left":  return Vector2.LEFT
		"Right": return Vector2.RIGHT
		"Up":    return Vector2.UP
		"Down":  return Vector2.DOWN
	return Vector2.DOWN


# --------------------
# FISH TABLE
# --------------------
func _get_fish_table() -> FishTable:
	var area := get_tree().get_first_node_in_group("area_fishing")
	return area.fish_table if area else null


# --------------------
# SFX
# --------------------
func _play_random(prefix: String, count: int):
	SFXManagerGlobal.play(prefix + str(randi_range(1, count)))


func _on_fishing_sfx_timer():
	if is_fishing:
		_play_random("fishing", 3)
		fishing_sfx_timer.start(
			randf_range(fishing_sfx_min_delay, fishing_sfx_max_delay)
		)


func _start_fishing_sfx_loop():
	fishing_sfx_timer.stop()
	_play_random("fishing", 3)
	fishing_sfx_timer.start(
		randf_range(fishing_sfx_min_delay, fishing_sfx_max_delay)
	)


func _stop_fishing_sfx_loop():
	fishing_sfx_timer.stop()

func _can_use_equipped_rod() -> bool:
	var rod := _get_equipped_rod()
	if rod == null:
		return true # no rod / beginner behaviour

	var fishing_level = PlayerProgressionGlobal.skill_level.get("fishing", 1)

	match rod.power:
		1:
			return true # Beginner rod
		2:
			return fishing_level >= 3 # Amateur
		3:
			return fishing_level >= 6 # Pro
		4:
			return fishing_level >= 9 # Master
		_:
			return false
