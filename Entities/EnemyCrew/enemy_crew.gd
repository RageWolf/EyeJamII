class_name Enemy
extends CharacterBody3D

var _nav_timer: float = 0.0
const NAV_UPDATE_INTERVAL: float = 0.1
var _cached_next_nav_point: Vector3 = Vector3.ZERO

const LIGHT_THRESHOLD = 0.8
const VISION_ANGLE = 45.0
const DETECTION_RANGE = 40
const VISION_DISTANCE_CLOSE = 10       # always sees within this range (if in cone + raycast)
const VISION_DISTANCE_FAR = 30         # only sees this far if player is lit

# Squared versions
const VISION_DISTANCE_CLOSE_SQ = VISION_DISTANCE_CLOSE * VISION_DISTANCE_CLOSE
const VISION_DISTANCE_FAR_SQ = VISION_DISTANCE_FAR * VISION_DISTANCE_FAR
const DETECTION_RANGE_SQ = DETECTION_RANGE * DETECTION_RANGE
const LUNGE_DISTANCE_SQ = 3.5 * 3.5

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

# Vision check throttle to avoid running the expensive check every physics frame
var _vision_timer: float = 0.0
const VISION_CHECK_INTERVAL: float = 0.2

# Tracks whether stop_walk has already been called for the current state,
# so we don't call it redundantly every frame
var _walk_stopped: bool = false


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
	
	# offsets each enemy's vision check so they don't all fire together
	_vision_timer = randf_range(0.0, VISION_CHECK_INTERVAL)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	
	if not is_on_floor():
		velocity.y += -9.8 * _delta
	
	# Throttle vision check: only update every VISION_CHECK_INTERVAL seconds
	_vision_timer -= _delta
	if _vision_timer <= 0.0:
		_vision_timer = VISION_CHECK_INTERVAL
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
			_stop_walk_once()
			if player_caught:
				GameManager.player_caught = true
			elif lunge_timer <= 0:
				lunge_timer = 1.5
				prev_state = state
				state = State.CHASING
			else:
				lunge_timer -= _delta

		State.ALERT:
			_stop_walk_once()
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
			_walk_stopped = false
			patrol(_delta)
			play_walk()
		State.CHASING:
			_walk_stopped = false
			play_walk()
			# print("chasing")
			chase_player()
		State.IDLE:
			_stop_walk_once()
			velocity = Vector3.ZERO
			nav_agent.target_position = global_position
		State.SEARCHING:
			_stop_walk_once()
			velocity = Vector3.ZERO
			nav_agent.target_position = global_position
			search(_delta)
		State.REPAIRING:
			_walk_stopped = false
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

# Only calls stop_walk once per state entry, avoids stopping every frame
func _stop_walk_once() -> void:
	if not _walk_stopped:
		stop_walk()
		_walk_stopped = true
#endregion



func _on_system_broken(_target: Vector3, power_system):
	if power_system.tutorial_system == false:
		broken_power_systems.append(power_system)
		# Use squared distance to avoid sqrt
		if (_target - global_position).length_squared() <= DETECTION_RANGE_SQ and current_target == null:
			current_target = power_system
			prev_state = state
			state = State.REPAIRING


func _on_system_fixed(_power_system):
	broken_power_systems.erase(_power_system)


func chase_player():
	speed = 6.0
	nav_agent.target_position = player.global_position
	_nav_timer -= get_physics_process_delta_time()
	if _nav_timer <= 0.0:
		_nav_timer = NAV_UPDATE_INTERVAL
		_cached_next_nav_point = nav_agent.get_next_path_position()
		_cached_next_nav_point.y = 0
	var direction = (_cached_next_nav_point - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	look_at_target(player)
	if global_position.distance_squared_to(player.global_position) < LUNGE_DISTANCE_SQ:
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
				# Use squared distance to avoid sqrt
				if (power_system.global_position - global_position).length_squared() <= DETECTION_RANGE_SQ:
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
	vision_cone_check = angle < VISION_ANGLE

	# check distance - split into close and far ranges
	var dist_sq = global_position.distance_squared_to(player.global_position)
	var in_close_range = dist_sq <= VISION_DISTANCE_CLOSE_SQ
	var in_far_range = dist_sq <= VISION_DISTANCE_FAR_SQ

	# check line of sight - only cast ray if in cone AND within far range
	if vision_cone_check and in_far_range:
		ray.target_position = ray.to_local(player.global_position) + Vector3(0, .5, 0)
		ray.force_raycast_update()
		if ray.is_colliding():
			ray_check = ray.get_collider() == player
		else:
			ray_check = false
	else:
		ray_check = false

	# check lighting
	lighting_check = player.current_light_level > LIGHT_THRESHOLD

	if player.is_hidden:
		player_spotted = false
		return false

	if player_spotted:
		# must be in angle and range to keep tracking
		if ray_check and (vision_cone_check or in_far_range):
			return true
		else:
			player_spotted = false
			return false

	# close range: in cone + close distance + raycast - no light needed
	elif vision_cone_check and in_close_range and ray_check:
		player_spotted = true
		detection = false
		return true

	# far range: in cone + far distance + lit + raycast - light required
	elif vision_cone_check and in_far_range and lighting_check and ray_check:
		player_spotted = true
		detection = true
		return true

	# detection area: always sees regardless of range or light
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
	if waypoint is Vector3:
		nav_agent.target_position = waypoint
	else:
		nav_agent.target_position = waypoint.global_position
	_nav_timer -= get_physics_process_delta_time()
	if _nav_timer <= 0.0:
		_nav_timer = NAV_UPDATE_INTERVAL
		_cached_next_nav_point = nav_agent.get_next_path_position()
		_cached_next_nav_point.y = 0
	var my_pos_flat = Vector3(global_position.x, 0, global_position.z)
	var direction = (_cached_next_nav_point - my_pos_flat).normalized()
	
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
