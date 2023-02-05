extends SimpleArea

enum { NONE, WALK_IN, LOOK, WALK_OUT, RUN, JUMP }
var state := NONE

var target = null


func _ready():
	pass


func _process(delta):
	match state:
		NONE:
			return
		WALK_IN:
			pass
		WALK_OUT:
			pass
		LOOK:
			pass
		RUN:
			pass
		JUMP:
			pass


func change_state(new_state:int):
	if new_state == state:
		return
	print("WOLF STATE: ", stname(state), " -> ", stname(new_state))

	match new_state:
		NONE:
			return
		WALK_IN:
			pass
		WALK_OUT:
			pass
		LOOK:
			pass
		RUN:
			pass
		JUMP:
			pass
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
