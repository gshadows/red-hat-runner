extends Spatial

signal quit

const USE_THREAD := false
const END_GAME_TIMEOUT := 3.0

enum GameDifficulty { NORMAL }

onready var MenuUI = preload("res://ui/MenuUI.tscn")
onready var Wolf = preload("res://characters/wolf/Wolf.tscn")
onready var mapgen = $MapGenerator
onready var objgen = $ObjGenerator

onready var chunk1 := $chunk1
onready var chunk2 := $chunk2
onready var chunk3 := $chunk3
onready var redhat := $RedHat
onready var game_ui := $GameUI
onready var music := $MusicPlayer

onready var House := preload("res://objects/house/House.tscn")

var WOLD_PERIOD : int

var menu
var wolf = null
var chunks_left: int
var wolf_period: int
var is_wolf_from_left: bool
var is_wolf_watching := false

var difficulty: int
var scores_table_name: String

var gen_thread := Thread.new()
var gen_thread_mutex := Mutex.new()
var gen_thread_semaphore := Semaphore.new()
var gen_thread_quit := false

var debug_mode := 0


# Game settings: NORMAL
const RUN_SPEED_NORMAL		:= 5.0
const STRAFE_SPEED_NORMAL	:= 1.5
const TIME_LIMIT_NORMAL		:= 80.0
const CHUNKS_TOTAL_NORMAL	:= 20
const LIVES_NORMAL			:= 3
const FILLED_BLOCK_LENGTH_NORMAL	:= 10
const EMPTY_BLOCK_LENGTH_NORMAL		:= 3
const EMPTY_LINE_PROBABILITY_NORMAL	:= 20
const RIVER_PROBABILITY_NORMAL		:= 50
const LOG_PROBABILITY_NORMAL		:= 75
const STONE_PROBABILITY_NORMAL		:= 75
const FLOWER_PROBABILITY_NORMAL		:= 50
const WOLF_PERIOD_NORMAL := 5

func setup_game(new_difficulty: int):
	match new_difficulty:
		GameDifficulty.NORMAL:
			difficulty = new_difficulty
			scores_table_name = Settings.SCORES_TABLE_NORMAL
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
			WOLD_PERIOD = WOLF_PERIOD_NORMAL
			game_ui.high_score = Settings.get_high_score(Settings.SCORES_TABLE_NORMAL)
		_:
			printerr("Wrong game difficulty: ", difficulty)
			emit_signal("quit")

func save_score(score:int):
	Settings.set_score(scores_table_name, score)
	Settings.save()


func _ready():
	setup_game(GameDifficulty.NORMAL)
	wolf_period = WOLD_PERIOD
	is_wolf_from_left = true # TODO random?
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
		if is_wolf_watching and wolf:
			# Sighted Red Hat!
			print("Wolf sighted Red Hat!")
			is_wolf_watching = false
			wolf.attack(redhat)


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
		create_wolf(chunk1)

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
		create_wolf(chunk1)


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


func create_wolf(parent:Node):
	wolf_period -= 1
	if wolf_period > 0:
		return

	# Kill old wolf.
	is_wolf_watching = false
	if wolf:
		wolf.queue_free()
		parent.call_deferred("remove_child", wolf)

	# Update conditions.
	wolf_period = WOLD_PERIOD
	var dir = +1 if is_wolf_from_left else -1
	is_wolf_from_left = not is_wolf_from_left

	# Create new wolf.
	wolf = Wolf.instance()
	parent.call_deferred("add_child", wolf)
	wolf.call_deferred("start_wolf", dir)
	wolf.connect("attack_done", self, "on_wolf_attack_done")
	wolf.connect("walked_out", self, "on_wolf_walked_out")
	wolf.connect("walked_in", self, "on_wolf_walked_in")

	# Update game state.
	redhat.on_wolf_appear()
	wolf.call_deferred("start_wolf", dir)
	music.stop()
	game_ui.on_wolf(true)


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
	if event.is_action_pressed("debug"):
		debug_mode = (debug_mode + 1) % 2
		match debug_mode:
			0:
				$Camera.make_current()
				$CameraDebug.visible = false
				redhat.is_debug = false
			1:
				$CameraDebug.visible = true
				$CameraDebug.make_current()
				redhat.is_debug = true


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
	save_score(redhat.flowers)
	get_tree().paused = false
	emit_signal("quit")


func _on_RedHat_loose(_reason):
	$GameUI.on_loose(_reason)
	yield(get_tree().create_timer(END_GAME_TIMEOUT), "timeout")
	quit_game()


func _on_RedHat_win():
	$GameUI.on_win()
	yield(get_tree().create_timer(END_GAME_TIMEOUT), "timeout")
	quit_game()


func on_wolf_attack_done():
	redhat.loose(RedHat.LOOSE_REASON_WOLF)


func on_wolf_walked_out():
	print("Wolf leaves road")
	is_wolf_watching = false
	music.play()
	game_ui.on_wolf(false)
	redhat.on_wolf_disappear()


func on_wolf_walked_in():
	print("Wolf on the road!")
	music.stop()
	is_wolf_watching = true
