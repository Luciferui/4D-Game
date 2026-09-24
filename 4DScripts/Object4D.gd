extends Node3D
class_name Object4D

@export var position_3d_origin: Vector3 = Vector3.ZERO
@export var w_start: float = 0.0
@export var w_end: float = 5.0
@export var time_slices: int = 15
@export var animation_name: String = "default"
## Décalage temporel (en secondes) appliqué au shader entre deux tranches de temps :
## le clone i anime son shader avec TIME - i * shader_time_step.
## 0.0 -> tous les clones animent en temps réel (aucun décalage).
@export var shader_time_step: float = 0.08
## Opacité (alpha) des tranches de temps (clones) : 0.0 (invisible) à 1.0 (opaque).
@export_range(0.0, 1.0, 0.01) var ghost_alpha: float = 0.5
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

		# Chaque clone doit avoir ses propres matériaux : sinon le décalage
		# temporel (u_time_offset) serait partagé par tous les clones.
		_make_materials_unique(clone)

		# Le clone, lui, garde la collision du template : c'est lui qui doit être solide.
		# Elle suit la visibilité pour qu'une tranche de temps cachée ne bloque rien.
		var collision_enabled := not ghost_collision_follows_visibility
		set_collision_enabled(clone, collision_enabled)

		# Calcul du w spécifique pour ce clone
		var ghost_w = (float(i) / float(time_slices)) * (w_end - w_start) + w_start

		# Le shader du clone i anime son temps en direct (comme un objet 3D),
		# simplement décalé : TIME - i * shader_time_step.
		_set_shader_time_offset(clone, float(i) * shader_time_step)

		# Application de l'alpha configuré sur les matériaux du clone
		_apply_ghost_alpha(clone, ghost_alpha)

		var anim_player = clone.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.has_animation(animation_name):
			# Mode manuel (Godot 4) pour empêcher le moteur d'écraser notre frame
			anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_MANUAL
			anim_player.play(animation_name)
			anim_player.speed_scale = 0.0
			
			# On fige le clone à son instant de vie exact
			# (modulo la durée de l'animation : elle boucle sur le temps)
			var anim_time = ghost_w - w_start
			var anim = anim_player.get_animation(animation_name)
			if anim and anim.length > 0.0:
				anim_time = fposmod(anim_time, anim.length)
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

## Duplique les matériaux (surface override) de tous les MeshInstance3D sous
## `root` pour que chaque ghost puisse animer ses propres shader parameters.
func _make_materials_unique(root: Node) -> void:
	if root is MeshInstance3D:
		var mesh_inst := root as MeshInstance3D
		for surface in mesh_inst.get_surface_override_material_count():
			var mat := mesh_inst.get_surface_override_material(surface)
			if mat:
				mesh_inst.set_surface_override_material(surface, mat.duplicate())
	for child in root.get_children():
		_make_materials_unique(child)

## Règle le décalage temporel du shader (u_time_offset) sous `root`.
func _set_shader_time_offset(root: Node, offset: float) -> void:
	if root is MeshInstance3D:
		var mesh_inst := root as MeshInstance3D
		for surface in mesh_inst.get_surface_override_material_count():
			var mat := mesh_inst.get_surface_override_material(surface)
			if mat is ShaderMaterial:
				mat.set_shader_parameter("u_time_offset", offset)
	for child in root.get_children():
		_set_shader_time_offset(child, offset)

## Applique la transparence (alpha) sur tous les matériaux des MeshInstance3D sous `root`.
func _apply_ghost_alpha(root: Node, alpha: float) -> void:
	if root is MeshInstance3D:
		var mesh_inst := root as MeshInstance3D
		for surface in mesh_inst.get_surface_override_material_count():
			var mat := mesh_inst.get_surface_override_material(surface)
			if mat is ShaderMaterial:
				mat.set_shader_parameter("u_alpha", alpha)
			elif mat is StandardMaterial3D:
				var std_mat := mat as StandardMaterial3D
				std_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				var col := std_mat.albedo_color
				col.a = alpha
				std_mat.albedo_color = col
	for child in root.get_children():
		_apply_ghost_alpha(child, alpha)
