extends Control

signal quit
signal start
signal close

onready var but_start = $"%ButtonStart"
onready var but_quit = $"%ButtonQuit"

var is_ingame


func _ready():
	but_start.text = tr("CONTINUE") if is_ingame else tr("START")
	pass


func _on_ButtonQuit_pressed():
	emit_signal("quit")


func _on_ButtonStart_pressed():
	emit_signal("start")


func _input(event):
	# ESC - close menu.
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		emit_signal("close")
		return
