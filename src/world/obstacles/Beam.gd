extends KinematicBody2D

export (Circle.ColorType) var color_type = Circle.ColorType.WHITE

var possible_colors = Array()
var circles_inside = Array()

var switch_queued = false

func _ready():
	refresh()

func refresh():
	$MeshInstance2D.modulate = Circle.ct_dict.get(color_type).get("color")
	$MeshInstance2D.modulate.a = 0.4*$MeshInstance2D.modulate.a

func switch():
	var found = false
	for p in possible_colors:
		if found:
			color_type = p
			switch_queued = true
			return found
		elif p == color_type:
			found = true
	color_type = possible_colors[0]
	switch_queued = true
	return found

func _physics_process(delta):
	if switch_queued:
		switch_queued = false
		refresh()
	var to_remove = Array()
	for c in circles_inside:
		if c.merging_away:
			to_remove.append(c)
		elif c.color_type != color_type:
			c.remove_collision_exception_with(self)
			remove_collision_exception_with(c)
			var collision = c.move_and_collide(Vector2.ZERO, true, true, true)
			c.add_collision_exception_with(self)
			add_collision_exception_with(c)
			if collision:
				c.collide(collision)
	for c in to_remove:
		circles_inside.erase(c)

func add_circle_inside(circle):
	if !circles_inside.has(circle):
		circles_inside.append(circle)
