extends OmniLight3D

## Fait vaciller doucement une torche autour de son énergie de base,
## avec un déphasage aléatoire pour que les torches ne clignotent pas ensemble.
@export var flicker_speed: float = 7.0
@export var flicker_amount: float = 0.28
@export var min_energy_ratio: float = 0.55
@export var max_energy_ratio: float = 1.6

var _base_energy: float = 1.0
var _phase: float = 0.0

func _ready() -> void:
	_base_energy = light_energy
	_phase = randf() * TAU

func _process(delta: float) -> void:
	_phase += delta * flicker_speed
	var wave := sin(_phase) * 0.6 + sin(_phase * 2.3 + 1.7) * 0.3 + sin(_phase * 5.1 + 0.4) * 0.1
	var ratio := clampf(1.0 + wave * flicker_amount, min_energy_ratio, max_energy_ratio)
	light_energy = _base_energy * ratio
