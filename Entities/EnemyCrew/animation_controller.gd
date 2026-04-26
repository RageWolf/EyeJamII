extends Node

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")



@onready var enemy = $".."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	anim_tree.set("parameters/conditions/stationary", enemy.stationary)
	anim_tree.set("parameters/conditions/patrolling", enemy.patrolling)
	
	anim_tree.set("parameters/conditions/at_target", enemy.at_target_fix)
	
	# SignalBus.connect("update_anim", _on_update_anim)
	
	if enemy.state != enemy.prev_state:
		update_anim()


func update_anim():
	match enemy.state:
		enemy.State.PATROLLING:
			if enemy.at_target_patrol:
				state_machine.travel("Search")
			else:
				state_machine.travel("WalkStart")
		enemy.State.CHASING:
			state_machine.travel("Run")
		enemy.State.IDLE:
			state_machine.travel("Idle1")
		enemy.State.SEARCHING:
			state_machine.travel("Search")
		enemy.State.REPAIRING:
			if !enemy.at_target_fix:
				state_machine.travel("WalkStart")
			else:
				state_machine.travel("Fix")
		enemy.State.ALERT:
			state_machine.travel("Alert")
		enemy.State.LUNGING:
			state_machine.travel("Catch")
			
