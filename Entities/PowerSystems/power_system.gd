extends StaticBody3D


var is_broken := false
var player_in_range := false


@onready var sparks: CPUParticles3D = $CPUParticles3D
@onready var light: SpotLight3D = $SpotLight3D
@onready var interact_ui: Label3D = $InteractUi
@onready var progress_bar: TextureProgressBar = %ProgressBar
# Progress bar being used by player: do not delete!

func _ready():
	interact_ui.text = "[ E ] Feed"  
	progress_bar.visible = false

func set_player_in_range(value: bool):
	player_in_range = value
	interact_ui.visible = value
	# print(value)

func set_feeding_active(value: bool, can_feed: bool):
	interact_ui.visible = false if value else (player_in_range and can_feed)
	progress_bar.visible = value
	if not value:
		progress_bar.value = 0.0

func break_system():
	if is_broken:
		return
	
	is_broken = true
	
	interact_ui.visible = true 
	interact_ui.text = "[ BROKEN ]"
	
	# trigger visuals
	sparks.emitting = true
	blink_and_turn_off()
	
	# screen shake
	SignalBus.screen_shake.emit(0.1)
	
	await blink_and_turn_off()
	sparks.emitting = false
	
	alert_crew()

func blink_and_turn_off():
	var original_energy = light.light_energy
	
	for i in randi_range(2, 4):
		light.light_energy = original_energy * 0.2
		await get_tree().create_timer(randf_range(0.1,0.2)).timeout
		
		light.light_energy = original_energy
		await get_tree().create_timer(randf_range(0.1,0.2)).timeout
	
	light.light_energy = 0

func fix_system():
	
	light.visible = true
	is_broken = false

func alert_crew():
	SignalBus.system_broken.emit(global_position)
