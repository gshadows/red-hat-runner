extends Node

onready var Menu = preload("res://Menu.tscn")
onready var Game = preload("res://Game.tscn")

var cur_scene


func _ready():
	#if OS.is_debug_build() or get_tree().is_editor_hint():
	#	OS.current_screen = OS.get_screen_count() - 1
	#	OS.window_maximized = true
	randomize()
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
	cur_scene.difficulty = Settings.SCORES_TABLE_NORMAL
	cur_scene.startup_time_limit = 75.0
	cur_scene.chunks_left = 20
	add_child(cur_scene)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cur_scene.connect("quit", self, "open_menu")


func unload():
	if cur_scene:
		call_deferred("remove_child", cur_scene)
		cur_scene.queue_free()
		cur_scene = null


func _input(event):
	# ESC - open menu.
	if event.is_action_pressed("fullscreen"):
		get_tree().set_input_as_handled()
		Settings.full_screen = not Settings.full_screen
		OS.window_fullscreen = Settings.full_screen
		Settings.save()
