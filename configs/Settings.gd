extends Node

onready var AUDIO_BUS_MASTER = AudioServer.get_bus_index("Master")

const CFG_PATH = "config.ini"

const SCORES_TABLE_SIZE = 5
const SCORES_TABLE_NORMAL = "normal"

var sound_volume := 1.0
var full_screen := false

var debug := OS.is_debug_build()
var lang := "ru"

var scores_normal := _empty_scores()


func _ready():
	reload()
	apply()


func _empty_scores() -> Array:
	var scores = []
	for i in SCORES_TABLE_SIZE: scores.push_back(0)
	return scores


func save():
	var config = ConfigFile.new()

	config.set_value("audio", "sound_volume", sound_volume)
	config.set_value("video", "full_screen", full_screen)
	config.set_value("game", "lang", TranslationServer.get_locale())

	_save_scores_table(config, SCORES_TABLE_NORMAL)

	config.save(CFG_PATH)


func reload():
	var config = ConfigFile.new()
	var err = config.load(CFG_PATH)
	if err != OK:
		return

	sound_volume = config.get_value("audio", "sound_volume", sound_volume)
	full_screen = config.get_value("video", "full_screen", full_screen)
	lang = config.get_value("game", "lang", lang)

	_load_scores_table(config, SCORES_TABLE_NORMAL)


func apply():
	AudioServer.set_bus_volume_db(AUDIO_BUS_MASTER, linear2db(sound_volume))
	#AudioServer.set_bus_mute(AUDIO_BUS_MASTER, !sound_enable)

	OS.window_fullscreen = full_screen
	TranslationServer.set_locale(lang)


func _load_scores_table(config:ConfigFile, difficulty:String):
	var table = get_scores_table(difficulty)
	if table == null:
		return
	table.clear()
	var group_name := "scores_" + difficulty
	for i in SCORES_TABLE_SIZE:
		table.push_back(config.get_value(group_name, "score_" + str(i), 0))
	table.sort()


func _save_scores_table(config:ConfigFile, difficulty:String):
	var table = get_scores_table(difficulty)
	if table == null:
		return
	var group_name := "scores_" + difficulty
	for i in SCORES_TABLE_SIZE:
		if (i >= table.size()):
			table.push_front(0)
		config.set_value(group_name, "score_" + str(i), table[i])


func set_score(difficulty:String, value:int):
	var table = get_scores_table(difficulty)
	if table == null:
		return
	_insert_score(table, value)


func get_high_score(difficulty:String) -> int:
	var table = get_scores_table(difficulty)
	return table.back() if table else -1


func get_scores_table(difficulty:String):
	match difficulty.to_lower():
		SCORES_TABLE_NORMAL:
			return scores_normal
		_:
			print("Unknown difficulty: ", difficulty)
			return null


func _insert_score(table: Array, value:int):
	var index = table.bsearch(value)
	if (index <= 0) or ((index < table.size()) and (table[index] == value)):
		return # Do not overwrite. Do not add new lowest score.
	table.insert(index, value)
	table.remove(0) # Remove lowest.
