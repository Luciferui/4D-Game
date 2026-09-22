extends Node3D
class_name Object4D

@export var position_3d_origin: Vector3 = Vector3.ZERO
@export var w_start: float = 0.0
@export var w_end: float = 5.0
@export var time_slices: int = 15
@export var animation_name: String = "default"

var ghosts: Array = []
var time_slice_thickness: float = 0.0

@onready var template: Node3D = $Template

func _ready() -> void:
	# On masque le template d'origine pour ne pas l'afficher par erreur
	if template:
		template.visible = false
		
	# Calcul de l'épaisseur temporelle par clone
	time_slice_thickness = (w_end - w_start) / float(time_slices)
	
	generate_time_ghosts()

func generate_time_ghosts() -> void:
	for i in range(time_slices):
		# Duplication isolée : chaque clone a son propre Mesh et AnimationPlayer
		var clone = template.duplicate()
		add_child(clone)
		clone.visible = false # Caché par défaut

		# Calcul du w spécifique pour ce clone
		var ghost_w = (float(i) / float(time_slices)) * (w_end - w_start) + w_start

		var anim_player = clone.get_node("AnimationPlayer") as AnimationPlayer
		if anim_player:
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
			"w": ghost_w
		})
