class_name MapGenerator
extends Node

const GROUND_LEN := 10.0

const TREE_MIN_POS := 5.0
const TREE_MAX_POS := 9.0
const TREES_COUNT := 20

const BUSH_MIN_POS := 3.5
const BUSH_MAX_POS := 4.5
const BUSHES_COUNT := 6

const Z_DEVIATION := 0.1

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


func generate(parent):
	# Trees
	generate_obj(parent, TreeScene, TREES_COUNT, +TREE_MIN_POS, +TREE_MAX_POS)
	generate_obj(parent, TreeScene, TREES_COUNT, -TREE_MIN_POS, -TREE_MAX_POS)
	# Bushes
	generate_obj(parent, BushScene, BUSHES_COUNT, +BUSH_MIN_POS, +BUSH_MAX_POS)
	generate_obj(parent, BushScene, BUSHES_COUNT, -BUSH_MIN_POS, -BUSH_MAX_POS)


func generate_obj(parent, scene, count:int, min_pos:float, max_pos:float):
	var dz := GROUND_LEN / count
	var z := (GROUND_LEN - dz) / 2
	var zlim := -z
	var zdev = Z_DEVIATION * dz
	for i in count:
		var pos := Vector3(rng.randf_range(min_pos, max_pos), 0, z)
		var obj = scene.instance()
		obj.translation = pos
		obj.rotate_y(rng.randf_range(0, TAU))
		parent.add_child(obj)
		z -= dz + rng.randf_range(-zdev, +zdev)
		if z < zlim: break
