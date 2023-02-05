extends Spatial

signal quit

const USE_THREAD := false

enum GameDifficulty { NORMAL }

onready var MenuUI = preload("res://ui/MenuUI.tscn")
onready var mapgen = $MapGenerator
onready var objgen = $ObjGenerator

onready var chunk1 := $chunk1
onready var chunk2 := $chunk2
onready var chunk3 := $chunk3
onready var redhat := $RedHat

onready var House := preload("res://objects/house/House.tscn")

var menu
var chunks_left: int

var gen_thread := Thread.new()
var gen_thread_mutex := Mutex.new()
var gen_thread_semaphore := Semaphore.new()
var gen_thread_quit := false


# Game settings: NORMAL
const RUN_SPEED_NORMAL		:= 5.0
const STRAFE_SPEED_NORMAL	:= 1.5
const TIME_LIMIT_NORMAL		:= 30.0
const CHUNKS_TOTAL_NORMAL	:= 10
const LIVES_NORMAL			:= 3
const FILLED_BLOCK_LENGTH_NORMAL	:= 10
const EMPTY_BLOCK_LENGTH_NORMAL		:= 3
const EMPTY_LINE_PROBABILITY_NORMAL	:= 20
const RIVER_PROBABILITY_NORMAL		:= 50
const LOG_PROBABILITY_NORMAL		:= 75
const STONE_PROBABILITY_NORMAL		:= 75
const FLOWER_PROBABILITY_NORMAL		:= 50

func setup_game(difficulty: int):
	match difficulty:
		GameDifficulty.NORMAL:
			redhat.RUN_SPEED	= RUN_SPEED_NORMAL
			redhat.STRAFE_SPEED	= STRAFE_SPEED_NORMAL
			redhat.TIME_LIMIT	= TIME_LIMIT_NORMAL
			redhat.lives		= LIVES_NORMAL
			objgen.FILLED_BLOCK_LENGTH		= FILLED_BLOCK_LENGTH_NORMAL
			objgen.EMPTY_BLOCK_LENGTH		= EMPTY_BLOCK_LENGTH_NORMAL
			objgen.EMPTY_LINE_PROBABILITY	= EMPTY_LINE_PROBABILITY_NORMAL
			objgen.RIVER_PROBABILITY		= RIVER_PROBABILITY_NORMAL
			objgen.LOG_PROBABILITY			= LOG_PROBABILITY_NORMAL
			objgen.STONE_PROBABILITY		= STONE_PROBABILITY_NORMAL
			objgen.FLOWER_PROBABILITY		= FLOWER_PROBABILITY_NORMAL
			chunks_left = CHUNKS_TOTAL_NORMAL
		_:
			printerr("Wrong game difficulty: ", difficulty)
			emit_signal("quit")


func _ready():
	setup_game(GameDifficulty.NORMAL)
	regenerate_map(chunk1)
	regenerate_map(chunk2)
	regenerate_map(chunk3)
	regenerate_obj(chunk2, true)
	regenerate_obj(chunk1, false)
	chunks_left -= 3
	if USE_THREAD && not gen_thread.start(self, "_gen_thread_func", null, Thread.PRIORITY_LOW):
		printerr("Map generation thread start failed!")
		emit_signal("quit")
	redhat.start_game()


func _process(delta:float):
	var speed : float = redhat.current_speed
	if speed > 0:
		chunk1.translation.z += speed * delta
		chunk2.translation.z += speed * delta
		chunk3.translation.z += speed * delta
		if chunk3.translation.z >= MapGenerator.GROUND_LEN:
			swicth_chunks()


func swicth_chunks():
	var tmp = chunk3
	chunk3 = chunk2
	chunk2 = chunk1
	chunk1 = tmp
	chunk1.translation.z -= MapGenerator.GROUND_LEN * 3
	clear_chunk1()
	chunks_left -= 1
	if USE_THREAD:
		var __ = gen_thread_semaphore.post()
	else:
		regenerate_map(chunk1)
		regenerate_obj(chunk1, false)

func _exit_tree():
	if USE_THREAD:
		gen_thread_mutex.lock()
		gen_thread_quit = true
		gen_thread_mutex.unlock()
		var __ = gen_thread_semaphore.post()
		gen_thread.wait_to_finish()


func _gen_thread_func(_userdata):
	while true:
		var __ = gen_thread_semaphore.wait()
		if gen_thread_quit:
			break
		regenerate_map(chunk1)
		regenerate_obj(chunk1, false)


func regenerate_map(parent:Node):
	var map = Spatial.new()
	map.name = "Map"
	mapgen.generate(map)
	parent.call_deferred("add_child", map)


func regenerate_obj(parent:Node, flowers_only:bool):
	if chunks_left > 0:
		var obj = Spatial.new()
		obj.name = "Obj"
		objgen.generate(obj, flowers_only)
		parent.call_deferred("add_child", obj)
	else:
		var house = House.instance()
		parent.call_deferred("add_child", house)


func clear_chunk1():
	var map = chunk1.get_node_or_null("Map")
	if map:
		chunk1.remove_child(map)
		map.queue_free()
	var obj = chunk1.get_node_or_null("Obj")
	if obj:
		chunk1.remove_child(obj)
		obj.queue_free()


func _input(event):
	# ESC - open menu.
	if not menu and event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		open_menu()
		return


func open_menu():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	menu = MenuUI.instance()
	menu.is_ingame = true
	add_child(menu)
	menu.connect("quit", self, "quit_game")
	menu.connect("start", self, "close_menu")
	menu.connect("close", self, "close_menu")


func close_menu():
	if menu:
		remove_child(menu)
		menu.queue_free()
		menu = null
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func quit_game():
	get_tree().paused = false
	emit_signal("quit")


func _on_RedHat_loose(_reason):
	quit_game()


func _on_RedHat_win():
	quit_game()
