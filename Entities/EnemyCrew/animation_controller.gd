extends Node

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")



@onready var enemy = $".."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("player_spotted", _on_player_spotted)
	SignalBus.connect("in_capture_range", _on_enter_capture_range)


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	anim_tree.set("parameters/conditions/stationary", enemy.stationary)
	anim_tree.set("parameters/conditions/patrolling", enemy.patrolling)
	
	anim_tree.set("parameters/conditions/at_target", enemy.at_target)


func update_anim():
	match enemy.state:
		enemy.State.PATROLLING:
			state_machine.travel("Walk")
		enemy.State.CHASING:
			state_machine.travel("Walk")
		enemy.State.IDLE:
			state_machine.travel("Idle1")
		enemy.State.SEARCHING:
			state_machine.travel("Search")
		enemy.State.REPAIRING:
			if !enemy.at_target:
				state_machine.travel("Walk")
			else:
				state_machine.travel("Fix")

func _on_player_spotted():
	state_machine.travel("Alert")

func _on_enter_capture_range():
	state_machine.travel("Catch")
