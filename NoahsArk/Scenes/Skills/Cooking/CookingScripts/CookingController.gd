extends Node
class_name CookingController

@export var flip_wait_min := 1.5
@export var flip_wait_max := 3.0
@export var flip_window_duration := 0.45

@onready var wait_timer: Timer = $FlipTimer
@onready var flip_window_timer: Timer = $FlipWindowTimer
@onready var player := get_parent() as CharacterBody2D

enum State {
	IDLE,
	WAITING_SIDE_1,
	FLIP_WINDOW_1,
	WAITING_SIDE_2,
	FLIP_WINDOW_2
}

var state: State = State.IDLE
var is_cooking := false
var input_locked := false
var cooking_item: InvItem = null


# --------------------
# SETUP
# --------------------
func _ready():
	set_process_unhandled_input(true)

	wait_timer.one_shot = true
	flip_window_timer.one_shot = true

	wait_timer.timeout.connect(_on_wait_timer_timeout)
	flip_window_timer.timeout.connect(_on_flip_window_timeout)


# --------------------
# INPUT (LEFT CLICK)
# --------------------
func _unhandled_input(_event):
	if input_locked or not is_cooking:
		return

	if Input.is_action_just_pressed("mouse_left"):
		match state:
			State.FLIP_WINDOW_1:
				_on_successful_flip()
			State.FLIP_WINDOW_2:
				_finish_cooking()
			_:
				_burn_food()


# --------------------
# START COOKING
# --------------------
func start_cooking(item: InvItem) -> void:
	if is_cooking:
		return

	is_cooking = true
	input_locked = true
	cooking_item = item
	state = State.WAITING_SIDE_1

	# 🔥 Remove raw fish immediately
	player.inv.remove_item(item, 1)

	_start_wait()

	await get_tree().process_frame
	input_locked = false


func _start_wait():
	wait_timer.start(randf_range(flip_wait_min, flip_wait_max))


# --------------------
# TIMERS
# --------------------
func _on_wait_timer_timeout():
	match state:
		State.WAITING_SIDE_1:
			state = State.FLIP_WINDOW_1
		State.WAITING_SIDE_2:
			state = State.FLIP_WINDOW_2

	# 🔔 FLIP CUE
	SFXManagerGlobal.play("flip")
	player.anim.play("CookingFlip" + player.last_direction)

	flip_window_timer.start(flip_window_duration)


func _on_flip_window_timeout():
	_burn_food()


# --------------------
# FLIP SUCCESS
# --------------------
func _on_successful_flip():
	SFXManagerGlobal.play("flip_success")

	if state == State.FLIP_WINDOW_1:
		state = State.WAITING_SIDE_2
		_start_wait()
	elif state == State.FLIP_WINDOW_2:
		_finish_cooking()


# --------------------
# FINISH / FAIL
# --------------------
func _finish_cooking():
	SFXManagerGlobal.play("cook_done")

	if cooking_item and cooking_item.cooked_version:
		player.inv.add_item(cooking_item.cooked_version, 1)

	_reset()


func _burn_food():
	SFXManagerGlobal.play("burn")
	_reset()


func _reset():
	wait_timer.stop()
	flip_window_timer.stop()

	state = State.IDLE
	is_cooking = false
	cooking_item = null

	player.anim.play("Idle" + player.last_direction)
