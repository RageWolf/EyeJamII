extends CanvasLayer

var target_scene := ""

@onready var loading_bar: ProgressBar = $LoadingBar
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false

func load_scene(path: String) -> void:
	target_scene = path
	visible = true
	loading_bar.value = 0
	loading_bar.visible = false
	anim_player.play("fade_in")
	await anim_player.animation_finished
	loading_bar.visible = true
	ResourceLoader.load_threaded_request(path)
	set_process(true)

func _process(_delta: float) -> void:
	if target_scene == "":
		return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		loading_bar.value = progress[0] * 100
	
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		loading_bar.value = 100
		loading_bar.visible = false
		var scene = ResourceLoader.load_threaded_get(target_scene)
		get_tree().change_scene_to_packed(scene)  
		anim_player.play("fade_out")              
		await anim_player.animation_finished
		target_scene = ""
		visible = false
		set_process(false)
	
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Failed to load: " + target_scene)
		target_scene = ""
		visible = false
		set_process(false)
