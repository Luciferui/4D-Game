extends CharacterBody3D
@export var move_speed: float = 10
@export var acceleration: float = 25.
@export var deceleration: float = 18.

var w_position: float = 0.0
var _ghost_w_offsets: Array[float] = []
var angle : float = 0.0
var gravity : float = 0.5
var has_jump : bool = false
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_back"):
		var normalized = movement.normalized()
		angle = acos(normalized.x) if asin(normalized.y) < 0 else -acos(normalized.x)
	global_rotation = Vector3(0.0,angle, 0.0)
	
	
	var target_velocity := Vector2(movement.x, movement.y) * move_speed
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
	#position += direction * move_speed * delta
