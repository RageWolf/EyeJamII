# SAVEMANAGER
extends Node

var PHASE_1 : bool = false
var PHASE_2 : bool = false
var PHASE_3 : bool = false

var time_limit : float = 1200

var timer : float = 0
var power_level : float


func _ready() -> void:
	game_start()

func game_start():
	
	while time_limit > 0:
		time_limit -= 1 
		await get_tree().create_timer(1.0).timeout
		print(time_limit)
