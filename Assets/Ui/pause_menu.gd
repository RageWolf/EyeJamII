extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  
	$AnimationPlayer.play("RESET")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("pause_blur")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("pause_blur")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		Audio.ui_cancel()
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	Audio.ui_select()
	resume()

func _on_restart_pressed() -> void:
	Audio.ui_select()
	resume()
	GameManager.reset()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	Audio.ui_select()
	get_tree().quit()




func _on_resume_focus_entered() -> void:
	Audio.ui_focus_change()

func _on_resume_mouse_entered() -> void:
	Audio.ui_focus_change()

func _on_restart_focus_entered() -> void:
	Audio.ui_focus_change()

func _on_restart_mouse_entered() -> void:
	Audio.ui_focus_change()

func _on_quit_focus_entered() -> void:
	Audio.ui_focus_change()

func _on_quit_mouse_entered() -> void:
	Audio.ui_focus_change()
