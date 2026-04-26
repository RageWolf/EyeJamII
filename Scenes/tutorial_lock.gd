extends Area3D

@onready var blocker = $"../CollisionShape3D"
var player_inside := false

func _ready():
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(body):
	if body.is_in_group("player"):
		player_inside = true
		check_tutorial()

func _on_exit(body):
	if body.is_in_group("player"):
		player_inside = false

func _process(_delta):
	if player_inside:
		check_tutorial()

func check_tutorial():
	if GameManager.tutorial_drain_done \
	and GameManager.tutorial_stealth_done:

		# already unlocked? skip
		if blocker.disabled:
			return

		blocker.disabled = true
		GameManager.tutorial_completed = true

	else:
		GameManager.show_dialog("Please complete all the tutorial tasks.")
