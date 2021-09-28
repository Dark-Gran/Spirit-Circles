extends KinematicBody2D

export (PoolIntArray) var angles

var angle
var upcoming_angle
var new_angle

const ROT_SPEED = 50

func _ready():
	angle = round(rad2deg(transform.get_rotation()))
	upcoming_angle = angle
	if angles.size() == 0:
		angles.append(angle)

func switch():
	var found = false
	for a in angles:
		if found:
			upcoming_angle = a
			return found
		elif a == upcoming_angle:
			found = true
	upcoming_angle = angles[0]
	return found

func _physics_process(delta):
	if new_angle != upcoming_angle:
		new_angle = upcoming_angle
	if angle != upcoming_angle:
		if round(angle) == upcoming_angle: # todo smoother stop
			rotation = deg2rad(round(angle))
		else:
			var rot = ROT_SPEED * delta
			if angle > upcoming_angle:
				rot *= -1
			rotate(deg2rad(rot))
			angle = rad2deg(transform.get_rotation())
