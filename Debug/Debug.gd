extends Control

@onready var player : Node
@onready var key_status: Panel = $KeyStatus
@onready var fps: Label = $GameOverlay/VBoxContainer/FPS
@onready var frame_time: Label = $GameOverlay/VBoxContainer/FrameTime
@onready var draw_calls: Label = $GameOverlay/VBoxContainer/DrawCalls
@onready var objects: Label = $GameOverlay/VBoxContainer/Objects
@onready var ram: Label = $GameOverlay/VBoxContainer/RAM
@onready var vram: Label = $GameOverlay/VBoxContainer/VRAM
@onready var physics_time: Label = $GameOverlay/VBoxContainer/PhysicsTime
@onready var process_time: Label = $GameOverlay/VBoxContainer/ProcessTime

func _ready() -> void:
	if OS.is_debug_build(): return
	visible = false
	player = get_tree().get_first_node_in_group("player")

var pressed_color := Color("ff6666")
var normal_color := Color("ffffff")


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return
	
	if event is InputEventKey:
		var key_name := event.as_text()
		if key_name in ["W", "A", "S", "D", "Space", "Shift"]:
			var key_node = key_status.get_node_or_null(key_name)
			if key_node:
				if event.pressed:
					key_node.modulate = pressed_color
				else:
					key_node.modulate = normal_color
	
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("debug"):
		visible = !visible

	if Input.is_action_just_pressed("screenshot"):
		take_screenshot()
	
	if Input.is_action_pressed("invincible"):
		if player:
			player.hurtbox.is_invulnerable = !player.hurtbox.is_invulnerable
			print("HULK SMASH? : ", player.hurtbox.is_invulnerable)

func _process(delta: float) -> void:
	if not visible: return
	
	fps.text         = "FPS: %d" % Engine.get_frames_per_second()
	frame_time.text  = "Frame: %.2f ms" % (delta * 1000.0)
	draw_calls.text  = "Draw Calls: %d" % RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	objects.text     = "Objects: %d" % RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	ram.text         = "RAM: %.1f MB" % (OS.get_static_memory_usage() / 1048576.0)
	vram.text        = "VRAM: %.1f MB" % (RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0)
	physics_time.text  = "Physics: %.2f ms" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	process_time.text  = "Process: %.2f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)

func take_screenshot():
	var img = get_viewport().get_texture().get_image()
	var time = Time.get_datetime_string_from_system()
	time = time.replace(":", "-")
	var path = "user://screenshot_%s.png" % time
	img.save_png(path)
	print("Saved: ", path)
