extends KinematicBody2D
class_name Circle

enum ColorType {WHITE, GREEN, BLUE, RED}
const ct_dict = {
	ColorType.WHITE: {
		"color": Color.white,
		"speed": 1,
		"lowest_power": 10
	},
	ColorType.BLUE: {
		"color": Color.blue,
		"speed": 1,
		"lowest_power": 10
	},
	ColorType.GREEN: {
		"color": Color.green,
		"speed": 1.4,
		"lowest_power": 5
	},
	ColorType.RED: {
		"color": Color.red,
		"speed": 0.9,
		"lowest_power": 5
	}
}
const MIN_SIZE = 0.01 # "Technical" limit
const PREDICTION_DISTANCE = 3
const PREDICTION_MAX = 350
const CIRCLE_BUTTON_MIN_RADIUS = 60
const CIRCLE_OVERLAP_FIX = 1 # see circles_overlap()
const MAX_MOVE_ATTEMPTS = 5 # see process() "Move"
const DANCE_STRENGTH = 0.1 # see dance()
const SPLIT_PART_ANGLE = 15 # see split()

export (ColorType) var color_type = ColorType.WHITE
export (int) var angle = 0
export (float) var size = 1

var color_info
var speed = 0
var velocity = Vector2.ZERO
var velocity_direction = Vector2.ZERO
var radius = (float(size)/PI)*Main.SIZE_TO_SCALE

var top_portal = 0
var left_portal = 0
var bot_portal = Main.DEFAULT_HEIGHT
var right_portal = Main.DEFAULT_WIDTH

var ray_point_a # End or Collision-point
var ray_point_b # not present or End
const RAY_TRESH = 0.01

var world # World -> Level -> Circles -> Circle
var level

var merging_away = false
var grow_buffer = 0
var unbreakable = false
var ignored_while_overlapping = Array()

var stuck_timer = 0

func _init():
	ray_point_a = position
	ray_point_b = null
	collision_layer = 1
	collision_mask = 1

func _ready():
	level = get_parent().get_parent()
	world = level.get_parent()
	color_info = ct_dict.get(color_type)
	if size < color_info.get("lowest_power"):
		size = color_info.get("lowest_power")
	$MeshInstance2D.modulate = color_info.get("color")
	refresh()

func _physics_process(delta):
	# Resize
	if merging_away || grow_buffer != 0:
		var grow_speed = world.get_grow_speed() * delta
		if merging_away:
			if size-grow_speed > MIN_SIZE:
				size -= grow_speed
				refresh()
			else:
				queue_free()
		elif grow_buffer > 0:
			if grow_buffer-grow_speed > 0:
				size += grow_speed
				grow_buffer -= grow_speed
			else:
				size += grow_buffer
				grow_buffer = 0
			refresh()
		elif grow_buffer < 0:
			if grow_buffer+grow_speed < 0:
				if size-grow_speed > MIN_SIZE:
					size -= grow_speed
					grow_buffer += grow_speed
			else:
				if size+grow_buffer > MIN_SIZE:
					size += grow_buffer
					grow_buffer = 0
			refresh()
	# Reset breakability
	if unbreakable && grow_buffer == 0:
		unbreakable = false
	# Reset collison-exceptions
	if ignored_while_overlapping.size() > 0:
		var not_to_ignore_anymore = Array()
		for i in ignored_while_overlapping:
			if i.is_in_group("circles"):
				if !merging_away && !circles_overlap(self, i):
					not_to_ignore_anymore.append(i)
			else:
				if i.get_node_or_null("CollisionShape2D") != null:
					if !$CollisionShape2D.shape.collide_with_motion($CollisionShape2D.global_transform, velocity*delta, i.get_node("CollisionShape2D").shape, i.get_node("CollisionShape2D").global_transform, Vector2.ZERO):
						not_to_ignore_anymore.append(i)
						if i.is_in_group("beams"):
							i.circles_inside.erase(self)
		for i in not_to_ignore_anymore:
			remove_from_ignore_while_overlapping(i)
	# RayCast
	if world.get_rays_enabled():
		var cast = velocity*PREDICTION_DISTANCE
		if cast.length() > PREDICTION_MAX:
			cast = cast.clamped(PREDICTION_MAX)
		var r = radius + Main.PC_RADIUS
		if cast.length() > r:
			$RayCastA.cast_to = cast
			$RayCastB.cast_to = cast
			$RayCastC.cast_to = cast
			$RayCastA.force_raycast_update()
			$RayCastB.force_raycast_update()
			$RayCastC.force_raycast_update()
			if $RayCastA.is_colliding() || $RayCastB.is_colliding() || $RayCastC.is_colliding():
				var collider
				if $RayCastC.get_collider():
					collider = $RayCastC.get_collider()
				elif $RayCastB.get_collider():
					collider = $RayCastB.get_collider()
				else:
					collider = $RayCastA.get_collider()
				var sic = Geometry.segment_intersects_circle(to_local(position), cast, to_local(collider.position), r-RAY_TRESH)
				if sic > 0 && (cast*sic).length() < (position-collider.position).length():
					ray_point_a = to_global(cast*sic)
					var	remaining_cast = to_global(cast)-ray_point_a
					var collision_normal = (ray_point_a - collider.position).normalized()
					var bounced = remaining_cast.bounce(collision_normal)
					ray_point_b = ray_point_a+bounced
				else:
					null_ray_points()
			else:
				ray_point_a = to_global(cast)
				ray_point_b = null
		else:
			null_ray_points()
	# Move
	var movement = velocity*delta
	var i = 0
	while movement.length() > 0 && i <= MAX_MOVE_ATTEMPTS:
		var collision = move_and_collide(movement, true, true, true)
		if collision:
			collide(collision)
			if get_collision_exceptions().has(collision.collider):
				move_and_collide(movement)
				break
			else:
				move_and_collide(collision.travel)
				movement = collision.remainder.rotated(collision.travel.angle()-deg2rad(angle))
		else:
			move_and_collide(movement)
			break
		i += 1
	# Stuck in wall -> Split
	pass

# COLLISIONS

func collide(collision):
	var collider = collision.collider
	if collider.is_in_group("circles"):
		if !collider.merging_away && !merging_away:
			var humbled = collider.size > size
			# Merge
			if color_type == collider.color_type:
				if humbled:
					collider.mergeIn(self)
				else:
					mergeIn(collider)
			# Split
			elif color_type == ColorType.RED || collider.color_type == ColorType.RED:
				if humbled:
					color_reaction(collider, color_type, collision)
				else:
					color_reaction(collider, collider.color_type, collision)
			# Misc
			elif collider.color_type != ColorType.WHITE && (color_type == ColorType.WHITE || humbled):
				color_reaction(collider, collider.color_type, collision)
			else:
				color_reaction(collider, color_type, collision)
		else:
			collider.add_collision_exception_with(self)
			add_collision_exception_with(collider)
	elif collider.is_in_group("beams"):
		if merging_away || color_type == collider.color_type:
			add_to_ignore_while_overlapping(collider)
			collider.add_circle_inside(self)
		elif collider.color_type == ColorType.WHITE:
			color_reaction(collider, color_type, collision)
		else:
			color_reaction(collider, collider.color_type, collision)
	else:
		bounce(collision)

func color_reaction(collider, color, collision):
	match color:
		ColorType.WHITE:
			bounce(collision)
		ColorType.GREEN:
			bounce(collision)
		ColorType.BLUE:
			dance(collider, collision)
		ColorType.RED:
			split(collider)

func bounce(collision):
	if collision.normal.dot(velocity) < 0:
		velocity = velocity.bounce(collision.normal)
		angle = rad2deg(velocity.angle())
		refresh_velocity()

func mergeIn(collider):
	collider.merging_away = true
	collider.add_collision_exception_with(self)
	add_collision_exception_with(collider)
	grow_buffer += collider.size+collider.grow_buffer
	collider.grow_buffer = 0

func dance(collider, collision):
	if collision.normal.dot(velocity) < 0:
		velocity = velocity.reflect(collision.normal)
		var new_angle = rad2deg(velocity.angle())
		if angle >= new_angle:
			angle += DANCE_STRENGTH
		else:
			angle -= DANCE_STRENGTH
		refresh_velocity()

func split(collider):
	var toSplit = self
	var splitter = collider
	if color_type == ColorType.RED:
		toSplit = collider
		splitter = self
	splitter.add_to_ignore_while_overlapping(toSplit)
	toSplit.add_to_ignore_while_overlapping(splitter)
	# Get outcome angle
	var splitter_direction = Vector2.ZERO
	if splitter.is_in_group("circles"):
		splitter_direction = splitter.velocity_direction
	var perpendicular = splitter_direction.rotated(deg2rad(90))
	var angle_to_perp = floor(rad2deg(toSplit.velocity_direction.angle_to(perpendicular)))
	var mid_direction = splitter_direction + toSplit.velocity_direction # "Get pushed by splitter"
	var mid_angle = rad2deg(mid_direction.angle())
	# Update toSplit
	var tot_size = toSplit.size+toSplit.grow_buffer
	var half_size = float(tot_size)/2
	if !toSplit.unbreakable && half_size >= toSplit.color_info.get("lowest_power"): # Break toSplit if big enough
		toSplit.unbreakable = true
		if angle_to_perp <= 0 && abs(angle_to_perp) != 180: # In direction against splitter's push = move against the push (ie. "splitting opposing force only corrects it")
			mid_direction = toSplit.velocity_direction - splitter_direction
			mid_angle = rad2deg(mid_direction.angle())
		# Update old
		toSplit.grow_buffer = -(toSplit.size-half_size)
		toSplit.angle = mid_angle - SPLIT_PART_ANGLE
		refresh()
		# Create new
		var opposite_angle = mid_angle + SPLIT_PART_ANGLE
		var new_circle = level.create_circle(toSplit.position, toSplit.color_type, opposite_angle, toSplit.size, toSplit.grow_buffer)
		new_circle.unbreakable = true
		new_circle.add_to_ignore_while_overlapping(toSplit)
		toSplit.add_to_ignore_while_overlapping(new_circle)
		new_circle.add_to_ignore_while_overlapping(splitter)
		splitter.add_to_ignore_while_overlapping(new_circle)
	else: # Redirect toSplit if too small
		toSplit.angle = mid_angle
		toSplit.refresh()

func add_to_ignore_while_overlapping(i):
	if !ignored_while_overlapping.has(i):
		add_collision_exception_with(i)
		ignored_while_overlapping.append(i)

func remove_from_ignore_while_overlapping(i):
	remove_collision_exception_with(i)
	ignored_while_overlapping.erase(i)

# REFRESHERS

func refresh():
	if size < MIN_SIZE:
		size = MIN_SIZE
	refresh_size()
	refresh_velocity()
	refresh_raycasts()

func refresh_size():
	var s = float(size)/PI
	$MeshInstance2D.scale = Vector2(s, s)
	$CollisionShape2D.scale = Vector2(s, s)
	radius = s*Main.SIZE_TO_SCALE
	top_portal = -radius
	left_portal = -radius
	bot_portal = Main.DEFAULT_HEIGHT+radius
	right_portal = Main.DEFAULT_WIDTH+radius

func refresh_velocity():
	if !(merging_away && size < color_info.get("lowest_power")):
		speed = (world.get("world_speed") * color_info.get("speed")) / pow((float(size)/PI)/2, 2)
	velocity = Vector2(speed*cos(deg2rad(angle)), speed*sin(deg2rad(angle)))
	velocity_direction = velocity.normalized()
	refresh_raycasts()

func refresh_raycasts():
	var d = velocity_direction * radius
	var ray = Vector2(d.y, -d.x)
	$RayCastA.position = -ray
	$RayCastB.position = ray
	if level.PlayerCircle_enabled:
		$RayCastA.enabled = true
		$RayCastB.enabled = true
		$RayCastC.enabled = true
	else:
		$RayCastA.enabled = false
		$RayCastB.enabled = false
		$RayCastC.enabled = false

func check_edge_portal():
	if position.x < left_portal || position.x > right_portal || position.y < top_portal || position.y > bot_portal:
		if position.x < left_portal:
			position.x = right_portal
		elif position.x > right_portal:
			position.x = left_portal
		if position.y < top_portal:
			position.y = bot_portal
		elif position.y > bot_portal:
			position.y = top_portal

# MISC

func set_size(new_size):
	size = new_size
	refresh()

func null_ray_points():
	ray_point_a = null
	ray_point_b = null

func circles_overlap(c1, c2):
	var r1 = c1.radius+CIRCLE_OVERLAP_FIX
	var r2 = c2.radius+CIRCLE_OVERLAP_FIX
	var distance = sqrt(pow(c2.position.y-c1.position.y, 2) + pow(c2.position.x-c1.position.x, 2))
	return distance <= r1+r2
