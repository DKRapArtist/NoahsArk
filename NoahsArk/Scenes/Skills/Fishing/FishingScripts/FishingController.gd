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

func _ready():
	set_process_unhandled_input(true)
	bite_timer.timeout.connect(_on_bite_timer_timeout)
	bite_window_timer.timeout.connect(_on_bite_window_timeout)
	fishing_sfx_timer = Timer.new()
	fishing_sfx_timer.one_shot = true
	fishing_sfx_timer.timeout.connect(_on_fishing_sfx_timer)

	add_child(fishing_sfx_timer)
	
func _unhandled_input(_event):
	if input_locked:
		return

	if not is_fishing:
		return

	if not Input.is_action_just_pressed("interact"):
		return

	match state:
		State.WAITING:
			_fail("Too early!")

		State.BITE_WINDOW:
			_catch()


func start_fishing():
	if is_fishing:
		return

	state = State.WAITING
	is_fishing = true
	input_locked = true

	_start_fishing_sfx_loop()

	player.anim.play("FishingIdle" + player.last_direction)

	var power := _get_rod_power()
	var wait_mult := _get_wait_multiplier(power)

	var wait_time := randf_range(
		bite_time_min * wait_mult,
		bite_time_max * wait_mult
	)

	bite_timer.start(wait_time)

	await get_tree().process_frame
	input_locked = false

func _on_bite_timer_timeout():
	if state != State.WAITING:
		return

	state = State.BITE_WINDOW

	# 🐟 Bite sound
	SFXManagerGlobal.play("fishingbite")

	player.anim.play("FishBite" + player.last_direction)

	var power := _get_rod_power()
	var window_mult := _get_window_multiplier(power)

	bite_window_timer.start(bite_window_duration * window_mult)

func _catch():
	_stop_fishing_sfx_loop()
	state = State.IDLE
	bite_timer.stop()
	bite_window_timer.stop()

	var table := _get_fish_table()
	var fish := _roll_fish(table)

	if fish == null or fish.item == null:
		_end_fishing()
		return

	_add_item_to_inventory(fish.item, 1)

	# ✅ Catch reward sound
	_play_random("pickup", 4)

	player.anim.play("FishCaught" + player.last_direction)
	await player.anim.animation_finished

	is_fishing = false
	player.anim.play("Idle" + player.last_direction)



func _fail(reason: String):
	print("Fishing failed:", reason)

	# 💦 Failed splash
	_play_random("fishing", 3)

	_end_fishing()

func _end_fishing():
	_stop_fishing_sfx_loop()

	state = State.IDLE
	is_fishing = false
	bite_timer.stop()
	bite_window_timer.stop()

	player.anim.play("Idle" + player.last_direction)

func _on_bite_window_timeout():
	if state == State.BITE_WINDOW:
		_fail("Too late!")

func _get_fish_table() -> FishTable:
	var area := get_tree().get_first_node_in_group("area_fishing")
	if area == null:
		return null

	return area.fish_table

func _roll_fish(table: FishTable) -> FishData:
	if table == null:
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

func _get_equipped_rod() -> InvItem:
	if player.active_hotbar_index == -1:
		return null

	if player.inv == null:
		return null

	if player.active_hotbar_index >= player.inv.slots.size():
		return null

	var slot = player.inv.slots[player.active_hotbar_index]
	if slot == null or slot.item == null:
		return null

	if slot.item.tool_type != "FishingRod":
		return null

	return slot.item

func _get_rod_power() -> int:
	var rod := _get_equipped_rod()
	return rod.power if rod else 1

func _get_wait_multiplier(power: int) -> float:
	return max(0.55, 1.0 - (power - 1) * 0.15)

func _get_window_multiplier(power: int) -> float:
	return 1.0 + (power - 1) * 0.15

func _add_item_to_inventory(item: InvItem, amount: int = 1) -> bool:
	if player.inv == null:
		return false

	# 1️⃣ Try stacking first
	for slot in player.inv.slots:
		if slot != null and slot.item == item and slot.amount < item.max_stack:
			var space = item.max_stack - slot.amount
			var to_add = min(space, amount)
			slot.amount += to_add
			amount -= to_add

			if amount <= 0:
				player.inv.notify_changed()
				return true

	# 2️⃣ Find empty slot
	for i in range(player.inv.slots.size()):
		if player.inv.slots[i] == null or player.inv.slots[i].item == null:
			var new_slot := InvSlot.new()
			new_slot.item = item
			new_slot.amount = amount
			player.inv.slots[i] = new_slot
			player.inv.notify_changed()
			return true

	# 3️⃣ Inventory full
	return false

func _get_water_tilemap() -> TileMapLayer:
	var area := get_tree().get_first_node_in_group("area_fishing")
	if area == null:
		return null

	var area_root := area.get_parent()
	if area_root.has_method("get"):
		return area_root.water_tilemap

	return null


func _is_facing_water(water_tilemap: TileMapLayer) -> bool:
	if water_tilemap == null:
		return false

	var facing := _get_facing_dir()
	var tile_size := water_tilemap.tile_set.tile_size.x
	var world_pos := player.global_position + facing * tile_size

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

#SFX
func _play_random(prefix: String, count: int):
	var index := randi_range(1, count)
	SFXManagerGlobal.play(prefix + str(index))

func _on_fishing_sfx_timer():
	if not is_fishing:
		return

	_play_random("fishing", 3)

	fishing_sfx_timer.start(
		randf_range(fishing_sfx_min_delay, fishing_sfx_max_delay)
	)

func _start_fishing_sfx_loop():
	fishing_sfx_timer.stop()

	# 🔊 Play immediately
	_play_random("fishing", 3)

	# ⏱ Then schedule the next random one
	fishing_sfx_timer.start(
		randf_range(fishing_sfx_min_delay, fishing_sfx_max_delay)
	)

func _stop_fishing_sfx_loop():
	if fishing_sfx_timer:
		fishing_sfx_timer.stop()
