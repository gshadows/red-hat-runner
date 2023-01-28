extends Spatial

signal quit

onready var MenuUI = preload("res://ui/MenuUI.tscn")

var menu


func _input(event):
	# ESC - open menu.
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		if not menu:
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
	emit_signal("quit")
