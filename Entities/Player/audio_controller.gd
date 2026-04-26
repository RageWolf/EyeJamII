extends Node

@export var jump_sound: AudioStream
@export var footstep_sound: AudioStream
@export var land_sound: AudioStream
@export var feed_sound: AudioStream
@export var trill_sound: AudioStream
@export var cancel_feed_sound: AudioStream

func play_jump() -> void:
	Audio.play_sound_3d(jump_sound, get_parent().global_position)

func play_footstep() -> void:
	Audio.play_sound_3d(footstep_sound, get_parent().global_position)

func play_land() -> void:
	Audio.play_sound_3d(land_sound, get_parent().global_position)

func play_feed() -> void:
	Audio.play_sound_3d(feed_sound, get_parent().global_position)
