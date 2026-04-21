extends StaticBody3D


var is_broken := false
var player_in_range := false

@onready var interact_ui: Label3D = $InteractUi
@onready var progress_bar: TextureProgressBar = %ProgressBar
# Progress bar being used by player: do not delete!

func _ready():
	interact_ui.text = "[ E ] Feed"  
	progress_bar.visible = false

func set_player_in_range(value: bool):
	player_in_range = value
	interact_ui.visible = value

func set_feeding_active(value: bool):
	interact_ui.visible = false if value else player_in_range
	progress_bar.visible = value
	if not value:
		progress_bar.value = 0.0

func break_system():
	if is_broken:
		return
	
	is_broken = true
	interact_ui.text = "[ BROKEN ]"
	
	# trigger visuals (lights off etc.)
	# screen shake
	
	alert_crew()

func fix_system():
	is_broken = false

func alert_crew():
	SignalBus.system_broken.emit(global_position)
