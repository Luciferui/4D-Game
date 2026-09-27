extends Node3D

var pressed := false
@export var extreme_pos := Vector2(-0., 0.1)
var speed := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if pressed:
		if self.position.y > extreme_pos.x:
			self.position.y -= delta * speed
	else:
		if self.position.y < extreme_pos.y:
			self.position.y += delta * speed


func _on_body_entered(body: Node3D) -> void:
	pressed =  true


func _on_body_exited(body: Node3D) -> void:
	pressed =  false
