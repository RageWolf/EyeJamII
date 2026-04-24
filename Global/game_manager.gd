# SAVEMANAGER
extends Node

var PHASE_1 : bool = false
var PHASE_2 : bool = false
var PHASE_3 : bool = false

# PLAYER ENERGY
var player_energy: float = 100.0
var max_energy: float = 100.0
var energy_decay_rate: float = 1   # per second

# SHIP DECAY
var ship_decay: float = 100.0
var max_decay: float = 100.0

# TIMER
var time_left: float = 120.0  # seconds

# SIGNALS
signal energy_changed(value)
signal decay_changed(value)
signal time_changed(value)

func _process(delta):
	# 1. ENERGY DECAY
	player_energy -= energy_decay_rate * delta
	player_energy = clamp(player_energy, 0, max_energy)
	emit_signal("energy_changed", player_energy)

	# 2. TIMER
	time_left -= delta
	time_left = max(time_left, 0)
	emit_signal("time_changed", time_left)

	check_game_state()

# ------------------------

func add_energy(amount):
	player_energy += amount
	player_energy = clamp(player_energy, 0, max_energy)
	emit_signal("energy_changed", player_energy)

func add_decay(amount):
	var old_decay = ship_decay
	
	ship_decay -= amount
	ship_decay = clamp(ship_decay, 0, max_decay)
	emit_signal("decay_changed", ship_decay)

	check_decay_reward(old_decay)

# ------------------------

func check_decay_reward(old_decay):
	# every 20% -> give bonus time
	if int(old_decay / 20) > int(ship_decay / 20):
		time_left += 20

# ------------------------

func check_game_state():
	if player_energy <= 0:
		print("LOSE: Player died")

	if time_left <= 0:
		print("LOSE: Crew arrived")

	if ship_decay <= 0:
		print("WIN: Ship fully decayed")
