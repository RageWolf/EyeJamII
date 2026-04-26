@tool
class_name StealthZone
extends Area3D

@export var zone_size: Vector3 = Vector3(5, 5, 5):
	set(value):
		zone_size = value
		if Engine.is_editor_hint():
			get_node("CollisionShape3D").shape.size = value

var player : Player 
var hide_timer = 1.5
var entered := false


func _ready() -> void:
	if Engine.is_editor_hint():
		get_node("CollisionShape3D").shape.size = zone_size
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("player"):
		entered = true
		player = body
		print(player, " entered")
		await get_tree().create_timer(hide_timer).timeout
		if not entered or player == null:
			return
		player.player_inside_stealth_zone = true
		GameManager.tutorial_stealth_done = true

func _on_body_exited(body):
	if body == player:
		entered = false
		player.player_inside_stealth_zone = false
		player = null
