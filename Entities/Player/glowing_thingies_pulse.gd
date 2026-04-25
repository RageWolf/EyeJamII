extends MeshInstance3D

var mat : StandardMaterial3D
var time := 0.0

func _ready():
	mat = get_active_material(0)
	
	if mat == null:
		push_error("No material found on Glowing Thingies!")
		return

func _process(delta):
	if mat == null:
		return
	
	time += delta
	
	var pulse1 = sin(time * 2.0)
	var pulse2 = sin(time * 3.7)
	var combined = (pulse1 + pulse2) * 0.5   # irregular motion
	
	var energy_factor = GameManager.player_energy / GameManager.max_energy
	# Clamp just in case
	energy_factor = clamp(energy_factor, 0.0, 1.0)
	

	var base_intensity = 3.0
	var pulse_intensity = combined * 2.5
	
	mat.emission_energy = (base_intensity + pulse_intensity) * (0.5 + energy_factor)
	

	var shift = 0.1 * sin(time * 1.5)
	mat.emission = Color(0.2 + shift, 0.8, 1.0)
