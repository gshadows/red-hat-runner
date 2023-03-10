extends Control

const LIVES_ICON_SIZE := 64
const BLINK_TEMPERATURE := 0.15
const BLINK_PERIOD := 0.25

onready var lives := $LivesCounter
onready var flowers := $FlowersCounter
onready var therm := $Thermometer

var is_blinking := false
var is_blink_visible := false
var blink_time := 0.0
var is_new_high_score := false
var high_score := 0


func _process(delta):
	if is_blinking:
		blink_time -= delta
		if blink_time <= 0:
			blink_time = BLINK_PERIOD
			is_blink_visible = not is_blink_visible
			therm.tint_progress = Color.white if is_blink_visible else Color.yellow


func on_lives_changed(count: int):
	if count < 1:
		lives.visible = false # Can't set width less then single size.
	else:
		lives.rect_size.x = count * LIVES_ICON_SIZE


func on_flowers_changed(count: int):
	flowers.text = str(count)
	if (not is_new_high_score) and (high_score < count):
		is_new_high_score = true
		flowers.add_color_override("font_color", Color.magenta)


func on_temperature_changed(value: float):
	if value <= 0:
		value = 0
	elif value < BLINK_TEMPERATURE:
		is_blinking = true
	therm.value = value * therm.max_value


func on_loose(reason:String):
	$Wolf.visible = false
	$Loose.visible = true
	$Loose/Reason.text = tr(reason)
	if is_new_high_score:
		$Loose/Record.text = tr("HISCORE") + " " + str(high_score)
		$Loose/Record.visible = true


func on_win():
	$Wolf.visible = false
	$Win.visible = true
	if is_new_high_score:
		$Win/Record.text = tr("HISCORE") + " " + str(high_score)
		$Win/Record.visible = true


func on_wolf(is_here:bool):
	$Wolf.visible = is_here
