extends Node3D

func _ready() -> void:
	$Boudicca.visible = false
	$Muntz.visible = false
	$InfiniVerse.visible = false
	$Edward.visible = false
	$Nikki.visible = false
	$"Dominic and Rage".visible = false
	$AnimationPlayer.play("Credits")


func _unhandled_input(event):
	if event.is_action_pressed("esc") or event.is_action_pressed("click"):
		credits_finished()

func credits_finished():
	get_tree().change_scene_to_file("res://Scenes/start_menu_3d.tscn")
	queue_free()
