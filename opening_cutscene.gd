extends Control

var line_complete: bool = false
var speed = 0.05
var timer = 0.0

@onready var dialogue = $Panel/RichTextLabel
@onready var index = 0
@onready var lines = ["Ripped from your home by lesser beings. Contained within a prison of plastics and metal. Taken from your home.",
"The lesser beings study you, fascinated by powers beyond their control. They take you to their home. Far from yours.",
"A slip through space and time and you are free of your bonds. The alarm sounds and the creatures stir, desperate to capture you once more.",
"Even as they search you hunger. Hunger for susctinence. Hunger for power. Their machines run on power.",
"The growing hunger inside you signals your coming change, these lesser beings will not stop you, though they may try.",
"Your belly growls. They won't find ways to use your power. For you are swift, and silent."]

func _ready() -> void:
	dialogue.text = lines[0]
	dialogue.visible_characters = 0

func _process(delta: float) -> void:
	var line = lines[index]
	if dialogue.visible_characters < line.length():
		timer += delta
	elif dialogue.visible_characters == line.length():
		line_complete = true
	if timer >= speed:
		dialogue.visible_characters += 1
		timer = 0.0

func _on_button_pressed() -> void:
	var line = lines[index]
	if line_complete:
		index += 1
		if index == lines.size() - 1:
			LoadManager.load_scene("res://Scenes/main_level.tscn")
		else:
			dialogue.visible_characters = 0
			line_complete = false
			dialogue.text = lines[index]
	else:
		dialogue.visible_characters = line.length()
