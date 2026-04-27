class_name Enemy
extends CharacterBody3D

const LIGHT_THRESHOLD = 0.4
const VISION_ANGLE = 45.0
const VISION_DISTANCE = 30
const DETECTION_RANGE = 40


var player = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_area: Area3D = $Scientist/Area3D
@onready var ray: RayCast3D = $Scientist/RayCast3D
@onready var anim_controller = $AnimationController
@onready var player_capture_point = $Scientist/Armature/Skeleton3D/Hand_R/PlayerCapturePoint/CaptureArea/CollisionShape3D
@onready var player_vis = $Scientist
@onready var debug_vision_cone = $Scientist/Area3D/debug
@export var patrol_route: Node3D
@onready var patrol_points: Array = []
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer


var speed = 1.5

#region VISION VARIABLES
var can_see_player: bool = false
var lost_player: bool = false
var player_in_area: bool = false
var lighting_check: bool = false
var vision_cone_check: bool = false
var ray_check: bool = false
var player_spotted = false
var detection = false
var in_detection_area = false
#endregion

enum State {PATROLLING, CHASING, REPAIRING, SEARCHING, IDLE, ALERT, LUNGING}
var state: State = State.IDLE
var prev_state = null

@export var patrolling: bool = true
@export var stationary: bool = false
@export var num: int

var broken_power_systems = []
var current_target = null

var at_target_fix = false
var at_target_patrol = false

var search_timer = 0.0
var fix_timer = 2.0
var lunge_timer = 1.5
var alert_timer = 0.5

var index = 0

var player_caught = false
var turn = false


func _ready() -> void:
	if patrol_route:
		patrol_points = patrol_route.get_children()
	player = get_tree().get_first_node_in_group("player")
	SignalBus.connect("system_broken", _on_system_broken)
	SignalBus.connect("system_fixed", _on_system_fixed)
	if patrolling:
		state = State.PATROLLING
	else:
		state = State.IDLE
	debug_vision_cone.visible = false
	footstep_player.finished.connect(_on_footstep_finished)



func _physics_process(_delta: float) -> void:
	if player == null:
		return
	
	if not is_on_floor():
		velocity.y += -9.8 * _delta
	
	can_see_player = check_can_see_player()
	# print(can_see_player)
	if num == 1:
		print(state)
	match state:
		State.PATROLLING:
			if can_see_player:
				if detection:
					prev_state = state
					state = State.ALERT
				else:
					prev_state = state
					state = State.CHASING
			elif current_target != null:
				prev_state = state
				state = State.REPAIRING
		State.CHASING:
			if !can_see_player:
				start_search(5.0)
			else:
				prev_state = state
				state = State.CHASING

		State.IDLE:
			if can_see_player:
				if detection:
					prev_state = state
					state = State.ALERT
				else:
					prev_state = state
					state = State.CHASING

		State.SEARCHING:
			if can_see_player:
				if detection:
					prev_state = state
					state = State.ALERT
				else:
					prev_state = state
					state = State.CHASING
			elif search_timer <= 0:
				if current_target != null:
					prev_state = state
					state = State.REPAIRING
				else:
					prev_state = state
					state = State.PATROLLING

		State.REPAIRING:
			if can_see_player:
				if detection:
					prev_state = state
					state = State.ALERT
				else:
					prev_state = state
					state = State.CHASING
			elif current_target == null:
				prev_state = state
				state = State.PATROLLING
		State.LUNGING:
			stop_walk()
			if player_caught:
				GameManager.player_caught = true
			elif lunge_timer <= 0:
				lunge_timer = 1.5
				prev_state = state
				state = State.CHASING
			else:
				lunge_timer -= _delta

		State.ALERT:
			stop_walk()
			detection = false
			if alert_timer <= 0:
				alert_timer = 0.5
				if can_see_player:
					prev_state = state
					state = State.CHASING
				else:
					start_search(5.0)
			else:
				alert_timer -= _delta
			

	match state:
		State.PATROLLING:
			patrol(_delta)
			play_walk()
		State.CHASING:
			play_walk()
			# print("chasing")
			chase_player()
		State.IDLE:
			stop_walk()
			velocity = Vector3.ZERO
			nav_agent.target_position = global_position
		State.SEARCHING:
			velocity = Vector3.ZERO
			nav_agent.target_position = global_position
			search(_delta)
			stop_walk()
		State.REPAIRING:
			play_walk()
			fix_system(_delta)

	move_and_slide()


#region AUDIO:
func _on_footstep_finished() -> void:
	if footstep_player.stream != null:
		footstep_player.play(randf_range(0.0, footstep_player.stream.get_length()))

func play_walk() -> void:
	if footstep_player.playing: return
	footstep_player.play(randf_range(0.0, footstep_player.stream.get_length()))

func stop_walk() -> void:
	footstep_player.stop()
#endregion



func _on_system_broken(_target: Vector3, power_system):
	if power_system.tutorial_system == false:
		broken_power_systems.append(power_system)
		if (_target - global_position).length() <= DETECTION_RANGE and current_target == null:
			current_target = power_system
			prev_state = state
			state = State.REPAIRING
	else:
		return


func _on_system_fixed(_power_system):
	broken_power_systems.erase(_power_system)


func chase_player():
	speed = 6.0
	nav_agent.target_position = player.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	next_nav_point.y = 0
	var direction = (next_nav_point - global_position).normalized()
	velocity.x = direction.x * speed  
	velocity.z = direction.z * speed
	look_at_target(player)
	if (player.global_position - global_position).length() < 3.5:
		prev_state = state
		state = State.LUNGING


func patrol(_delta):
	if patrol_points.size() == 0:
		return
	speed = 1.5
	var waypoint = patrol_points[index]
	#if num == 1:
		#print(index)
	

	nav_agent.target_position = waypoint.global_position
	
	move_to_waypoint(waypoint.global_position)
	if nav_agent.is_navigation_finished():
		at_target_patrol = true
		index = (index + 1) % patrol_points.size()
		start_search(5.0)
		at_target_patrol = false


func search(delta):
	search_timer -= delta
		
func start_search(time):
	search_timer = time
	prev_state = state
	state = State.SEARCHING


func fix_system(delta):
	speed = 1.5
	move_to_waypoint(current_target.global_position)
	if nav_agent.is_navigation_finished():
		at_target_fix = true
		SignalBus.emit_signal("update_anim")
		fix_timer -= delta
		if fix_timer <= 0:
			current_target.fix_system()
			at_target_fix = false
			SignalBus.emit_signal("update_anim")
			broken_power_systems.erase(current_target)
			fix_timer = 2.0
			current_target = null
			for power_system in broken_power_systems:
				if (power_system.global_position - global_position).length() <= DETECTION_RANGE:
					current_target = power_system
					break 
			nav_agent.target_position = patrol_points[index].global_position



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false



func check_can_see_player() -> bool:
	# check angle - if no then no see
	var to_player = (player.global_position - global_position).normalized()
	var forward = player_vis.global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_player))
	if angle < VISION_ANGLE:
		vision_cone_check = true
	else:
		vision_cone_check = false

	# check distance 
	var dist = global_position.distance_to(player.global_position)
	var in_vision_range = dist <= VISION_DISTANCE

	# check line of sight 
	if vision_cone_check and in_vision_range:
		ray.target_position = ray.to_local(player.global_position) + Vector3(0, .5, 0)
		ray.force_raycast_update()
		if ray.is_colliding():
			if ray.get_collider() == player:
				ray_check = true
			else:
				ray_check = false
		else:
			ray_check = false
	else:
		ray_check = false

	# check lighting
	var light = player.current_light_level
	if light > LIGHT_THRESHOLD:
		lighting_check = true
	else:
		lighting_check = false

	if player.is_hidden:
			player_spotted = false
			return false
	if player_spotted:
		# must be in angle and range to keep tracking
		if ray_check and (vision_cone_check or in_vision_range):
			return true
		else:
			player_spotted = false
			return false

	# in vision cone (angle + range) + ray = sees, no light needed
	elif vision_cone_check and in_vision_range and ray_check:
		player_spotted = true
		detection = false
		return true

	# in light + angle + ray = sees even at distance
	elif vision_cone_check and lighting_check and ray_check:
		player_spotted = true
		detection = true
		return true

	# detection area 
	elif in_detection_area:
		player_spotted = true
		detection = true
		return true

	else:
		return false


func look_at_target(target):
	var direction = null
	if target is Vector3:
		direction = target - global_position
	else:
		direction = target.global_position - global_position
	direction.y = 0  
	if direction.length() < 0.05:
		return
	var look_pos = global_position - direction.normalized()
	look_pos.y = global_position.y
	player_vis.look_at(look_pos, Vector3.UP)
	player_vis.rotation.x = 0.0 
	player_vis.rotation.z = 0.0


func move_to_waypoint(waypoint):
	var target_position = null
	if waypoint is Vector3:
		nav_agent.target_position = waypoint
	else:
		nav_agent.target_position = waypoint.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	next_nav_point.y = 0
	var my_pos_flat = Vector3(global_position.x, 0, global_position.z)
	var direction = (next_nav_point - my_pos_flat).normalized()
	
	var target_velocity = Vector3(direction.x * speed, 0, direction.z * speed)
	velocity.x = move_toward(velocity.x, target_velocity.x, speed * 0.25)
	velocity.z = move_toward(velocity.z, target_velocity.z, speed * 0.25)
	
	# do 'direction = global_position - velocity' for moonwalking mode
	if direction.length() > 0.05 and abs(direction.y) < 0.99:
		var look_pos = global_position - direction
		look_pos.y = global_position.y
		player_vis.look_at(look_pos, Vector3.UP)
		player_vis.rotation.x = 0.0  
		player_vis.rotation.z = 0.0  

func _on_capture_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Player caught!")
		player_caught = true


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		in_detection_area = true


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		in_detection_area = false
