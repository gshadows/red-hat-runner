class_name RedHat
extends Spatial

signal win
signal loose
signal lives_changed(count)
signal flowers_changed(count)
signal temperature_changed(value)

const LOOSE_REASON_DEATH := "LOOSE_DEATH"
const LOOSE_REASON_TIME := "LOOSE_TIME"
const LOOSE_REASON_WOLF := "LOOSE_WOLF"

const TIME_HALF_JUMP := 0.5
const TIME_BLINK := 0.05
const TIME_KNOCK_OUT := 1.5
const TIME_BUBBLE := 2.0
const TIME_SLOWDOWN := 1.0
const TIME_FALL := 0.5
const TIME_SINK := 0.15

const ROADSIDE_POS := 2.7
const JUMP_SPEED := 1.0
const BLINK_COUNT := int(1.5 / TIME_BLINK) # 1.5 seconds
const SINK_SPEED := 5.0
const HIDE_SPEED := 0.5

const SimpleArea = preload("res://objects/SimpleArea.gd")

onready var body := $RedHat
onready var cloak_up := $RedHat/RedHatCloakUP
onready var cloak_dn := $RedHat/RedHatCloakDN
onready var foot_l := $RedHat/RedHatFootL
onready var foot_r := $RedHat/RedHatFootR
onready var anim := $AnimationPlayer

# Configuration (based on difficulty).
var RUN_SPEED: float
var STRAFE_SPEED: float
var TIME_LIMIT: float
var lives: float


enum { NONE, RUN, JUMP, HIDE, FALL, BIRDS, SINK, BUBBLE }
var state := NONE

var is_end_game := false
var is_win := false
var flowers := 0
var is_jump_up := true
var current_speed: float

var game_time := 0.0
var timer: float
var blink_time := 0.0
var blink_count := 0


func start_game():
	call_deferred("emit_signal", "lives_changed", lives)
	call_deferred("emit_signal", "flowers_changed", flowers)
	_change_state(RUN)


func _process(delta:float):
	if is_end_game:
		return

	# Blinking (invulnerable) after knock-out.
	if blink_count > 0:
		do_blinking(delta)

	match state:
		RUN:
			if Input.is_action_just_pressed("Jump"):
				_change_state(JUMP)
			elif Input.is_action_just_pressed("Hide"):
				_change_state(HIDE)
			else:
				_do_strafe(delta)
				
		JUMP:
			if timer > 0:
				timer -= delta
				if is_jump_up:
					translation.y = cos(timer / TIME_HALF_JUMP * (PI/2)) * JUMP_SPEED
				else:
					translation.y = sin(timer / TIME_HALF_JUMP * (PI/2)) * JUMP_SPEED
			else:
				if is_jump_up:
					is_jump_up = false;
					timer = TIME_HALF_JUMP
					cloak_dn.visible = false
					cloak_up.visible = true
				else:
					_change_state(RUN)
					translation.y = 0
			_do_strafe(delta)
		HIDE:
			if timer > 0: # Slowing down
				timer -= delta
				if timer <= 0:
					anim.stop()
					current_speed = 0
					translation.y -= HIDE_SPEED * delta # Body down (croach).
				else:
					current_speed = RUN_SPEED * timer / TIME_SLOWDOWN
			if Input.is_action_just_pressed("Jump"):
				_change_state(JUMP)
			elif Input.is_action_just_released("Hide"):
				_change_state(RUN)
		FALL:
			timer -= delta
			if (not anim.is_playing()) or (timer < 0):
				_change_state(BIRDS)
				if timer < 0:
					print("Fall animation still playing: ", anim.current_animation, " at pos ", anim.current_animation_position)
		SINK:
			timer -= delta
			if timer > 0:
				translation.y -= SINK_SPEED * delta
			else:
				_change_state(BUBBLE)
		BIRDS, BUBBLE:
			if timer > 0:
				timer -= delta
			else:
				lives -= 1
				emit_signal("lives_changed", lives)
				if lives < 1:
					loose(LOOSE_REASON_DEATH)
				else:
					start_blinking()
					_change_state(RUN)

	game_time += delta
	emit_signal("temperature_changed", 1.0 - game_time / TIME_LIMIT )


func start_blinking():
	blink_count = BLINK_COUNT
	blink_time = TIME_BLINK
	visible = true


func do_blinking(delta:float):
	blink_time -= delta
	if (blink_time <= 0):
		visible = not visible
		blink_time = TIME_BLINK
		if visible:
			blink_count -= 1


func _do_strafe(delta:float):
	var strafe := 0
	if Input.is_action_pressed("Left"):
		strafe = -1
	elif Input.is_action_pressed("Right"):
		strafe = +1
	var x = translation.x
	x += strafe * STRAFE_SPEED * delta
	x = clamp(x, -ROADSIDE_POS, +ROADSIDE_POS)
	translation.x = x


func _change_state(new_state: int):
	if new_state == state:
		return
	print("STATE: ", stname(state), " -> ", stname(new_state))
	if state == JUMP:
		# Exiting from JUMP to any other: return legs down.
		foot_l.translation.y -= 0.25
		foot_r.translation.y -= 0.25
	if state == HIDE:
		translation.y = 0
	cloak_up.visible = false
	cloak_dn.visible = true

	match new_state:
		RUN:
			translation.y = 0
			current_speed = RUN_SPEED
			anim.play("run")
			timer = 0
		JUMP:
			translation.y = 0
			current_speed = RUN_SPEED
			is_jump_up = true
			anim.stop()
			foot_l.translation.y += 0.25 # Legs up.
			foot_r.translation.y += 0.25
			timer = TIME_HALF_JUMP
		HIDE:
			timer = TIME_SLOWDOWN
		FALL:
			anim.play("fall")
			timer = TIME_FALL
		SINK:
			timer = TIME_SINK
		BIRDS:
			current_speed = 0
			timer = TIME_KNOCK_OUT
		BUBBLE:
			current_speed = 0
			timer = TIME_BUBBLE
	state = new_state


func stname(st:int) -> String:
	match st:
		NONE:	return "NONE"
		RUN:	return "RUN"
		JUMP:	return "JUMP"
		HIDE:	return "HIDE"
		FALL:	return "FALL"
		SINK:	return "SINK"
		BIRDS:	return "BIRDS"
		BUBBLE:	return "BUBBLE"
		_: return str(st)


func loose(_reason):
	print("===== LOOSE: ", _reason, " =====")
	_endgame()
	is_win = false
	visible = false
	emit_signal("loose", _reason)


func win():
	if game_time > TIME_LIMIT:
		loose(LOOSE_REASON_TIME)
	else:
		print("===== WIN =====")
		_endgame()
		is_win = true
		emit_signal("win")


func _endgame():
	is_end_game = true
	current_speed = 0
	anim.stop()


func _on_RedHat_area_entered(area:Area):
	if is_end_game:
		return
	if not area is SimpleArea:
		print("Unknown area: ", area)
		return
	var atype = (area as SimpleArea).area_type
	match atype:
		SimpleArea.AreaType.OBSTACLE:
			if blink_count <= 0:
				_change_state(FALL)
		SimpleArea.AreaType.RIVER:
			if (state == RUN) and (blink_count <= 0):
				_change_state(SINK)
		SimpleArea.AreaType.FLOWER:
			if (state == RUN) or (state == JUMP):
				area.queue_free()
				flowers += 1
				emit_signal("flowers_changed", flowers)
		SimpleArea.AreaType.WOLF:
			if blink_count <= 0:
				loose(LOOSE_REASON_WOLF)
		SimpleArea.AreaType.ENDGAME:
			if blink_count > 0:
				blink_count = 0
				visible = true
			win()


func on_wolf_appear():
	pass


func on_wolf_disappear():
	pass
