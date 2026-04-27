extends Node3D

@export var phase1 : AudioStream
@export var phase2 : AudioStream
@export var phase3 : AudioStream

func _ready():
	Audio.fade_in_first_track(phase1)
	await get_tree().create_timer(1.0).timeout
	GameManager.show_dialog("Try feeding on that power source.")
	


func _on_phase_2():
	Audio.play_ambience(phase2, 0.0)

func _on_phase_3():
	Audio.play_ambience(phase3, -6.0)
