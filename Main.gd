extends Node

onready var Menu = preload("res://Menu.tscn")
onready var Game = preload("res://Game.tscn")

var cur_scene


func _ready():
	randomize()
	Settings.reload()
	Settings.apply()
	open_menu()


func quit_game():
	get_tree().quit(0)


func open_menu():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	unload()
	cur_scene = Menu.instance()
	add_child(cur_scene)
	cur_scene.connect("quit", self, "quit_game")
	cur_scene.connect("start", self, "start_game")


func start_game():
	unload()
	cur_scene = Game.instance()
	add_child(cur_scene)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cur_scene.connect("quit", self, "open_menu")


func unload():
	if cur_scene:
		remove_child(cur_scene)
		cur_scene.queue_free()
		cur_scene = null


func _input(event):
	# ESC - open menu.
	if event.is_action_pressed("fullscreen"):
		get_tree().set_input_as_handled()
		Settings.full_screen = not Settings.full_screen
		OS.window_fullscreen = Settings.full_screen
		Settings.save()
