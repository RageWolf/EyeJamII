extends Control

@onready var start: Button = $VBoxContainer/Start
var has_focused := false

func _on_start_pressed() -> void:
	Audio.ui_select()
	LoadManager.load_scene("res://Scenes/opening_cutscene.tscn")

func _on_credits_pressed() -> void:
	Audio.ui_select()
	LoadManager.load_scene("res://Scenes/credits_3d.tscn")

func _on_quit_pressed() -> void:
	Audio.ui_select()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if has_focused:
		return
	
	if event is InputEventKey and event.pressed:
		start.grab_focus()
		has_focused = true


func _on_start_focus_entered() -> void:
	Audio.ui_focus_change()

func _on_credits_focus_entered() -> void:
	Audio.ui_focus_change()

func _on_quit_focus_entered() -> void:
	Audio.ui_focus_change()

func _on_start_mouse_entered() -> void:
	Audio.ui_focus_change()

func _on_credits_mouse_entered() -> void:
	Audio.ui_focus_change()

func _on_quit_mouse_entered() -> void:
	Audio.ui_focus_change()
