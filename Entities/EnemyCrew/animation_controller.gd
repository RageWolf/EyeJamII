extends Node

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")



@onready var enemy = $".."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	anim_tree.set("parameters/conditions/stationary", enemy.stationary)
	anim_tree.set("parameters/conditions/patrolling", enemy.patrolling)

	
	if enemy.player_spotted:
		state_machine.travel("Alert")
		enemy.player_spotted = false
		if (enemy.check_can_see_player()):
			state_machine.travel("Walk")
		else:
			state_machine.travel("Searching")
	
	match enemy.state:
		enemy.State.PATROLLING:
			state_machine.travel("Walk")
		enemy.State.CHASING:
			state_machine.travel("Walk")
		enemy.State.IDLE:
			state_machine.travel("Idle1")
		enemy.State.SEARCHING:
			state_machine.travel("Searching")
		enemy.State.REPAIRING:
			if enemy.at_target:
				state_machine.travel("Idle1")
			else:
				state_machine.travel("Walk")
				
			

	
