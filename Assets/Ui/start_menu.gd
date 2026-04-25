extends Control


@onready var loading_bar: ProgressBar = $LoadingBar

var target_scene := ""

func _on_start_pressed() -> void:
	load_scene("res://Scenes/main_level.tscn")

func _on_credits_pressed() -> void:
	load_scene("res://Assets/Ui/Credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func load_scene(path: String) -> void:
	target_scene = path
	$LoadingBar.visible = true
	$LoadingBar.value = 0
	ResourceLoader.load_threaded_request(path)
	set_process(true)

func _process(_delta: float) -> void:
	if target_scene == "":
		return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		$LoadingBar.value = progress[0] * 100
	
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		$LoadingBar.value = 100
		var scene = ResourceLoader.load_threaded_get(target_scene)
		get_tree().change_scene_to_packed(scene)
		target_scene = ""
		set_process(false)
	
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Failed to load: " + target_scene)
		target_scene = ""
		set_process(false)
