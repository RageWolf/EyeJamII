# GAMEMANAGER
extends Node
@onready var dialog: Label = $Dialog
@onready var color_rect: ColorRect = $ColorRect
var PHASE_2 : bool = false
var PHASE_3 : bool = false

#TUTORIAL
var tutorial_drain_done := false
var tutorial_stealth_done := false
var dialog_busy := false

# PLAYER ENERGY
var player_energy: float = 100.0
var max_energy: float = 100.0
var energy_decay_rate: float = 1.0  # per second

# SHIP DECAY
var ship_decay: float = 100.0
var max_decay: float = 100.0

# TIMER
var time_left: float = 300.0  # seconds

# SIGNALS
signal energy_changed(value)
signal decay_changed(value)
signal time_changed(value)

# NARRATIVE
var tutorial_completed : bool = false

# PLAYER DEATH
var player_caught: bool = false
var game_over: bool = false

func _process(delta):
	if not tutorial_completed:
		return
	
	# 1. ENERGY DECAY
	player_energy -= energy_decay_rate * delta
	player_energy = clamp(player_energy, 0, max_energy)
	emit_signal("energy_changed", player_energy)

	# 2. TIMER
	time_left -= delta
	time_left = max(time_left, 0)
	emit_signal("time_changed", time_left)
	check_game_state()

# ----------------------------------
func add_energy(amount):
	if not tutorial_drain_done:
		tutorial_drain_done = true
		show_dialog("Good... now try hiding in that dark area.")
		check_tutorial_complete()
	
	player_energy += amount
	player_energy = clamp(player_energy, 0, max_energy)
	emit_signal("energy_changed", player_energy)

# ----------------------------------
func add_decay(amount):
	var old_decay = ship_decay
	
	ship_decay -= amount
	ship_decay = clamp(ship_decay, 0, max_decay)
	emit_signal("decay_changed", ship_decay)
	check_decay_reward(old_decay)
	check_phase()

# ----------------------------------
func check_phase() -> void:
	var percent = (ship_decay / max_decay) * 100.0
	
	if percent <= 70.0 and not PHASE_2:
		PHASE_2 = true
		SignalBus.phase_2_started.emit()
	
	if percent <= 30.0 and not PHASE_3:
		PHASE_3 = true
		SignalBus.phase_3_started.emit()

# ----------------------------------
func check_decay_reward(old_decay):
	# every 20% -> give bonus time
	if int(old_decay / 20) > int(ship_decay / 20):
		time_left += 30

# ----------------------------------
func check_game_state():
	if game_over:
		return
	else:
		if player_energy <= 0:
			#print("LOSE: Player died")
			game_over = true
			LoadManager.load_scene("res://death_screen.tscn")
		if time_left <= 0:
			#print("LOSE: Crew arrived")
			game_over = true
			LoadManager.load_scene("res://death_screen.tscn")
		if ship_decay <= 0:
			#print("WIN: Ship fully decayed")
			game_over = true
			LoadManager.load_scene("res://ship_explosion.tscn")
			
		if player_caught == true:
			print("LOSE: Player Caught")
			game_over = true
			LoadManager.load_scene("res://death_screen.tscn")

#-----------------------------------------------------
func show_dialog(text: String, duration: float = 3.0):
	if dialog_busy:
		return
	
	dialog_busy = true
	dialog.text = text
	dialog.modulate.a = 0.0  # start invisible
	create_tween().tween_property(dialog, "modulate:a", 1.0, 0.3)  # fade in
	create_tween().tween_property(color_rect, "color:a", 0.5, 0.3)
	
	await get_tree().create_timer(duration).timeout
	
	create_tween().tween_property(color_rect, "color:a", 0.0, 0.3)
	create_tween().tween_property(dialog, "modulate:a", 0.0, 0.3)  # fade out
	await get_tree().create_timer(0.3).timeout
	
	dialog.text = ""
	dialog_busy = false

#------------------------------------------------------------
func check_tutorial_complete():
	if tutorial_completed:
		return
	
	if tutorial_drain_done \
	and tutorial_stealth_done:
		tutorial_completed = true
		show_dialog("Tutorial Completed. Now look for all feedable sources of energy and decay the ship before they catch you!")
		
		var hud = get_tree().get_first_node_in_group("hud")
		await get_tree().create_timer(4.0).timeout
		hud.show()

func reset():
	PHASE_2 = false
	PHASE_3 = false
	player_energy = 100.0
	ship_decay = 100.0
	time_left = 120.0
	player_caught = false
	game_over = false
