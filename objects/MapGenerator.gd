extends Node

const GROUND_LEN := 10.0

export var tree_min_pos := 4.0
export var tree_max_pos := 6.5
export var trees_count := 30

export var bush_min_pos := 3.0
export var bush_max_pos := 4.0
export var bushes_count := 8

export var z_deviation := 0.1

onready var TreeScene = preload("res://objects/tree/Tree.tscn")
onready var BushScene = preload("res://objects/bush/Bush.tscn")


var start_seed: int = 0
var rng = RandomNumberGenerator.new()


func _ready():
	if start_seed != 0:
		rng.seed = start_seed
	else:
		rng.randomize()
		start_seed = rng.seed


func generate(var parent):
	# Trees
	generate_obj(parent, TreeScene, trees_count, +tree_min_pos, +tree_max_pos)
	generate_obj(parent, TreeScene, trees_count, -tree_min_pos, -tree_max_pos)
	# Bushes
	generate_obj(parent, BushScene, bushes_count, +bush_min_pos, +bush_max_pos)
	generate_obj(parent, BushScene, bushes_count, -bush_min_pos, -bush_max_pos)
	

func generate_obj(var parent, var scene, var count:int, var min_pos:float, var max_pos:float):
	var dz := GROUND_LEN / count
	var z := (GROUND_LEN - dz) / 2
	var zlim := -z
	var zdev = z_deviation * dz
	for i in count:
		var pos := Vector3(rng.randf_range(min_pos, max_pos), 0, z)
		var obj = scene.instance()
		obj.translation = pos
		parent.add_child(obj)
		z -= dz + rng.randf_range(-zdev, +zdev)
		if z < zlim: break
