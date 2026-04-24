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
var current_light_level : float = 0.0
@onready var sub_viewport: SubViewport = $SubViewport
@onready var light_detection: Node3D = $SubViewport/LightDetection
@onready var texture_rect: TextureRect = $Control/TextureRect
@onready var light_level: TextureProgressBar = $Control/LightLevel
@onready var color_rect: ColorRect = $Control/ColorRect
#endregion

#region MOVEMENT VARIABLES
@export var SPEED = 4.0
@export var GRAVITY = -9.8
@export var ACCELERATION = 15.0
@export var FRICTION = 12.0
#endregion

#region HIDING VARIABLES
var is_hidden: bool = false
var player_inside_stealth_zone : bool = false
#endregion

#animation
@onready var anim_controller = $AnimationController


func _ready():
	if camera:
		cam = get_node(camera)
	
	sub_viewport.debug_draw = Viewport.DEBUG_DRAW_LIGHTING
	update_light_loop()




func _physics_process(delta):
	var direction = get_input_direction()
	
	apply_gravity(delta)
	apply_movement(direction, delta)
	update_feeding(delta)
	update_stealth()


	anim_controller.update(delta, velocity, direction)

	move_and_slide()
	var cam_y = spring_arm_pivot.rotation.y
	monster.rotation.y = lerp_angle(monster.rotation.y, cam_y , 10.0 * delta)



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


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
#endregion



#region LIGHT DETECTION :=========================================================================
func update_light_loop():
	while is_inside_tree():
		update_light()
		await get_tree().create_timer(0.1).timeout

func update_light():
	light_detection.global_position = global_position
	
	var texture := sub_viewport.get_texture()
	texture_rect.texture = texture
	
	var color := get_average_color(texture)
	color_rect.color = color
	
	var luminance := color.get_luminance()
	
	current_light_level = luminance 
	light_level.value = luminance * 100
	light_level.tint_progress.a = luminance


func get_average_color(texture: ViewportTexture) -> Color:
	var image := texture.get_image()
	if image.is_empty():
		return Color.BLACK
	
	image.resize(1, 1)
	return image.get_pixel(0, 0)

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
	
	current_target.set_feeding_active(true, can_feed)
	anim_controller.play_feeding()

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
	
	# TODO: play cancel sound / effect
	
	var target = current_target
	current_target = null
	
	await get_tree().create_timer(feed_cooldown).timeout
	can_feed = true
	
	if target:
		target.set_feeding_active(false, can_feed)



func finish_feeding():
	is_feeding = false
	cleanup_feed_ui()
	
	if current_target:
		current_target.break_system()
	
	current_target = null


func cleanup_feed_ui():
	anim_controller.stop_feeding()
	if current_target:
		current_target.set_feeding_active(false, can_feed)

#endregion



#region HIDING MECHANISM :=========================================================================
func update_stealth():
	var is_moving = velocity.length() > 0.1
	
	if player_inside_stealth_zone and not is_moving:
		set_hidden(true)
	else:
		set_hidden(false)

func set_hidden(state: bool):
	if is_hidden == state:
		return
	
	is_hidden = state
	if is_hidden:
		# Disable collision
		
		collision_layer = 3
	else:
		# Restore collision
		collision_layer = 2

#endregion
