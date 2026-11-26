extends Node3D
@export_range(0,5) var level: int
func _ready()->void:
	preload("res://scripts/vessels.gd").build(self,level)
