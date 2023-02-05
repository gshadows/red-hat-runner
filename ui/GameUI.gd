extends Control

const LIVES_ICON_SIZE = 64

onready var lives := $LivesCounter
onready var flowers := $FlowersCounter
onready var therm := $Thermometer


func on_lives_changed(count: int):
	if count < 1:
		lives.visible = false # Can't set width less then single size.
	else:
		lives.rect_size.x = count * LIVES_ICON_SIZE


func on_flowers_changed(count: int):
	flowers.text = str(count)


func on_temperature_changed(value: float):
	therm.value = value * therm.max_value
