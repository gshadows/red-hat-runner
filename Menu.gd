extends Spatial

signal quit
signal start


func _ready():
	# Restore sound volume.
	$MusicSlider.value = Settings.music_volume
	# Start wolf looking around :)
	$Wolf/AnimationPlayer.play("Wolf_looking")
	$Wolf/AnimationPlayer.playback_speed /= 3


func quit_game():
	emit_signal("quit")

func start_game():
	emit_signal("start")
