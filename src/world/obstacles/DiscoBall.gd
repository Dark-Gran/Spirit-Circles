extends Switchable

export (float) var speed = 0.05

func _ready():
	options = [0, 1, 2, 3]
	current_state = 0
	._ready()

func _physics_process(delta):
	if current_state != upcoming_state:
		current_state = upcoming_state
	var rot
	match current_state:
		0:
			rot = 0
		1:
			rot = -speed
		2:
			rot = 0
		3:
			rot = speed
	if rot != 0:
		rotate(rot*delta)
