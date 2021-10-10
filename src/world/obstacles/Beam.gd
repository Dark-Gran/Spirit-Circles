extends Switchable

export (Circle.ColorType) var color_type = Circle.ColorType.WHITE

var possible_colors = Array()
var circles_inside = Array()

var switch_queued = false
var discoball

func _ready():
	discoball = get_parent().get_parent() != null && get_parent().get_parent().is_in_group("discoball")
	$Area2D/CollisionShape2D2.disabled = !discoball
	current_state = color_type
	options = possible_colors
	refresh()
	._ready()

func refresh():
	$MeshInstance2D.modulate = Circle.ct_dict.get(color_type).get("color")
	$MeshInstance2D.modulate.a = 0.4*$MeshInstance2D.modulate.a

func _physics_process(delta):
	# Check state
	if current_state != upcoming_state:
		current_state = upcoming_state
		color_type = upcoming_state
		refresh()
	# Check circles
	var to_remove = Array()
	for c in circles_inside:
		if c.merging_away || c == null:
			to_remove.append(c)
		elif c.color_type != color_type:
			c.remove_collision_exception_with(self)
			remove_collision_exception_with(c)
			var collision = c.move_and_collide(Vector2.ZERO, true, true, true)
			c.add_collision_exception_with(self)
			add_collision_exception_with(c)
			if collision && collision.collider == self:
				c.collide(collision)
	for c in to_remove:
		circles_inside.erase(c)
	# DiscoBall
	if discoball:
		for o in $Area2D.get_overlapping_bodies():
			if o.is_in_group("circles") && !circles_inside.has(o):
				circles_inside.append(o)

func add_circle_inside(circle):
	if !circles_inside.has(circle):
		circles_inside.append(circle)
