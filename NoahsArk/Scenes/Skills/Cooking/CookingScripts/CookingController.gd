extends Node
class_name CookingController

@export var flip_wait_min := 1.5
@export var flip_wait_max := 3.0
@export var flip_window_duration := 0.7
@export var cooking_xp := 8

@onready var wait_timer: Timer = $FlipTimer
@onready var flip_window_timer: Timer = $FlipWindowTimer
@onready var player := get_parent() as CharacterBody2D

var cooking_sfx_player: AudioStreamPlayer = null

enum State {
	IDLE,
	WAITING_SIDE_1,
	FLIP_WINDOW_1,
	WAITING_SIDE_2,
	FLIP_WINDOW_2
}

var state: State = State.IDLE
var is_cooking := false
var cooking_item: InvItem = null


# --------------------
# READY
# --------------------
func _ready():
	print("[COOKING] Controller ready")

	wait_timer.one_shot = true
	flip_window_timer.one_shot = true

	wait_timer.timeout.connect(_on_wait_timer_timeout)
	flip_window_timer.timeout.connect(_on_flip_window_timeout)


# --------------------
# PLAYER LEFT CLICK
# --------------------
func try_flip() -> void:
	if not is_cooking:
		return

	match state:
		State.FLIP_WINDOW_1:
			print("[COOKING] Flip 1 SUCCESS")
			_on_successful_flip()

		State.FLIP_WINDOW_2:
			print("[COOKING] Flip 2 SUCCESS → finished")
			_finish_cooking()

		_:
			print("[COOKING] Click outside flip window → burned")
			_burn_food()


# --------------------
# START COOKING
# --------------------
func start_cooking(item: InvItem) -> void:
	if is_cooking:
		return

	if player == null or player.inv == null:
		print("[COOKING] Missing player or inventory")
		return

	if not _consume_held_item(item, 1):
		print("[COOKING] Failed to consume raw item")
		return

	is_cooking = true
	cooking_item = item
	state = State.WAITING_SIDE_1

	print("[COOKING] Started cooking:", item.name)

	_start_cooking_sfx()
	_start_wait()


# --------------------
# TIMING
# --------------------
func _start_wait():
	var t := randf_range(flip_wait_min, flip_wait_max)
	print("[COOKING] Waiting", t, "seconds for flip")
	wait_timer.start(t)


func _on_wait_timer_timeout():
	match state:
		State.WAITING_SIDE_1:
			state = State.FLIP_WINDOW_1
			print("[COOKING] >>> FLIP NOW <<<")

		State.WAITING_SIDE_2:
			state = State.FLIP_WINDOW_2
			print("[COOKING] >>> FLIP AGAIN <<<")

		_:
			return

	# 🔔 AUDIO CUE (same as fishing bite)
	SFXManagerGlobal.play("fishingbite")

	flip_window_timer.start(flip_window_duration)


func _on_flip_window_timeout():
	if state == State.FLIP_WINDOW_1 or state == State.FLIP_WINDOW_2:
		print("[COOKING] Missed flip window → burned")
		_burn_food()


# --------------------
# FLIP RESULTS
# --------------------
func _on_successful_flip():
	# Stop burn timer immediately
	if not flip_window_timer.is_stopped():
		flip_window_timer.stop()

	if state == State.FLIP_WINDOW_1:
		state = State.WAITING_SIDE_2
		print("[COOKING] Side 1 done")
		_start_wait()

	elif state == State.FLIP_WINDOW_2:
		_finish_cooking()


func _finish_cooking():
	if cooking_item and cooking_item.cooked_version:
		print("[COOKING] Adding cooked item:", cooking_item.cooked_version.name)

		_add_item_to_inventory(cooking_item.cooked_version, 1)

		# ⭐ COOKING XP
		PlayerProgressionGlobal.add_xp("cooking", cooking_xp)

		# 🔔 Success sound
		SFXManagerGlobal.play("cooked")
	else:
		print("[COOKING] No cooked_version set")

	_stop_cooking_sfx()
	_reset()


func _burn_food():
	print("[COOKING] Food burned (nothing returned)")
	SFXManagerGlobal.play("burnt")

	_stop_cooking_sfx()
	_reset()


func _reset():
	wait_timer.stop()
	flip_window_timer.stop()

	state = State.IDLE
	is_cooking = false
	cooking_item = null


# --------------------
# INVENTORY HELPERS
# --------------------
func _consume_held_item(item: InvItem, amount := 1) -> bool:
	var idx = player.active_hotbar_index
	if idx < 0 or idx >= player.inv.slots.size():
		return false

	var slot = player.inv.slots[idx]
	if slot == null or slot.item == null:
		return false

	if slot.item != item:
		return false

	slot.amount -= amount
	if slot.amount <= 0:
		player.inv.slots[idx] = null

	player.inv.notify_changed()
	return true


func _add_item_to_inventory(item: InvItem, amount := 1) -> bool:
	# Try stacking first
	for slot in player.inv.slots:
		if slot and slot.item == item and slot.amount < item.max_stack:
			var to_add = min(item.max_stack - slot.amount, amount)
			slot.amount += to_add
			amount -= to_add
			if amount <= 0:
				player.inv.notify_changed()
				return true

	# Find empty slot
	for i in range(player.inv.slots.size()):
		if player.inv.slots[i] == null:
			var new_slot := InvSlot.new()
			new_slot.item = item
			new_slot.amount = amount
			player.inv.slots[i] = new_slot
			player.inv.notify_changed()
			return true

	return false


# --------------------
# COOKING SFX
# --------------------
func _start_cooking_sfx():
	if cooking_sfx_player != null:
		return

	cooking_sfx_player = AudioStreamPlayer.new()
	cooking_sfx_player.stream = SFXManagerGlobal.sounds["cooking"]
	cooking_sfx_player.bus = "SFX"
	cooking_sfx_player.volume_db = -6.0

	add_child(cooking_sfx_player)
	cooking_sfx_player.play()


func _stop_cooking_sfx():
	if cooking_sfx_player == null:
		return

	cooking_sfx_player.stop()
	cooking_sfx_player.queue_free()
	cooking_sfx_player = null
