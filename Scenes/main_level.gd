extends Node3D

@export var Phase1 : AudioStream
@export var Phase2 : AudioStream
@export var Phase3 : AudioStream

func _ready() -> void:
	Audio.fade_in_first_track(Phase1, 0.0)   
	if GameManager.PHASE_2:
		Audio.play_ambience(Phase2, 0.0)
	if GameManager.PHASE_3:
		Audio.play_ambience(Phase3, -6.0)
