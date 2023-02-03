class_name ObjGenerator
extends Node

const GROUND_LEN := 10.0
const LINE_LENGTH := 1.0 # Should be same as player jump distance.
const NUM_LINES := int(GROUND_LEN / LINE_LENGTH)
const OBJ_Y := 0.25
const ROWS_DISTANCE_X := -1.5

onready var RiverScene = preload("res://objects/river/River.tscn")
onready var LogScene = preload("res://objects/log/Log.tscn")
onready var StoneScene = preload("res://objects/stone/Stone01.tscn")
onready var FlowerScene = preload("res://objects/flower/Flower.tscn")


var start_seed: int = 0
var rng = RandomNumberGenerator.new()

# Generation options.
var FILLED_BLOCK_LENGTH := 10
var EMPTY_BLOCK_LENGTH := 5
var EMPTY_LINE_PROBABILITY := 50
var RIVER_PROBABILITY := 25
var LOG_PROBABILITY := 75
var STONE_PROBABILITY := 75
var FLOWER_PROBABILITY := 50

# Bit masks for line usage: line1 is nearest to game start.
var line1 := 0
var line2 := 0
var is_filling := true
var lines_filled := 0


func _ready():
	if start_seed != 0:
		rng.seed = start_seed
	else:
		rng.randomize()
		start_seed = rng.seed


func generate(var parent: Spatial):
	var line : int
	for i in NUM_LINES:
		if is_filling:
			line = gen_line_obstacles(parent, i)
			lines_filled += 1
			#print("Lines filled: ", lines_filled)
			if lines_filled > FILLED_BLOCK_LENGTH:
				lines_filled = 0
				is_filling = false
		else:
			line = 0
			lines_filled += 1
			#print("Lines skipped: ", lines_filled)
			if lines_filled > EMPTY_BLOCK_LENGTH:
				lines_filled = 0
				is_filling = true
		# Flowers
		gen_line_flowers(parent, i, line)
		# Finish line.
		push_line(line)


func gen_line_flowers(var parent: Spatial, var line_num:int, var line: int):
	if not (line & 1) and check(FLOWER_PROBABILITY):
		make_flower(parent, line_num, +1)
	if not (line & 2) and check(FLOWER_PROBABILITY):
		make_flower(parent, line_num, 0)
	if not (line & 4) and check(FLOWER_PROBABILITY):
		make_flower(parent, line_num, -1)


func gen_line_obstacles(var parent: Spatial, var line_num:int) -> int:
	var line := gen_next_line_mask() # Bits set for allowed positions.
	if (line == 0) or check(EMPTY_LINE_PROBABILITY):
		return 0 # Empty line.
	if (line == 7) and check(RIVER_PROBABILITY):
		# All 3 rows free. River decided.
		make_river(parent, line_num)
		return 7
	if ((line == 3) or (line >= 6)) and check(LOG_PROBABILITY):
		# At least 2 adjacent rows free. Log decided.
		if line == 7:
			# Decide which side to use.
			line = 3 if check(50) else 6
		make_log(parent, line_num, line == 6)
		return line
	# Place stones.
	var stones := 0
	if (line & 1) and check(STONE_PROBABILITY):
		make_stone(parent, line_num, +1)
		stones |= 1
	if (line & 2) and check(STONE_PROBABILITY):
		make_stone(parent, line_num, 0)
		stones |= 2
	if (line & 4) and check(STONE_PROBABILITY):
		make_stone(parent, line_num, -1)
		stones |= 4
	return stones


func make_river(var parent: Spatial, var line_num:int):
	var river = RiverScene.instance()
	river.translation = Vector3(0, 0.01, get_line_z(line_num))
	parent.add_child(river)


func make_log(var parent: Spatial, var line_num:int, var is_left:bool):
	var thelog = LogScene.instance()
	var x := -1.5 if is_left else +1.5
	thelog.translation = Vector3(x, 0, get_line_z(line_num))
	parent.add_child(thelog)


func make_stone(var parent: Spatial, var line_num:int, var pos:int):
	var stone = StoneScene.instance()
	var x := pos * 1.5
	stone.translation = Vector3(x, 0, get_line_z(line_num))
	parent.add_child(stone)


func make_flower(var parent: Spatial, var line_num:int, var pos:int):
	var flower = FlowerScene.instance()
	var x:float = (pos + rng.randf() - 0.75) * 1.5
	var z:float = get_line_z(line_num) - (rng.randf() - 0.5) * LINE_LENGTH
	flower.translation = Vector3(x, 0, z)
	parent.add_child(flower)


func get_line_z(var line_num:int) -> float:
	return (GROUND_LEN / 2) - LINE_LENGTH * line_num


func check(var probability:int) -> bool:
	return rng.randi_range(0, 100) <= probability


func gen_next_line_mask() -> int:
	var mask := 7 ^ line1 ^ line2 # Allowed bits mask for next line.
	var line = rng.randi() & 7 # Next line - random.
	line &= mask # Leave only allowed bits.
	return line


func push_line(var line:int):
	line1 = line2
	line2 = line

