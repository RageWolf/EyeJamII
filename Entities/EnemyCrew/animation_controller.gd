extends Node

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
