extends Control


@onready var video_player = $VideoStreamPlayer
var timer = 0.0
var _delta = null

func _ready() -> void:
	timer = 2.0
	video_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_delta = delta


func _on_video_stream_player_finished() -> void:
	# fade to black if I can figure out how to do this
	start_timer()
		
func start_timer():
	if timer <= 0:
		LoadManager.load_scene("res://Scenes/start_menu_3d.tscn")
	else:
		timer -= _delta
		start_timer()
	
