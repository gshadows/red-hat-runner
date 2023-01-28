class_name ObjGenerator
extends Node

const GROUND_LEN := 10.0
const JUMP_DISTANCE := 1.0
const NUM_LINES := int(GROUND_LEN / JUMP_DISTANCE)

onready var TreeScene = preload("res://objects/tree/Tree.tscn")
onready var BushScene = preload("res://objects/bush/Bush.tscn")


var start_seed: int = 0
var rng = RandomNumberGenerator.new()

# Bit masks for line usage: line1 is nearest to game start.
var line1 := 0
var line2 := 0


func _ready():
	if start_seed != 0:
		rng.seed = start_seed
	else:
		rng.randomize()
		start_seed = rng.seed


func generate(var parent):
	for i in NUM_LINES:
	# Obstacles
	pass
	# Flowers
	pass


func gen_next_line() -> int:
	var mask := 7 ^ line1 ^ line2 # Allowed bits mask for next line.
	var line = rng.randi() & 7 # Next line - random.
	line &= mask # Leave only allowed bits.
	return line


func generate_obj(var parent, var scene, var count:int, var min_pos:float, var max_pos:float):
	var dz := GROUND_LEN / count
	var z := (GROUND_LEN - dz) / 2
	var zlim := -z
	for i in count:
		var pos := Vector3(rng.randf_range(min_pos, max_pos), 0, z)
		var obj = scene.instance()
		obj.translation = pos
		parent.add_child(obj)
		z -= dz
		if z < zlim: break
