extends Node3D

@export var mouse_sensitivity: float = 0.2
@export var normal_length: float = 3.0
@export var hidden_length: float = 5.0
@export var zoom_speed: float = 3.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

@onready var player: Player = get_tree().get_first_node_in_group("player")

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
	#print("player ref: ", player, " | is_hidden: ", player.is_hidden if player else "NULL")
	# zoom out when hidden
	var target_length = hidden_length if player.is_hidden else normal_length
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, zoom_speed * delta)
	
	if shake_strength > 0:
		position.x = randf_range(-1, 1) * shake_strength
		position.y = randf_range(-1, 1) * shake_strength
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
	else:
		position.x = 0.0
		position.y = 0.0
