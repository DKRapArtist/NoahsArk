extends Node
class_name FishingController

@export var bite_time_min := 3.5
@export var bite_time_max := 7.0
@export var bite_window_duration := 0.45
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

	bite_timer.timeout.connect(_on_bite_timer_timeout)
	bite_window_timer.timeout.connect(_on_bite_window_timeout)

	fishing_sfx_timer = Timer.new()
	fishing_sfx_timer.one_shot = true
	fishing_sfx_timer.timeout.connect(_on_fishing_sfx_timer)
	add_child(fishing_sfx_timer)


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

	is_fishing = true
	input_locked = true
	state = State.WAITING

	bite_timer.stop()
	bite_window_timer.stop()

	_start_fishing_sfx_loop()
	player.anim.play("FishingIdle" + player.last_direction)

	var power := _get_rod_power()
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

	var power := _get_rod_power()
	bite_window_timer.start(
		bite_window_duration * _get_window_multiplier(power)
	)


func _on_bite_window_timeout():
	if state == State.BITE_WINDOW:
		_fail()


func _catch():
	_stop_fishing_sfx_loop()
	state = State.IDLE

	bite_timer.stop()
	bite_window_timer.stop()

	var table := _get_fish_table()
	var fish := _roll_fish(table)

	if fish and fish.item:
		_add_item_to_inventory(fish.item, 1)
		_play_random("pickup", 4)

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
# FISH SELECTION
# --------------------
func _get_fish_table() -> FishTable:
	var area := get_tree().get_first_node_in_group("area_fishing")
	return area.fish_table if area else null


func _roll_fish(table: FishTable) -> FishData:
	if table == null or table.fish.is_empty():
		return null

	var total_weight := 0.0
	for fish in table.fish:
		total_weight += fish.weight

	var roll := randf() * total_weight
	var acc := 0.0

	for fish in table.fish:
		acc += fish.weight
		if roll <= acc:
			return fish

	return table.fish.back()


# --------------------
# ROD / POWER
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


func _get_rod_power() -> int:
	var rod := _get_equipped_rod()
	return rod.power if rod else 1


func _get_wait_multiplier(power: int) -> float:
	return max(0.55, 1.0 - (power - 1) * 0.15)


func _get_window_multiplier(power: int) -> float:
	return 1.0 + (power - 1) * 0.15


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
	var area := get_tree().get_first_node_in_group("area_fishing")
	if area == null:
		return null

	return area.get_parent().water_tilemap


func _is_facing_water(water_tilemap: TileMapLayer) -> bool:
	if water_tilemap == null:
		return false

	var facing := _get_facing_dir()
	var tile_size := Vector2(water_tilemap.tile_set.tile_size)

	var feet_pos := player.global_position + Vector2(0, tile_size.y * 0.5)
	var world_pos := feet_pos + facing * tile_size

	var cell := water_tilemap.local_to_map(
		water_tilemap.to_local(world_pos)
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
