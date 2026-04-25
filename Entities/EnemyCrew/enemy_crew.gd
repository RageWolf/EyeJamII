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


var speed = 1.0

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

var player_spotted = false
var at_target = false



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
	
	if check_can_see_player():
		state = State.CHASING
	elif current_target != null:
		state = State.REPAIRING
	else:
		state = State.PATROLLING

	match state:
		State.PATROLLING:
			patrol(_delta)
		State.CHASING:
			chase_player()
		State.IDLE:
			pass
		State.SEARCHING:
			search(5.0, _delta)
		State.REPAIRING:
			fix_system(current_target, _delta)

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
	speed = 2.0
	nav_agent.target_position = player.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * speed
	var player_direction = player.global_position - global_position
	player_direction.y = 0
	look_at(global_position + player_direction, Vector3.UP)
	if (player.global_position - global_position).length() < 0.3:
		player_caught()
	

func patrol(delta):
	speed = 1.5
	velocity = Vector3.ZERO
	for waypoint in patrol_points:
		var direction = waypoint.global_position - global_position
		direction.y = 0
		look_at(global_position + direction, Vector3.UP)
		nav_agent.target_position = waypoint
		var next_nav_point = nav_agent.get_next_path_position()
		velocity = (next_nav_point - global_position).normalized() * speed
		if nav_agent.is_navigation_finished():
			search(2, delta)

func search(search_time, delta):
	while search_time >= 0:
		search_time -= delta
		if check_can_see_player():
			state = State.CHASING
	if current_target != null:
		state = State.REPAIRING
	else:
		state = State.PATROLLING
	
func fix_system(power_system, delta):
	nav_agent.target_position = power_system.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * speed
	var direction = next_nav_point
	direction.y = 0
	look_at(global_position + direction, Vector3.UP)
	if nav_agent.is_navigation_finished():
		at_target = true
		var fix_timer = 1.5
		while fix_timer > 0:
			fix_timer -= delta
		power_system.fix_system()
		at_target = false
		
	
func player_caught():
	print("Player caught")
	state = State.IDLE


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
	

func check_can_see_player() -> bool:
	# check vision cone
	if !(player_in_area):
		# print("player out of range")
		return false
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
		if ray_check:
			can_see_player = true
			state = State.CHASING
			return true
		else:
			can_see_player = false
			state = State.SEARCHING
			return false
	elif vision_cone_check and lighting_check and ray_check:
		# print("true")
		# print()
		can_see_player = true
		player_spotted = true
		return true
	else:
		# print("false")
		# print()
		can_see_player = false
		player_spotted = false
		return false
