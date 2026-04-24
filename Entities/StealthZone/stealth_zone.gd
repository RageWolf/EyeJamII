extends Area3D

var player : Player 
var hide_timer = 1.5

func _on_body_entered(body):
	if body.is_in_group("player"):
		await get_tree().create_timer(hide_timer).timeout
		player = body
		player.player_inside_stealth_zone = true

func _on_body_exited(body):
	if body == player:
		player.player_inside_stealth_zone = false
		if player:
			player.set_hidden(false)
		player = null
