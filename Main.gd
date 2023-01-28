extends Node

const MENU_SCENE = "res://Menu.tscn"
const GAME_SCENE = "res://Game.tscn"

onready var Menu = preload(MENU_SCENE)
onready var Game = preload(GAME_SCENE)

var cur_scene


func _ready():
	randomize()
	Settings.reload()
	Settings.apply()
	open_menu()


func open_menu():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	unload()
	cur_scene = Menu.instance()
	add_child(cur_scene)


func start_game():
	unload()
	cur_scene = Game.instance()
	add_child(cur_scene)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func unload():
	if cur_scene:
		remove_child(cur_scene)
		cur_scene.queue_free()
		cur_scene = null
