extends Spatial

signal win
signal loose

const LOOSE_REASON_DEATH := "LOOSE_DEATH"
const LOOSE_REASON_TIME := "LOOSE_TIME"

onready var body := $RedHat
onready var cloak_up := $RedHatCloakUP
onready var cloak_dn := $RedHatCloakDN
onready var foot_l := $RedHatFootL
onready var foot_r := $RedHatFootR

export var TIME_LIMIT := 15.0
export var lives := 3


enum { RUN, JUMP, HIDE, FALL, BIRDS, SINK, BUBBLE }
var state = RUN

var is_end_game := false
var is_win := false
var flowers := 0
var loose_reason := ""
var is_jump_up := true

var game_time := 0.0
var timer: float


func _process(delta:float):
	if is_end_game:
		return

	match state:
		RUN:
			pass
		JUMP:
			pass
		HIDE:
			pass
		FALL:
			pass
		BIRDS:
			pass
		SINK:
			pass
		BUBBLE:
			pass

	game_time += delta
	_check_loose()


func _change_state(new_state: int):
	if new_state == state:
		return
	if state == HIDE:
		body.translation.y += 0.5
	if state == JUMP:
		foot_l.translation.y -= 0.25
		foot_r.translation.y -= 0.25
	cloak_up.visible = false
	cloak_dn.visible = true

	match new_state:
		RUN:
			pass
		JUMP:
			foot_l.translation.y += 0.25
			foot_r.translation.y += 0.25
			is_jump_up = true
		HIDE:
			body.translation.y -= 0.5
		FALL:
			pass
		BIRDS:
			pass
		SINK:
			pass
		BUBBLE:
			pass

	state = new_state


func _check_loose():
	if lives < 1:
		_loose(LOOSE_REASON_DEATH)
	elif game_time > TIME_LIMIT:
		_loose(LOOSE_REASON_TIME)

func _loose(_reason):
	is_end_game = true
	is_win = false
	loose_reason = _reason
	emit_signal("loose")

func _win():
	is_end_game = true
	is_win = true
	emit_signal("win")


const SimpleArea = preload("res://objects/SimpleArea.gd")

func _on_RedHat_area_entered(area):
	if not area is SimpleArea:
		print("Unknown area: ", area)
		return
	var atype = (area as SimpleArea).area_type
	match atype:
		SimpleArea.AreaType.OBSTACLE:
			_change_state(FALL)
		SimpleArea.AreaType.RIVER:
			_change_state(SINK)
		SimpleArea.AreaType.ENDGAME:
			_win()
