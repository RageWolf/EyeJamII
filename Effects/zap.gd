extends Node3D

@onready var org_zap: CPUParticles3D = $OrgZap
@onready var blu_zap: CPUParticles3D = $BluZap


func _ready() -> void:
	for i in range(3):
		org_zap.restart()
		blu_zap.restart()
		await get_tree().create_timer(0.3).timeout  
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
