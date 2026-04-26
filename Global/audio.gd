# AudioManager — Autoload Singleton
extends Node

enum REVERB_TYPE { NONE, SMALL, MEDIUM, LARGE }

# Audio pool for 3D spatial sounds
const POOL_SIZE = 8
var pool_3d: Array[AudioStreamPlayer3D] = []

@export var ui_focus_audio : AudioStream
@export var ui_hover_audio : AudioStream
@export var ui_select_audio : AudioStream
@export var ui_cancel_audio : AudioStream
@export var ui_success_audio : AudioStream
@export var ui_error_audio : AudioStream

var current_track : int = 0 
var ambience_tweens : Array [Tween]
var ui_audio_player : AudioStreamPlaybackPolyphonic

@onready var ambience_1: AudioStreamPlayer = %Ambience1
@onready var ambience_2: AudioStreamPlayer = %Ambience2
@onready var ui: AudioStreamPlayer = %Ui

func _ready() -> void:
	ui.play()
	ui_audio_player = ui.get_stream_playback()
	_init_pool_3d()

#region AMBIENCE:
func play_ambience( audio : AudioStream ) -> void:
	
	# Determine the current ambience player 
	var current_player: AudioStreamPlayer = get_ambience_player(current_track)
	if current_player.stream == audio:
		return
		
	# Determine next ambience player
	var next_track :  int = wrapi(current_track + 1, 0, 2)
	var next_player : AudioStreamPlayer = get_ambience_player(next_track)
	
	# Set audio on next ambience player
	next_player.stream = audio
	next_player.play()
	
	# HANDLE AUDIO FADES
	# Kill tweens
	for t in ambience_tweens:
		t.kill()
	ambience_tweens.clear()
	
	# Create new tweens
	fade_track_out( current_player )
	fade_track_in( next_player )
	
	# Store/set current ambience track
	current_track = next_track
	pass

func get_ambience_player( i : int ) -> AudioStreamPlayer:
	if i == 0:
		return ambience_1
	else:
		return ambience_2
#endregion


#region GENERAL:
func fade_track_out(player : AudioStreamPlayer) -> void:
	var tween : Tween = create_tween()
	ambience_tweens.append( tween )
	tween.tween_property( player, "volume_linear", 0.0, 1.5)
	tween.tween_callback(player.stop)
	pass


func fade_track_in(player : AudioStreamPlayer) -> void:
	var tween : Tween = create_tween()
	ambience_tweens.append( tween )
	tween.tween_property( player, "volume_linear", 1.0, 1.0)
	pass

func set_reverb( type : REVERB_TYPE ) -> void:
	var reverb_fx : AudioEffectReverb = AudioServer.get_bus_effect(1,0)
	if not reverb_fx:
		return
	AudioServer.set_bus_effect_enabled(1, 0, true)
	match type:
		REVERB_TYPE.NONE:
			AudioServer.set_bus_effect_enabled(1, 0, false)
		REVERB_TYPE.SMALL:
			reverb_fx.room_size = 0.2
		REVERB_TYPE.MEDIUM:
			reverb_fx.room_size = 0.5
		REVERB_TYPE.LARGE:
			reverb_fx.room_size = 0.8
	pass
#endregion


#region 3D POOL:
func _init_pool_3d() -> void:
	for i in POOL_SIZE:
		var ap := AudioStreamPlayer3D.new()
		ap.bus = "SFX"
		add_child(ap)
		pool_3d.append(ap)

func get_free_player_3d() -> AudioStreamPlayer3D:
	for ap in pool_3d:
		if not ap.playing:
			return ap
	return pool_3d[0]

func play_sound_3d(audio: AudioStream, pos: Vector3) -> void:
	var ap := get_free_player_3d()
	ap.global_position = pos
	ap.stream = audio
	ap.play()
#endregion


#region UI FUNCTION:
func play_ui_audio( audio : AudioStream ) -> void:
	if ui_audio_player:
		ui_audio_player.play_stream( audio )

func setup_button_audio( node : Node ) -> void:
	for c in node.find_children( "*", "Button" ): 
		c.focus_entered.connect( ui_focus_change ) 
		c.pressed.connect( ui_select ) 

func ui_focus_change() -> void:
	play_ui_audio(ui_focus_audio)

func ui_hover() -> void:
	play_ui_audio(ui_hover_audio)

func ui_select() -> void:
	play_ui_audio(ui_select_audio)

func ui_cancel() -> void:
	play_ui_audio(ui_cancel_audio)

func ui_success() -> void:
	play_ui_audio(ui_success_audio)

func ui_error() -> void:
	play_ui_audio(ui_error_audio)
#endregion
