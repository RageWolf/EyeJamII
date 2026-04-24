extends CanvasLayer

@onready var energy_bar = $Control/EnergyBar
@onready var decay_bar = $Control/DecayBar
@onready var timer_label = $Control/TimerLabel

func _ready():
	GameManager.energy_changed.connect(update_energy)
	GameManager.decay_changed.connect(update_decay)
	GameManager.time_changed.connect(update_time)
	
	# initialize UI with current values
	update_energy(GameManager.player_energy)
	update_decay(GameManager.ship_decay)
	update_time(GameManager.time_left)

func update_energy(value):
	energy_bar.value = value

func update_decay(value):
	decay_bar.value = value

func update_time(value):
	var total_seconds = int(value)
	
	var minutes = total_seconds / 60.0
	var seconds = total_seconds % 60
	
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# turn red when low
	if total_seconds <= 20:
		timer_label.modulate = Color(1, 0.2, 0.2)
	else:
		timer_label.modulate = Color(1, 1, 1)
