extends Area3D

var player_in_range := false
var player_ref = null

@onready var interact_ui: Label3D = $Label3D

func _ready():
	interact_ui.text = "[ E ] Hide"
	interact_ui.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("feed"):
		if player_ref:
			player_ref.toggle_hide()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		interact_ui.visible = true

func _on_body_exited(body):
	if body == player_ref:
		player_in_range = false
		player_ref = null
		interact_ui.visible = false
