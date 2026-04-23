extends Node3D

@export var mouse_sensitivity: float = 0.2

var orbit_angle: float = 0.0
var shake_strength := 0.0
var shake_fade := 6.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	SignalBus.screen_shake.connect(_on_screen_shake)

func _on_screen_shake(intensity: float):
	shake_strength = intensity

func _input(event):
	if event is InputEventMouseMotion:
		orbit_angle -= event.relative.x * mouse_sensitivity

func _process(delta):
	rotation.y = lerp_angle(rotation.y, deg_to_rad(orbit_angle), 10.0 * delta)
	
	if shake_strength > 0:
		position.x = randf_range(-1, 1) * shake_strength
		position.y = randf_range(-1, 1) * shake_strength
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
	else:
		position.x = 0.0
		position.y = 0.0
