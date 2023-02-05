class_name Wolf
extends SimpleArea

signal walked_out
signal walked_in
signal attack_done

const ANIM_LOOK = "looking"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_JUMP = "jump"

const START_X := 5.0
const START_Z := 10.0

const WALK_SPEED := 1.5
const RUN_SPEED := 4.0
const JUMP_DISTANCE := 2.8 # From animation.
const JUMP_DISTANCE_SQUARED := pow(JUMP_DISTANCE, 2)
const ROADSIDE_IN_X := 1.5
const ROADSIDE_OUT_X := 3.0


onready var anim = $AnimationPlayer

enum { NONE, WALK_IN, LOOK, WALK_OUT, RUN, JUMP }
var state := NONE

var target = null
var walk_dir: int


func _ready():
	pass


func start_wolf(dir:int):
	walk_dir = dir
	change_state(WALK_IN)


func attack(redhat: Spatial):
	target = redhat
	change_state(RUN)


func _process(delta):
	match state:
		NONE:
			return
		WALK_IN:
			var old_x = translation.x
			translation.x = old_x + WALK_SPEED * walk_dir * delta
			var abs_x = abs(translation.x)
			if (abs_x < WALK_SPEED * delta):
				change_state(LOOK)
			elif (abs_x < ROADSIDE_IN_X) and (abs(old_x) < ROADSIDE_IN_X):
				# Entered the road.
				emit_signal("walked_in")
		WALK_OUT:
			translation.x += WALK_SPEED * walk_dir * delta
			if (abs(translation.x) > ROADSIDE_OUT_X):
				emit_signal("walked_out")
				change_state(NONE)
		LOOK:
			pass # Finish detected in on_look_finished() animation callback.
		RUN:
			var dist_sqr = global_translation.distance_squared_to(target.global_translation)
			if dist_sqr < JUMP_DISTANCE_SQUARED:
				change_state(JUMP)
			else:
				var new_pos = global_translation.move_toward(target.global_translation, RUN_SPEED * delta)
				look_at_from_position(new_pos, target.global_translation, Vector3.UP)
		JUMP:
			# Finish detected in on_jump_finished() animation callback.
			# Ensure distance is constant. No chance to evade.
			global_translation = target.global_translation + (global_translation - target.global_translation).normalized() * JUMP_DISTANCE
			look_at(target.global_translation, Vector3.UP)


func change_state(new_state:int):
	if new_state == state:
		return
	print("WOLF STATE: ", stname(state), " -> ", stname(new_state))

	match new_state:
		NONE:
			visible = false
		WALK_IN:
			visible = true
			translation = Vector3(START_X * -walk_dir, 0.0, START_Z)
			rotation.y = walk_dir * PI / 2
			anim.play(ANIM_WALK)
		WALK_OUT:
			anim.play(ANIM_WALK)
		LOOK:
			translation.x = 0
			anim.play(ANIM_LOOK)
		RUN:
			if not target:
				print("Expected target to attack")
				return
			anim.play(ANIM_RUN)
		JUMP:
			anim.play(ANIM_JUMP)
	state = new_state


func stname(st:int) -> String:
	match st:
		NONE:		return "NONE"
		WALK_IN:	return "WALK_IN"
		LOOK:		return "LOOK"
		WALK_OUT:	return "WALK_OUT"
		RUN:		return "RUN"
		JUMP:		return "JUMP"
		_: return str(st)


func on_jump_finished():
	change_state(NONE)
	emit_signal("attack_done")


func on_look_finished():
	change_state(WALK_OUT)
