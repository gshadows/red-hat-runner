extends Spatial

signal quit
signal start


func _ready():
	# Start wolf looking around :)
	$Wolf/AnimationPlayer.play(Wolf.ANIM_LOOK)
	$Wolf/AnimationPlayer.playback_speed /= 3


func quit_game():
	emit_signal("quit")

func start_game():
	emit_signal("start")
