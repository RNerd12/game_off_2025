extends CharacterBody2D


@export var speed: float = 300.0
@export var jump_velocity: float = -500.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.10
@export var friction: float = 2000.0
@export var air_accel: float = 1600.0
@export var ground_accel: float = 2000.0
@export var jump_cut_multiplier: float = 0.45
@export var max_fall_speed: float = 900.0
@export var gravity: float = 1400.0

var _coyote_ready: bool = false
var _jump_buffer: bool = false

enum STATE {
	GROUNDED,
	AIRBORNE
}

var state = STATE.GROUNDED

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var buffer_timer: Timer = $JumpBufferTimer

func _ready() -> void:
	coyote_timer.wait_time = coyote_time
	buffer_timer.wait_time = jump_buffer

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_horizontal(delta)
	_check_ground()
	_handle_jump()
	_apply_terminal_velocity()
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _handle_horizontal(delta: float) -> void:
	var dir := Input.get_action_strength("right") - Input.get_action_strength("left")
	var target_speed := dir * speed
	var accel := ground_accel if is_on_floor() else air_accel

	if dir != 0:
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _check_ground() -> void:
	if is_on_floor():
		if state == STATE.AIRBORNE:
			state = STATE.GROUNDED
		_coyote_ready = true
		coyote_timer.start()
	else:
		if state == STATE.GROUNDED:
			state = STATE.AIRBORNE

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = true
		buffer_timer.start()

	if _jump_buffer and (is_on_floor() or _coyote_ready):
		velocity.y = jump_velocity
		_jump_buffer = false
		_coyote_ready = false
		buffer_timer.stop()
		coyote_timer.stop()

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier
	
func _apply_terminal_velocity() -> void:
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed

func _on_jump_buffer_timer_timeout() -> void:
	_jump_buffer = false

func _on_coyote_timer_timeout() -> void:
	_coyote_ready = false
