extends Node

func _ready() -> void:
	if "--spoonful-test" in OS.get_cmdline_user_args():
		var probe := preload("res://qa/probe.gd").new()
		get_tree().root.call_deferred("add_child", probe)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Menu.tscn")
