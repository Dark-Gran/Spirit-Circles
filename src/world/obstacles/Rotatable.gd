extends Switchable

export (PoolIntArray) var angles

var next_angle

const ROT_SPEED = 30

func _ready():
	current_state = round(rad2deg(transform.get_rotation()))
	options = angles
	._ready()

func _physics_process(delta):
	if next_angle != upcoming_state:
		next_angle = upcoming_state
	if current_state != upcoming_state:
		if round(current_state) == upcoming_state: # todo smoother stop
			rotation = deg2rad(round(current_state))
		else:
			var rot = ROT_SPEED * delta
			if current_state > upcoming_state && (options.size() == 2 || upcoming_state >= 0):
				rot *= -1
			rotate(deg2rad(rot))
			current_state = rad2deg(transform.get_rotation())
