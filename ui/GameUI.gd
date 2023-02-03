extends Control

const LIVES_ICON_SIZE = 64

onready var lives := $LivesCounter
onready var flowers := $FlowersCounter


func on_lives_changed(count: int):
	lives.rect_size.x = count * LIVES_ICON_SIZE


func on_flowers_changed(count):
	flowers.text = str(count)
