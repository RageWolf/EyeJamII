extends Control

var dialogue_completed: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dialogue_completed:
		LoadManager.load_scene("res://Scenes/main_level.tscn")


func _on_button_pressed() -> void:
	pass # next dialogue line
	
func next_line():
	pass
	
