extends Node

# Variables d'état de l'espace-temps
var global_T: float = 0.0
var angle_XW: float = 0.0

@export var rotation_speed: float = 5.0
 
func _process(delta: float) -> void:
	# Le temps réel pousse le présent de la caméra vers l'avant
	global_T += delta

	# Contrôles pour tourner l'espace-temps
	var rotation_changed = false
	if Input.is_action_pressed("rotate_xw_plus"):
		angle_XW += rotation_speed * delta * cos(angle_XW)
		rotation_changed = true
	if Input.is_action_pressed("rotate_xw_minus"):
		angle_XW -= rotation_speed * delta * cos(angle_XW)
		rotation_changed = true
	if Input.is_action_pressed("reinit_xw"):
		angle_XW = 0.
	if Input.is_action_pressed("pi2_xw"):
		angle_XW = 3.14116 / 2
	if Input.is_action_pressed("T_glob_reinit"):
		global_T = 0.
	#test
	# Rendu continu à chaque frame
	render_world_4d()

func render_world_4d() -> void:
	# Calcul des cosinus et sinus pour la matrice de rotation XW
	var c = cos(angle_XW)
	var s = sin(angle_XW)

	for object in get_children():
		if object is Object4D:
			# Tolérance multipliée par 1.5 pour assurer un chevauchement sans clignotement
			var thickness = object.time_slice_thickness * 0.505
			
			for clone_data in object.ghosts:
				var ghost_node = clone_data["node"] as Node3D
				var ghost_w = clone_data["w"]

				# Étape 1 : Coordonnée w relative au "présent" du joueur
				var relative_w = ghost_w - global_T
				
				# Étape 2 : Projection matricielle (Rotation sur le plan XW)
				var x_prime = object.position_3d_origin.x * c + relative_w * s
				var y_prime = object.position_3d_origin.y
				var z_prime = object.position_3d_origin.z
				var w_prime = -object.position_3d_origin.x * s + relative_w * c
				
				# Étape 3 : Plan de coupe (La caméra voit ce qui a w' proche de 0)
				if abs(w_prime) < thickness:
					object.set_ghost_visible(clone_data, true)
					# On déplace le Nœud Parent (le Mesh animé bougera librement à l'intérieur)
					ghost_node.global_position = Vector3(x_prime, y_prime, z_prime)
				else:
					object.set_ghost_visible(clone_data, false)
