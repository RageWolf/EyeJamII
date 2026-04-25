extends CharacterBody3D

const LIGHT_THRESHOLD = 0.3
const VISION_ANGLE = 45.0
const VISION_DISTANCE = 10
const DETECTION_RANGE = 15


var player = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_area: Area3D = $Area3D
@onready var ray: RayCast3D = $RayCast3D
@onready var anim_controller = $AnimationController
@onready var patrol_points = $PatrolRoute.get_children()
@onready var player_capture_point = $Scientist/Armature/Skeleton3D/Hand_R/PlayerCapturePoint/CaptureArea/CollisionShape3D


var speed = 1.5

#region VISION VARIABLES
var can_see_player: bool = false
var lost_player: bool = false
var player_in_area: bool = false
var lighting_check: bool = false
var vision_cone_check: bool = false
var ray_check: bool = false

#endregion

enum State {PATROLLING, CHASING, REPAIRING, SEARCHING, IDLE}
var state: State = State.IDLE

@export var patrolling: bool = true
@export var stationary: bool = false

var broken_power_systems = []
var current_target = null

var at_target = false

var search_timer = 0.0
var fix_timer = 2.0

var index = 1



func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	SignalBus.connect("system_broken", _on_system_broken)
	SignalBus.connect("system_fixed", _on_system_fixed)
	if patrolling:
		state = State.PATROLLING
	else:
		state = State.IDLE

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	velocity = Vector3.ZERO
	
	can_see_player = check_can_see_player()
	
	match state:
		State.PATROLLING:
			if can_see_player:
				state = State.CHASING
			elif current_target != null:
				state = State.REPAIRING
		State.CHASING:
			if !can_see_player:
				state = State.SEARCHING
		State.IDLE:
			if can_see_player:
				state = State.CHASING
		State.SEARCHING:
			if can_see_player:
				state = State.CHASING
			elif search_timer <= 0:
				if current_target != null:
					state = State.REPAIRING
				else:
					state = State.PATROLLING
		State.REPAIRING:
			if can_see_player:
				state = State.CHASING
			elif current_target == null:
				state = State.PATROLLING

	match state:
		State.PATROLLING:
			#patrol(_delta)
			move_and_slide()
		State.CHASING:
			chase_player()
			move_and_slide()
		State.IDLE:
			velocity = Vector3.ZERO
			nav_agent.target_position = global_position
		State.SEARCHING:
			search(_delta)
		State.REPAIRING:
			search(_delta)
			move_and_slide()


func _on_system_broken(_target: Vector3, power_system):
	if (_target - global_position).length() <= DETECTION_RANGE:
		current_target = power_system
		state = State.REPAIRING
	else:
		broken_power_systems.append(power_system)
func _on_system_fixed(_power_system):
	broken_power_systems.erase(_power_system)

func chase_player():
	speed = 3.0
	move_to_waypoint(player.global_position)
	look_at_target(player)
	if (player.global_position - global_position).length() < 2.0:
		SignalBus.emit_signal("in_capture_range")
	

#func patrol(delta):
	#speed = 1.5
	#var waypoint =  patrol_points[index]
	#move_to_waypoint(waypoint)
	#look_at_target(waypoint)
	#if nav_agent.is_navigation_finished():
		#index = (index + 1) % patrol_points.size()
		#start_search(2.0)

func search(delta):
	velocity = Vector3.ZERO
	nav_agent.target_position = global_position
	search_timer -= delta
		
func start_search(time):
	search_timer = time
	state = State.SEARCHING
	

func fix_system(delta):
	speed = 1.5
	move_to_waypoint(current_target.global_position)
	look_at_target(current_target)
	if nav_agent.is_navigation_finished():
		at_target = true
		fix_timer -= delta
		if fix_timer <= 0:
			fix_timer -= delta
		current_target.fix_system()
		at_target = false
		broken_power_systems.erase(current_target)
		for power_system in broken_power_systems:
			if (power_system - global_position).length() <= DETECTION_RANGE:
				current_target = power_system
				break
		


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
	

func check_can_see_player() -> bool:
	var player_in_range = false
	# check vision cone
	if (player_in_area):
		# print("player out of range")
		player_in_range = true
	var to_player = (player.global_position - global_position).normalized()
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_player))
	# print(angle)
	if angle < VISION_ANGLE:
		vision_cone_check = true
		# print("vision cone check")
	else:
		vision_cone_check = false
	
	# check lighting
	var light = player.current_light_level
	if light > LIGHT_THRESHOLD:
		lighting_check = true
		# print("lighting check")
	else:
		lighting_check = false
	
	# check line of sight
	ray.target_position = ray.to_local(player.global_position) + Vector3(0,.5,0)
	ray.force_raycast_update()
	if ray.is_colliding():
		# print(ray.get_collider())
		if ray.get_collider() == player:
			ray_check = true
			# print("ray check")
		else:
			ray_check = false
	else:
		ray_check = false
	
	if can_see_player:
		if player.is_hidden:
			state = State.SEARCHING
			return false
		elif ray_check:
			state = State.CHASING
			return true
		else:
			state = State.SEARCHING
			return false
	elif vision_cone_check and lighting_check and ray_check:
		# print("true")
		# print()
		SignalBus.emit_signal("player_spotted")
		return true
	else:
		# print("false")
		# print()
		return false
		
func look_at_target(target):
	var direction = null
	if target is Vector3:
		direction = target - global_position
	else:
		direction = target.global_position - global_position
	direction.y = 0
	look_at(global_position + direction, Vector3.UP)
	
func move_to_waypoint(waypoint):
	if waypoint is Vector3:
		nav_agent.target_position = waypoint
	else:
		nav_agent.target_position = waypoint.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * speed
	velocity.y = 0


func _on_capture_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Player caught!")
	
