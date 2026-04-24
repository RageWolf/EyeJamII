extends Node

const ZAP = preload("uid://cpey08dyw5hdl")

func emit_zap(pos: Vector3):
	var vfx = ZAP.instantiate()
	vfx.position = pos
	get_tree().current_scene.add_child(vfx)  
