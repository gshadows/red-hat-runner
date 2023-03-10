extends Control

signal quit
signal start
signal close

onready var but_start = $"%ButtonStart"
onready var but_quit = $"%ButtonQuit"

var is_ingame


func _ready():
	# Restore sound volume.
	$SoundVolume.value = Settings.sound_volume
	# Rename START/CONTINUE button.
	but_start.text = tr("CONTINUE") if is_ingame else tr("START")


func _on_ButtonQuit_pressed():
	$SoundClick.play()
	yield(get_tree().create_timer(0.3), "timeout")
	emit_signal("quit")


func _on_ButtonStart_pressed():
	$SoundClick.play()
	yield(get_tree().create_timer(0.3), "timeout")
	emit_signal("start")


func _input(event):
	# ESC - close menu.
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		emit_signal("close")
		return


func _on_SoundVolume_drag_ended(_value_changed):
	#if value_changed: --> Bug? False if clicked instead of dragging.
	$SoundClick.play()
	Settings.save()

func _on_SoundVolume_value_changed(value):
	AudioServer.set_bus_volume_db(Settings.AUDIO_BUS_MASTER, linear2db(value))
	Settings.sound_volume = value


func _on_hover():
	$SoundHover.play()
