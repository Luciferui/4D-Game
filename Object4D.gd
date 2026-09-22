extends Node3D
class_name Object4D

@export var position_3d_origin: Vector3 = Vector3.ZERO
@export var w_start: float = 0.0
@export var w_end: float = 5.0
@export var time_slices: int = 15
@export var animation_name: String = "default"
## Si vrai, seules les tranches de temps visibles (le "présent") bloquent réellement :
## les clones invisibles n'ont alors plus de collision active.
@export var ghost_collision_follows_visibility: bool = true

var ghosts: Array = []
var time_slice_thickness: float = 0.0

@onready var template: Node3D = $Template

func _ready() -> void:
	# On masque le template d'origine pour ne pas l'afficher par erreur
	if template:
		template.visible = false
		# Le template n'est qu'un modèle : il ne doit jamais exister physiquement.
		set_collision_enabled(template, false)
		
	# Calcul de l'épaisseur temporelle par clone
	time_slice_thickness = (w_end - w_start) / float(time_slices)
	
	generate_time_ghosts()

func generate_time_ghosts() -> void:
	for i in range(time_slices):
		# Duplication isolée : chaque clone a son propre Mesh et AnimationPlayer
		var clone = template.duplicate()
		add_child(clone)
		clone.visible = false # Caché par défaut

		# Le clone, lui, garde la collision du template : c'est lui qui doit être solide.
		# Elle suit la visibilité pour qu'une tranche de temps cachée ne bloque rien.
		var collision_enabled := not ghost_collision_follows_visibility
		set_collision_enabled(clone, collision_enabled)

		# Calcul du w spécifique pour ce clone
		var ghost_w = (float(i) / float(time_slices)) * (w_end - w_start) + w_start

		var anim_player = clone.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.has_animation(animation_name):
			# Mode manuel (Godot 4) pour empêcher le moteur d'écraser notre frame
			anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_MANUAL
			anim_player.play(animation_name)
			anim_player.speed_scale = 0.0
			
			# On fige le clone à son instant de vie exact
			var anim_time = ghost_w - w_start
			anim_player.seek(anim_time, true)

		# Sauvegarde des données mathématiques pour le rendu 4D
		ghosts.append({
			"node": clone,
			"w": ghost_w,
			"collision_enabled": collision_enabled
		})

## Rend une tranche de temps visible ou non, et synchronise sa collision.
func set_ghost_visible(ghost_data: Dictionary, value: bool) -> void:
	var ghost_node := ghost_data["node"] as Node3D
	if ghost_node == null:
		return
	ghost_node.visible = value
	# Une tranche de temps cachée ne doit pas bloquer le joueur depuis une position périmée
	if not ghost_collision_follows_visibility:
		return
	if ghost_data.get("collision_enabled", false) == value:
		return
	set_collision_enabled(ghost_node, value)
	ghost_data["collision_enabled"] = value

## Active/désactive toutes les collisions présentes sous `root` (récursif).
func set_collision_enabled(root: Node, enabled: bool) -> void:
	for shape in _collect_collision_shapes(root):
		shape.disabled = not enabled

func _collect_collision_shapes(root: Node) -> Array:
	var shapes := []
	if root is CollisionShape3D:
		shapes.append(root)
	for child in root.get_children():
		shapes.append_array(_collect_collision_shapes(child))
	return shapes
