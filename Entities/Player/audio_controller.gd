extends Node

@onready var jump: AudioStreamPlayer3D = $"../Jump"

func play_jump():
	jump.play()
