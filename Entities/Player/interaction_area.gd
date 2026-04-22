class_name InteractionArea
extends Area3D

var nearby_targets: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("power_system"):
		nearby_targets.append(body)
		body.set_player_in_range(true)

func _on_body_exited(body):
	if body.is_in_group("power_system"):
		nearby_targets.erase(body)
		body.set_player_in_range(false)

func get_closest_target(from_position: Vector3):
	if nearby_targets.is_empty():
		return null
	
	var closest = nearby_targets[0]
	var min_dist = from_position.distance_to(closest.global_position)
	
	for t in nearby_targets:
		var d = from_position.distance_to(t.global_position)
		if d < min_dist:
			min_dist = d
			closest = t
	
	return closest

func has_target() -> bool:
	return not nearby_targets.is_empty()
