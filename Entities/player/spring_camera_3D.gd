extends Node3D

@export var follow_speed: float = 10.0
@export var target: NodePath

var target_node: Node3D
var is_rotating: bool = false
var orbit_angle: float = 0.0

func _ready():
	if target:
		target_node = get_node(target)

func _process(delta):
	if target_node == null:
		return

	if not is_rotating:
		if Input.is_action_just_pressed("rotate_left"):
			rotate_camera(-90)
		elif Input.is_action_just_pressed("rotate_right"):
			rotate_camera(90)

	global_position = global_position.lerp(target_node.global_position, follow_speed * delta)
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
