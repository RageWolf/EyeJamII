extends Node3D

@export var follow_speed: float = 10.0
@export var target: NodePath


var target_node: Node3D
var is_rotating: bool = false
var orbit_angle: float = 0.0

var shake_strength := 0.0
var shake_fade := 6.0
var shake_offset := Vector3.ZERO


func _ready():
	if target:
		target_node = get_node(target)
	
	SignalBus.screen_shake.connect(_on_screen_shake)

func _on_screen_shake(intensity: float):
	shake_strength = intensity

func _process(delta):
	if target_node == null:
		return
	
	if not is_rotating:
		if Input.is_action_just_pressed("rotate_left"):
			rotate_camera(-90)
		elif Input.is_action_just_pressed("rotate_right"):
			rotate_camera(90)
	
		# base follow position
	var base_pos = global_position.lerp(target_node.global_position, follow_speed * delta)
	
	# shake logic
	if shake_strength > 0:
		shake_offset = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			0
		) * shake_strength
		
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
	else:
		shake_offset = Vector3.ZERO
	
	# apply final position
	global_position = base_pos + shake_offset
	
	# rotation stays same
	rotation.y = lerp_angle(rotation.y, deg_to_rad(orbit_angle), follow_speed * delta)

func rotate_camera(degrees: float):
	is_rotating = true

	var start_angle = orbit_angle
	var end_angle = orbit_angle + degrees

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_method(
		func(value): orbit_angle = value,
		start_angle,
		end_angle,
		0.3
	)

	tween.finished.connect(func():
		orbit_angle = round(orbit_angle / 90.0) * 90.0
		is_rotating = false
	)
