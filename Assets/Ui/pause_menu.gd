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
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	GameManager.reset()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
