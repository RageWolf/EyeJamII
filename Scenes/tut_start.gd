extends Node3D

func _ready():
	await get_tree().create_timer(1.0).timeout
	GameManager.show_dialog("Try feeding on that power source.")
