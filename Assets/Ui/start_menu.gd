extends Control

@onready var start: Button = $VBoxContainer/Start
var has_focused := false

func _on_start_pressed() -> void:
	LoadManager.load_scene("res://Scenes/main_level.tscn")

func _on_credits_pressed() -> void:
	LoadManager.load_scene("res://Scenes/credits_3d.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if has_focused:
		return
	
	if event is InputEventKey and event.pressed:
		start.grab_focus()
		has_focused = true
