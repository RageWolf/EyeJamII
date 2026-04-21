class_name Player extends CharacterBody3D

#region CAMERA VARIABLES
@export var camera: NodePath
var cam: Camera3D
#endregion 

#region FEEDING VARIABLES
@onready var interaction_area: InteractionArea = $InteractionArea
var interact_ui_visible := false

var is_feeding := false
var feed_timer := 0.0
var feed_duration := 2.5  # seconds to fully drain
var feed_cooldown := 0.3
var can_feed := true
var current_target = null
var attach_position: Vector3
#endregion 


#region MOVEMENT VARIABLES
@export var SPEED = 4.0
@export var GRAVITY = -9.8
@export var ACCELERATION = 15.0
@export var FRICTION = 12.0
#endregion

func _ready():
	if camera:
		cam = get_node(camera)


func _physics_process(delta):
	var direction = get_input_direction()
	
	apply_gravity(delta)
	apply_movement(direction, delta)
	update_feeding(delta)
	
	move_and_slide()


#region INPUT & MOVEMENT :=========================================================================
func get_input_direction() -> Vector3:
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_front"):
		input_dir.y += 1
	if Input.is_action_pressed("move_back"):
		input_dir.y -= 1
	
	# Interact
	if Input.is_action_just_pressed("feed"):
		var target = interaction_area.get_closest_target(global_position)
		if target:
			try_start_feeding(target)
	
	if input_dir == Vector2.ZERO:
		return Vector3.ZERO
	
	input_dir = input_dir.normalized()
	
	# camera basis
	var forward = -cam.global_transform.basis.z
	var right = cam.global_transform.basis.x
	
	# flatten (ignore Y so player doesn’t tilt)
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	return (right * input_dir.x + forward * input_dir.y).normalized()
	


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func apply_movement(direction: Vector3, delta):
	if is_feeding:
		return 
	
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
#endregion


#region FEEDING MECHANISM:=========================================================================
func try_start_feeding(target):
	if is_feeding or not can_feed:
		return
	
	is_feeding = true
	can_feed = false
	
	current_target = target
	feed_timer = 0.0
	attach_position = global_position
	
	current_target.set_feeding_active(true)


func update_feeding(delta):
	if not is_feeding:
		return
	
	feed_timer += delta
	
	var progress = feed_timer / feed_duration
	on_feed_progress(progress)
	
	if not is_still_attached():
		cancel_feeding()
		return
	
	if feed_timer >= feed_duration:
		finish_feeding()


func on_feed_progress(value: float):
	if current_target and current_target.progress_bar:
		current_target.progress_bar.value = value * 100.0 


func is_still_attached() -> bool:
	if current_target == null:
		return false
	
	if global_position.distance_to(current_target.global_position) > 2.0:
		return false
	
	if global_position.distance_to(attach_position) > 1.0: 
		return false
	
	if not Input.is_action_pressed("feed"):
		return false
	
	return true


func cancel_feeding():
	is_feeding = false
	current_target = null
	feed_timer = 0.0
	
	# TODO: play cancel sound / effect
	cleanup_feed_ui()
	
	await get_tree().create_timer(feed_cooldown).timeout
	can_feed = true


func finish_feeding():
	is_feeding = false
	cleanup_feed_ui()
	
	if current_target:
		current_target.break_system() # TODO
	
	current_target = null


func cleanup_feed_ui():  
	if current_target:
		current_target.set_feeding_active(false) 

#endregion
