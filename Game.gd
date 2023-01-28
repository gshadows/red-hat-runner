extends Spatial

signal quit

export var RUN_SPEED := 5.0

onready var MenuUI = preload("res://ui/MenuUI.tscn")
onready var mapgen = $MapGenerator

var menu
onready var chunk1 : Spatial = $chunk1
onready var chunk2 : Spatial = $chunk2
onready var chunk3 : Spatial = $chunk3


func _ready():
	regenerate_map(chunk1)
	regenerate_map(chunk2)
	regenerate_map(chunk3)
	pass


func _process(delta:float):
	#if is_player_runs:
	chunk1.translation.z += RUN_SPEED * delta
	chunk2.translation.z += RUN_SPEED * delta
	chunk3.translation.z += RUN_SPEED * delta
	if chunk3.translation.z >= MapGenerator.GROUND_LEN:
		swicth_chunks()
	

func swicth_chunks():
	var tmp = chunk3
	chunk3 = chunk2
	chunk2 = chunk1
	chunk1 = tmp
	chunk1.translation.z -= MapGenerator.GROUND_LEN * 3
	regenerate_map(chunk1)


func regenerate_map(var parent:Node):
	var map = parent.get_node_or_null("Map")
	if map:
		map.queue_free()
		parent.remove_child(map)
	map = Spatial.new()
	map.name = "Map"
	mapgen.generate(map)
	parent.add_child(map)


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
