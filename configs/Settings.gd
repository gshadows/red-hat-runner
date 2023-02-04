extends Node

onready var AUDIO_BUS_MASTER = AudioServer.get_bus_index("Master")

const CFG_PATH = "config.ini"

var sound_volume := 1.0
var full_screen := false

var debug := OS.is_debug_build()
var lang := "ru"


func _ready():
	reload()
	apply()


func save():
	var config = ConfigFile.new()

	config.set_value("audio", "sound_volume", sound_volume)
	config.set_value("video", "full_screen", full_screen)
	config.set_value("game", "lang", TranslationServer.get_locale())

	config.save(CFG_PATH)


func reload():
	var config = ConfigFile.new()
	var err = config.load(CFG_PATH)
	if err != OK:
		return

	sound_volume = config.get_value("audio", "sound_volume", sound_volume)
	full_screen = config.get_value("video", "full_screen", full_screen)
	lang = config.get_value("game", "lang", lang)


func apply():
	AudioServer.set_bus_volume_db(AUDIO_BUS_MASTER, linear2db(sound_volume))
	#AudioServer.set_bus_mute(AUDIO_BUS_MASTER, !sound_enable)

	OS.window_fullscreen = full_screen
	TranslationServer.set_locale(lang)
