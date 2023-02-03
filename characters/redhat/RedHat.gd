extends Spatial

signal win
signal loose
signal lives_changed(count)
signal flowers_changed(count)

const LOOSE_REASON_DEATH := "LOOSE_DEATH"
const LOOSE_REASON_TIME := "LOOSE_TIME"
const ROADSIDE_POS := 2.7
const JUMP_SPEED := 1.0
const BLINK_COUNT := 8
const TIME_HALF_JUMP := 0.5
const TIME_BLINK := 0.125
const TIME_KNOCK_OUT := 2.0
const TIME_SLOWDOWN := 1.0
const TIME_FALL := 0.5
const TIME_SINK := 0.5

const SimpleArea = preload("res://objects/SimpleArea.gd")

onready var body := $RedHat
onready var cloak_up := $RedHat/RedHatCloakUP
onready var cloak_dn := $RedHat/RedHatCloakDN
onready var foot_l := $RedHat/RedHatFootL
onready var foot_r := $RedHat/RedHatFootR
onready var anim := $AnimationPlayer

export var RUN_SPEED := 5.0
export var STRAFE_SPEED := 1.5
export var TIME_LIMIT := 15.0
export var lives := 3


enum { NONE, RUN, JUMP, HIDE, FALL, BIRDS, SINK, BUBBLE }
var state := NONE

var is_end_game := false
var is_win := false
var flowers := 0
var loose_reason := ""
var is_jump_up := true
var current_speed := RUN_SPEED

var game_time := 0.0
var timer: float
var blink_time := 0.0
var blink_count := 0


func _ready():
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
				var strafe := 0
				if Input.is_action_pressed("Left"):
					strafe = -1
				elif Input.is_action_pressed("Right"):
					strafe = +1
				var x = translation.x
				x += strafe * STRAFE_SPEED * delta
				x = clamp(x, -ROADSIDE_POS, +ROADSIDE_POS)
				translation.x = x
				
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
		HIDE:
			timer -= delta
			if timer > 0: # Slowing down
				timer -= delta
				if timer <= 0:
					anim.stop()
					translation.y -= 0.5 # Body down (croach).
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
				translation.y -= delta
			else:
				_change_state(BUBBLE)
		BIRDS, BUBBLE:
			timer -= delta
			if timer < 0:
				lives -= 1
				emit_signal("lives_changed", lives)
				_change_state(RUN)

	game_time += delta
	_check_loose()


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


func _change_state(new_state: int):
	if new_state == state:
		return
	print("STATE: ", stname(state), " -> ", stname(new_state))
	if (state == HIDE) or (state == BUBBLE):
		# Exiting from HIDE or BUBBLE to any other: get up.
		translation.y = 0
	if state == JUMP:
		# Exiting from JUMP to any other: return legs down.
		foot_l.translation.y -= 0.25
		foot_r.translation.y -= 0.25
	cloak_up.visible = false
	cloak_dn.visible = true

	match new_state:
		RUN:
			anim.play("run")
			timer = 0
		JUMP:
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
		BIRDS, BUBBLE:
			timer = TIME_KNOCK_OUT

	state = new_state


func stname(st:int) -> String:
	match st:
		RUN:	return "RUN"
		JUMP:	return "JUMP"
		HIDE:	return "HIDE"
		FALL:	return "FALL"
		SINK:	return "SINK"
		BIRDS:	return "BIRDS"
		BUBBLE:	return "BUBBLE"
		_: return str(st)


func _check_loose():
	if lives < 1:
		_loose(LOOSE_REASON_DEATH)
	elif game_time > TIME_LIMIT:
		_loose(LOOSE_REASON_TIME)

func _loose(_reason):
	print("===== LOOSE: ", _reason, " =====")
	is_end_game = true
	is_win = false
	loose_reason = _reason
	emit_signal("loose")

func _win():
	print("===== WIN =====")
	is_end_game = true
	is_win = true
	emit_signal("win")


func _on_RedHat_area_entered(area:Area):
	if is_end_game:
		return
	if not area is SimpleArea:
		print("Unknown area: ", area)
		return
	var atype = (area as SimpleArea).area_type
	match atype:
		SimpleArea.AreaType.OBSTACLE:
			_change_state(FALL)
		SimpleArea.AreaType.RIVER:
			_change_state(SINK)
		SimpleArea.AreaType.FLOWER:
			if state == RUN:
				area.queue_free()
				flowers += 1
				emit_signal("flowers_changed", flowers)
		SimpleArea.AreaType.ENDGAME:
			_win()
