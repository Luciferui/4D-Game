extends CharacterBody3D

@export var move_speed: float = 10.0
@export var acceleration: float = 25.0
@export var deceleration: float = 18.0
@export var mouse_sensitivity: float = 0.002

var gravity: float = 0.5
var has_jump: bool = false
var camera_pitch: float = 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Tourner le joueur horizontalement (axe Y)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Incliner la caméra verticalement (axe X)
		camera_pitch = clamp(camera_pitch - event.relative.y * mouse_sensitivity, -deg_to_rad(89.0), deg_to_rad(89.0))
		if camera:
			camera.rotation.x = camera_pitch
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.is_pressed():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Direction relative à l'orientation du joueur
	var direction := (global_transform.basis * Vector3(movement.x, 0.0, movement.y)).normalized() if movement.length_squared() > 0.0 else Vector3.ZERO
	
	var target_velocity := Vector2(direction.x, direction.z) * move_speed
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var speed_change := acceleration if target_velocity.length_squared() > 0.0 else deceleration
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, speed_change * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	
	velocity.y -= gravity
	if Input.is_action_pressed("move_up"):
		if not has_jump:
			velocity.y += 7.0
			has_jump = true
	if is_on_floor():
		has_jump = false
	if Input.is_action_pressed("move_down"):
		velocity.y -= 1.0
	
	move_and_slide()
