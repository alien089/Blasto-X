tool
extends Node

export var increment = 1566
export var y = 768
export var x = 768
export var n_positions = 5
export(bool) var horizonal_vertical = false
export(Array, PackedScene) var scenes

func _ready() -> void:
	randomize()
	for n in n_positions:
		var rand_index:int = randi() % scenes.size()
		var scene_instance = scenes[rand_index].instance()
		if !horizonal_vertical:
			scene_instance.position = Vector2(increment * (n + 1), y)
		else:
			scene_instance.position = Vector2(x, increment * (n + 1))
		add_child(scene_instance)
