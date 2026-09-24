extends Object4D
class_name SimpleObject4D

## A static 3D scene repeated through the configured temporal interval.
@export var object_scene: PackedScene
@export_range(0.001, 1000000.0, 0.001) var temporal_extent: float = 100000.0

func _enter_tree() -> void:
	if has_node("Template"):
		return

	var template := Node3D.new()
	template.name = "Template"
	add_child(template)

	if object_scene:
		var object := object_scene.instantiate() as Node3D
		if object:
			template.add_child(object)
		else:
			push_error("SimpleObject4D.object_scene must contain a Node3D root.")

	var animation_player := AnimationPlayer.new()
	var animation_library := AnimationLibrary.new()
	var static_animation := Animation.new()
	static_animation.length = 1.0
	static_animation.loop_mode = Animation.LOOP_LINEAR
	animation_library.add_animation("static", static_animation)
	animation_player.add_animation_library("", animation_library)
	template.add_child(animation_player)
	animation_name = "static"

func _ready() -> void:
	w_start = -temporal_extent
	w_end = temporal_extent
	super._ready()
