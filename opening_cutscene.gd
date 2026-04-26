extends Control

var line_complete: bool = false
var speed = 0.05
var timer = 0.0

@onready var dialogue = $Panel/RichTextLabel
@onready var index = 0
@onready var lines = ["You were feeding off of the power supply belonging to a research outpost on a dead planet, when one of the scientists spotted and captured you.",
"The scientists brought you back to their ship for further study and are now en route to their home planet.",
"Fortunately for you, the crew was careless and you were able to escape containment. The crew is now patrolling the hallways in search of their missing specimen.",
"Your goal is to decay the ship by draining as much power as you can without getting caught before the crew reaches their destination and takes you back to their lab.",
"Feed off of the ship's systems to restore your own energy and do damage to the ship. But be careful, when a system breaks, any nearby crew members will be alerted and will go to repair the broken system.",
"If you run out of energy or the ship reaches its destination before you are able to finish destroying the ship, you will be caught by the crew and taken back to their lab."]

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
