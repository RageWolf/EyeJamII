extends Control

func _ready() -> void:
	$AnimationPlayer.play("RESET")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("pause_blur")

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("pause_blur")

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func testEsc(): 
	if Input.is_action_just_pressed("esc") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused == true:
		resume()

func _on_quit_pressed() -> void:
	get_tree().quit()

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	testEsc()
