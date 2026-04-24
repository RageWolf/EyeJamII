extends CharacterBody3D

const LIGHT_THRESHOLD = 0.3
const VISION_ANGLE = 45.0
const VISION_DISTANCE = 10


var player = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_area: Area3D = $Area3D
@onready var ray: RayCast3D = $RayCast3D
@onready var anim_controller = $AnimationController


const SPEED = 3.0

#region VISION VARIABLES
var can_see_player: bool = false
var player_in_area: bool = false
var lighting_check: bool = false
var vision_cone_check: bool = false
var ray_check: bool = false

#endregion

enum State {PATROLLING, CHASING, REPAIRING, SEARCHING, IDLE}
var state: State = State.IDLE
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	SignalBus.connect("system_broken", _on_system_broken)

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	velocity = Vector3.ZERO
	

	if check_can_see_player():
		print("chase player")
		chase_player()
	else:
		patrol()
	
	move_and_slide()

func _on_system_broken(_target: Vector3):
	#navigate to target
	#fix system
	pass

func chase_player():
	nav_agent.target_position = player.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED
	var player_direction = player.global_position - global_position
	player_direction.y = 0
	look_at(global_position + player_direction, Vector3.UP)
	

func patrol():
		# temporary idle
	velocity = Vector3.ZERO
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true


func _on_area_3d_body_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.is_in_group("player"):
		player_in_area = false
	

func check_can_see_player() -> bool:
	# check vision cone
	if !(player_in_area):
		print("player out of range")
		return false
	var to_player = (player.global_position - global_position).normalized()
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_player))
	print(angle)
	if angle < VISION_ANGLE:
		vision_cone_check = true
		print("vision cone check")
	else:
		vision_cone_check = false
	
	# check lighting
	var light = player.current_light_level
	if light > LIGHT_THRESHOLD:
		lighting_check = true
		print("lighting check")
	else:
		lighting_check = false
	
	# check line of sight
	ray.target_position = ray.to_local(player.global_position) + Vector3(0,.5,0)
	ray.force_raycast_update()
	if ray.is_colliding():
		print(ray.get_collider())
		if ray.get_collider() == player:
			ray_check = true
			print("ray check")
		else:
			ray_check = false
	else:
		ray_check = false
	
	if vision_cone_check and lighting_check and ray_check:
		print("true")
		print()
		return true
	else:
		print("false")
		print()
		return false

	
	
	
