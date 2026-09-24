extends Node

# Vérification visuelle temporaire : capture le niveau dans le passé puis dans le présent.
var _elapsed: float = 0.0
var _step: int = 0

func _process(delta: float) -> void:
	_elapsed += delta
	if _step == 0 and _elapsed > 0.6:
		_step = 1
		_capture("past")
	elif _step == 1 and _elapsed > 3.4:
		_step = 2
		_capture("present")
		await get_tree().create_timer(0.4).timeout
		get_tree().quit()

func _capture(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_%s.png" % tag)
	print("[SHOT] %s" % tag)
