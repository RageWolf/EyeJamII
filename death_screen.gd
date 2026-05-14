extends Control


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_restart_pressed() -> void:
	Audio.ui_select()
	GameManager.reset()
	GameManager.tutorial_completed = true
	LoadManager.load_scene("res://Scenes/main_level.tscn")


func _on_quit_pressed() -> void:
	Audio.ui_select()
	get_tree().quit()


func _on_restart_mouse_entered() -> void:
	Audio.ui_focus_change()


func _on_quit_mouse_entered() -> void:
	Audio.ui_focus_change()


func _on_restart_focus_entered() -> void:
	Audio.ui_focus_change()


func _on_quit_focus_entered() -> void:
	Audio.ui_focus_change()
