extends Spatial

signal quit
signal start


func _ready():
	var __
	__ = $"%MenuUI".connect("quit", self, "quit_game")
	__ = $"%MenuUI".connect("start", self, "start_game")
	pass


func quit_game():
	emit_signal("quit")

func start_game():
	emit_signal("start")
