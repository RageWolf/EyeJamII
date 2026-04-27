extends StaticBody3D

@export var energy_value: float = 20.0
@export var decay_value: float = 5.0
@export var tutorial_system: bool = false
var is_broken := false
var player_in_range := false


@onready var drainable_off: MeshInstance3D = $DrainableOff
@onready var mesh = get_node_or_null("MeshInstance3D")
@onready var light: SpotLight3D = $SpotLight3D
@onready var interact_ui: Label3D = $InteractUi
@onready var progress_bar: TextureProgressBar = %ProgressBar
# Progress bar being used by player: do not delete!

func _ready():
	interact_ui.text = "[ E ] Feed"  
	progress_bar.visible = false

func set_player_in_range(value: bool):
	player_in_range = value
	
	if interact_ui:
		interact_ui.visible = value
	
	if mesh and mesh.material_overlay:
		mesh.material_overlay.set_shader_parameter("outline_width", 7.0 if value else 0.0)

func set_feeding_active(value: bool, can_feed: bool):
	if is_broken:
		return
	interact_ui.visible = false if value else (player_in_range and can_feed)
	progress_bar.visible = value
	if not value:
		progress_bar.value = 0.0

func break_system():
	if is_broken:
		return
	
	is_broken = true
	GameManager.add_energy(energy_value)
	GameManager.add_decay(decay_value)
	interact_ui.visible = true 
	interact_ui.text = "[ BROKEN ]"
	
	# trigger visuals
	VfxManager.emit_zap(position)
	mesh.visible = false
	drainable_off.visible = true
	
	# screen shake
	SignalBus.screen_shake.emit(0.1)
	
	await blink_and_turn_off()
	
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
	interact_ui.text = "[ E ] Feed"
	light.visible = true
	is_broken = false
	drainable_off.visible = false
	mesh.visible = true
	SignalBus.system_fixed.emit(self)  

func alert_crew():
	SignalBus.system_broken.emit(global_position, self)
