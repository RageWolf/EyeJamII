extends Node

@export var jump_sounds: Array[AudioStream] = []
@export var trill_sounds: Array[AudioStream] = []
@export var drain_sounds: Array[AudioStream] = []
@export var hide_sounds: Array[AudioStream] = []

@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var drain_player: AudioStreamPlayer = $DrainPlayer
var _stream_length: float = 0.0


func _ready() -> void:
	footstep_player.finished.connect(_on_footstep_finished)
	_stream_length = footstep_player.stream.get_length()
	
	footstep_player.volume_db = -80.0
	footstep_player.play(randf_range(0.0, _stream_length))
	await get_tree().process_frame
	_prewarm(jump_sounds)
	_prewarm(hide_sounds)

func _prewarm(sounds: Array[AudioStream]) -> void:
	for sound: AudioStream in sounds:
		Audio.play_sound_3d(sound, get_parent().global_position, -80.0)

func _on_footstep_finished() -> void:
	footstep_player.play(randf_range(0.0, _stream_length))

func play_walk() -> void:
	footstep_player.volume_db = 0.0

func stop_walk() -> void:
	footstep_player.volume_db = -80.0

func play_jump() -> void:
	if jump_sounds.is_empty(): return
	Audio.play_sound_3d(jump_sounds[randi() % jump_sounds.size()], get_parent().global_position)

func play_trill() -> void:
	if trill_sounds.is_empty(): return
	Audio.play_sound_3d(trill_sounds[randi() % trill_sounds.size()], get_parent().global_position)

func play_drain() -> void:
	drain_player.play()

func stop_drain() -> void:
	drain_player.stop()

func play_hide() -> void:
	if hide_sounds.is_empty(): return
	Audio.play_sound_3d(hide_sounds[randi() % hide_sounds.size()], get_parent().global_position, -5)
