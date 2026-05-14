class_name Player extends CharacterBody3D

#region CAMERA VARIABLES
@onready var monster: Node3D = $Monster
@onready var spring_arm_pivot: Node3D = $SpringArmPivot
@export var camera: NodePath
var cam: Camera3D
#endregion 

#region FEEDING VARIABLES
@onready var interaction_area: InteractionArea = $InteractionArea
var interact_ui_visible := false

var is_feeding := false
var feed_timer := 0.0
var feed_duration := 2.0  # seconds to fully drain
var feed_cooldown := 1.0
var can_feed := true
var current_target = null
var attach_position: Vector3
#endregion 

#region LIGHT DETECTION VRIABLES
var _light_timer: float = 0.0
const LIGHT_CHECK_INTERVAL: float = 0.15
var current_light_level : float = 0.0
var _nearby_lights: Array = []
@onready var light_level: TextureProgressBar = $CanvasLayer/Control/LightLevel
@onready var color_rect: ColorRect = $CanvasLayer/Control/ColorRect
#endregion

#region MOVEMENT VARIABLES
@export var SPEED = 4.0
@export var GRAVITY = -9.8
@export var ACCELERATION = 15.0
@export var FRICTION = 12.0
@export var JUMP_HOLD_FORCE = 2.5
@export var JUMP_MAX_TIME = 0.3 
@export var JUMP_VELOCITY = 4.5 
var jump_hold_timer := 0.0
#endregion

#region HIDING VARIABLES
var is_hidden: bool = false
var player_inside_stealth_zone : bool = false
#endregion

#region ANIMATION AND AUDIO VARIABLES
@onready var anim_controller = $AnimationController
@onready var audio_controller: Node = $AudioController
var _footstep_timer: float = 0.0
const FOOTSTEP_CHECK_INTERVAL: float = 0.05 
var trill_timer := 0.0
#endregion ANIMATION AND AUDIO

func _ready():
	# debug only
	if OS.is_debug_build():
		#SPEED = 15.0
		pass

	if camera:
		cam = get_node(camera)
	
	_nearby_lights = get_tree().get_nodes_in_group("world_light")

func _physics_process(delta):
	var direction = get_input_direction()
	
	apply_gravity(delta)
	apply_movement(direction, delta)
	update_feeding(delta)
	update_stealth(delta)

	handle_trill(delta)
	anim_controller.update(delta, velocity, direction)

	move_and_slide()
	var cam_y = spring_arm_pivot.rotation.y
	monster.rotation.y = lerp_angle(monster.rotation.y, cam_y , 10.0 * delta)
	
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = FOOTSTEP_CHECK_INTERVAL
		handle_footsteps()
	
	_light_timer -= delta
	if _light_timer <= 0.0:
		_light_timer = LIGHT_CHECK_INTERVAL
		update_light()

func handle_footsteps() -> void:
	var is_moving: bool = velocity.length_squared() > 0.01
	var on_floor: bool = is_on_floor()
	if is_moving and on_floor and not is_feeding:
		audio_controller.play_walk()
	else:
		audio_controller.stop_walk()

func handle_trill(delta):
	var is_moving = velocity.length() > 0.1
	var is_airborne = not is_on_floor()
	
	# trill idle on ground
	if is_moving or is_airborne or is_feeding:
		trill_timer = randf_range(5.0, 8.0) 
		return
	
	trill_timer -= delta
	if trill_timer <= 0:
		audio_controller.play_trill()
		trill_timer = randf_range(5.0, 10.0) 

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


func apply_movement(direction: Vector3, delta):
	if is_feeding:
		velocity = Vector3.ZERO
		return

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
		
		#hard stop
	if abs(velocity.x) < 0.05:
		velocity.x = 0
	if abs(velocity.z) < 0.05:
		velocity.z = 0


func apply_gravity(delta):
	if not is_on_floor():
		if Input.is_action_pressed("jump") and jump_hold_timer > 0:
			velocity.y += JUMP_HOLD_FORCE * delta
			jump_hold_timer -= delta
		else:
			jump_hold_timer = 0.0  
			velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed("jump") and not is_feeding:
		jump()

func jump():
	anim_controller.is_jumping = true
	velocity.y = JUMP_VELOCITY
	jump_hold_timer = JUMP_MAX_TIME
	audio_controller.play_jump()

#endregion


#region LIGHT DETECTION :=========================================================================
func update_light() -> void:
	var luminance: float = calculate_light_at_position(global_position)
	current_light_level = luminance
	light_level.value = luminance * 100.0
	light_level.tint_progress.a = luminance
	color_rect.color = Color(luminance, luminance, luminance)

func calculate_light_at_position(pos: Vector3) -> float:
	var total_light: float = 0.0
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space_state == null:
		return 0.0

	for light: Node in _nearby_lights:
		if not light.visible:
			continue

		var dist: float = pos.distance_to(light.global_position)
		var light_range: float = light.omni_range if light is OmniLight3D else light.spot_range
		if dist >= light_range:
			continue

		# spotlight cone check
		if light is SpotLight3D:
			var to_player: Vector3 = (pos - light.global_position).normalized()
			var light_dir: Vector3 = -light.global_transform.basis.z
			var angle: float = rad_to_deg(light_dir.angle_to(to_player))
			if angle > light.spot_angle:
				continue

		var contribution: float = (1.0 - (dist / light_range)) * light.light_energy
		total_light += contribution

	return clampf(total_light, 0.0, 1.0)

#endregion


#region FEEDING MECHANISM:=========================================================================
func try_start_feeding(target):
	if target.is_broken:
		return
	if is_feeding or not can_feed:
		return
	
	is_feeding = true
	can_feed = false
	
	current_target = target
	feed_timer = 0.0
	attach_position = global_position
	
	current_target.set_feeding_active(true, can_feed)
	anim_controller.play_feeding()
	audio_controller.play_drain() 

func update_feeding(delta):
	if not is_feeding:
		return
	
	feed_timer += delta
	
	
	var progress = feed_timer / feed_duration
	on_feed_progress(progress)
	
	var intensity = lerp(0.02, 0.08, progress)
	SignalBus.screen_shake.emit(intensity)
	
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
	feed_timer = 0.0
	cleanup_feed_ui()
	audio_controller.stop_drain()
	
	
	var target = current_target
	current_target = null
	
	await get_tree().create_timer(feed_cooldown).timeout
	can_feed = true
	
	if target:
		target.set_feeding_active(false, can_feed)



func finish_feeding():
	is_feeding = false
	cleanup_feed_ui()
	audio_controller.stop_drain()
	
	if current_target:
		current_target.break_system()
	
	current_target = null
	
	await get_tree().create_timer(feed_cooldown).timeout
	can_feed = true


func cleanup_feed_ui():
	anim_controller.stop_feeding()
	if current_target:
		current_target.set_feeding_active(false, can_feed)

#endregion


#region HIDING MECHANISM :=========================================================================
func update_stealth(delta):
	var is_moving = velocity.length() > 0.1
	var is_airborne = not is_on_floor()
	if player_inside_stealth_zone and not is_moving and not is_airborne:
		set_hidden(true)
	else:
		set_hidden(false)
	
	var target_alpha = 0.0 if is_hidden else 1.0
	light_level.modulate.a = lerp(light_level.modulate.a, target_alpha, 6.0 * delta)

func set_hidden(state: bool):
	if is_hidden == state:
		return
	is_hidden = state
	if state:
		audio_controller.play_hide()
	
	if is_hidden:
		GameManager.tutorial_stealth_done = true
		GameManager.check_tutorial_complete()
#endregion
