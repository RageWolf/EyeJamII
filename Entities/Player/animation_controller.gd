extends Node

@onready var anim_tree: AnimationTree = $"../AnimationTree"
@onready var state_machine = anim_tree.get("parameters/playback")
@onready var player: Player = $".."

var was_hidden : bool = false

var idle_anims = ["Idle1", "Idle2", "Idle3"]
var idle_timer := 0.0
var idle_duration := randf_range(3.0, 8.0)

func update(delta: float, velocity: Vector3, direction: Vector3):
	var target = Vector2(direction.x, -direction.z)
	var is_moving = velocity.length() > 0.1
	
	#print("is_moving: ", is_moving, " | current: ", state_machine.get_current_node())
	
	# HIDE TRANSITION
	if player.is_hidden and not was_hidden:
		state_machine.travel("Hide")
	
	elif not player.is_hidden and was_hidden:
		state_machine.travel("Idle1")

	was_hidden = player.is_hidden

	# hidden : stop everything else
	if player.is_hidden:
		return
	
	# conditions
	anim_tree.set("parameters/conditions/is_running", is_moving and not player.is_feeding)
	anim_tree.set("parameters/conditions/is_idle", not is_moving and not player.is_feeding)
	anim_tree.set("parameters/conditions/is_draining", player.is_feeding)
	anim_tree.set("parameters/conditions/stop_draining", not player.is_feeding)
	
	# blend position relative to mesh facing
	if is_moving:
		var current = state_machine.get_current_node()
		if current == "Idle2" or current == "Idle3":
			state_machine.travel("Run")
		var mesh_angle = player.monster.rotation.y
		var cos_a = cos(-mesh_angle)
		var sin_a = sin(-mesh_angle)
		
		var rotated = Vector2(
			target.x * cos_a - target.y * sin_a,
			target.x * sin_a + target.y * cos_a
		)
		
		var blend = anim_tree.get("parameters/Run/blend_position")
		anim_tree.set("parameters/Run/blend_position", blend.lerp(rotated, 8 * delta))
	
	# random idle
	if not is_moving and not player.is_feeding:
		idle_timer += delta
		#print(idle_timer)
		if idle_timer >= idle_duration:
			idle_timer = 0.0
			idle_duration = randf_range(3.0, 8.0)
			state_machine.travel(idle_anims.pick_random())
	else:
		idle_timer = 0.0

func play_feeding():
	state_machine.travel("Drain")
func stop_feeding():
	state_machine.travel("Idle1")
