extends CharacterBody3D

const LIGHT_THRESHOLD = 0.6

var player = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


const SPEED = 8.0

#region VISION VARIABLES
var can_see_player : bool = false
#endregion


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	SignalBus.connect("system_broken", _on_system_broken)

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	velocity = Vector3.ZERO
	
	var light = player.current_light_level
	if light > LIGHT_THRESHOLD:
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
	pass

func patrol():
		# temporary idle
	velocity = Vector3.ZERO
	pass
