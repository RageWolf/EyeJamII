extends Node

@export var jump_sounds: Array[AudioStream] = []
@export var trill_sounds: Array[AudioStream] = []
@export var drain_sounds: Array[AudioStream] = []
@export var hide_sounds: Array[AudioStream] = []

@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var drain_player: AudioStreamPlayer = $DrainPlayer

func _ready() -> void:
	footstep_player.finished.connect(_on_footstep_finished)

func _on_footstep_finished() -> void:
	if footstep_player.stream != null:
		footstep_player.play(randf_range(0.0, footstep_player.stream.get_length()))


func play_walk() -> void:
	if footstep_player.playing: return
	footstep_player.play(randf_range(0.0, footstep_player.stream.get_length()))

func stop_walk() -> void:
	footstep_player.stop()

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
