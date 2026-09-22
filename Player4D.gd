extends Object4D
class_name Player4D

@export var move_speed: float = 5.0
@export var w_move_speed: float = 2.0

var w_position: float = 0.0
var _ghost_w_offsets: Array[float] = []

func _ready() -> void:
	super._ready()
	w_position = (w_start + w_end) * 0.5
	_ghost_w_offsets.clear()
	for ghost_data in ghosts:
		_ghost_w_offsets.append(float(ghost_data["w"]) - w_position)
	_update_ghost_w_positions()

func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(movement.x, 0.0, movement.y)

	if Input.is_action_pressed("move_up"):
		direction.y += 1.0
	if Input.is_action_pressed("move_down"):
		direction.y -= 1.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	position_3d_origin += direction * move_speed * delta

	var w_direction := Input.get_axis("move_w_back", "move_w_forward")
	if not is_zero_approx(w_direction):
		w_position += w_direction * w_move_speed * delta
		_update_ghost_w_positions()

func _update_ghost_w_positions() -> void:
	for index in range(ghosts.size()):
		ghosts[index]["w"] = w_position + _ghost_w_offsets[index]

func reset_to_origin() -> void:
	position_3d_origin = Vector3.ZERO
	w_position = (w_start + w_end) * 0.5
	_update_ghost_w_positions()
