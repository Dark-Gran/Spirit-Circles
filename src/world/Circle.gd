extends KinematicBody2D
class_name Circle

enum ColorType {WHITE, GREEN, BLUE, RED}
var ct_dict = {
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
const DANCE_STRENGTH = 0.1
const PREDICTION_DISTANCE = 3
const PREDICTION_MAX = 350
const CIRCLE_BUTTON_MIN_RADIUS = 80

export (ColorType) var color_type = ColorType.WHITE
export (int) var angle = 0
export (float) var size = 1

var color_info
var min_size = 0.01 # "Technical" limit

var speed = 0
var velocity = Vector2.ZERO
var velocity_direction = Vector2.ZERO
var radius = size*Main.SIZE_TO_SCALE
var pc_radius = 40

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
			if size-grow_speed > min_size:
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
				if size-grow_speed > min_size:
					size -= grow_speed
					grow_buffer += grow_speed
			else:
				if size+grow_buffer > min_size:
					size += grow_buffer
					grow_buffer = 0
			refresh()
	# RayCast
	if world.get_rays_enabled():
		var cast = velocity*PREDICTION_DISTANCE
		if cast.length() > PREDICTION_MAX:
			cast = cast.clamped(PREDICTION_MAX)
		var r = (radius + Main.PC_RADIUS)
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
	while movement.length() > 0:
		var collision = move_and_collide(movement, true, true, true)
		if collision:
			collide(collision.collider)
			move_and_collide(movement)
			movement = collision.remainder
		else:
			move_and_collide(movement)
			movement = Vector2.ZERO

func null_ray_points():
	ray_point_a = null
	ray_point_b = null

func collide(collider):
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
					color_reaction(collider, color_type)
				else:
					color_reaction(collider, collider.color_type)
			# Misc
			elif collider.color_type != ColorType.WHITE && (color_type == ColorType.WHITE || humbled):
				color_reaction(collider, collider.color_type)
			else:
				color_reaction(collider, color_type)
	else:
		bounce(collider)

func color_reaction(collider, color):
	match color:
		ColorType.WHITE:
			bounce(collider)
		ColorType.GREEN:
			bounce(collider)
		ColorType.BLUE:
			dance(collider)
		ColorType.RED:
			split(collider)

func split(collider):
	collider.add_collision_exception_with(self)
	add_collision_exception_with(collider)
	var toSplit = self
	if color_type == ColorType.RED:
		toSplit = collider
	if !toSplit.unbreakable:
		toSplit.unbreakable = true
		var hs = float(toSplit.size+toSplit.grow_buffer)/2
		if hs >= toSplit.color_info.get("lowest_power"):
			# Resize old
			toSplit.grow_buffer = -(toSplit.size-hs)
			# Create new
			level.create_circle(toSplit.position, toSplit.color_type, toSplit.angle, hs) # todo

func mergeIn(collider):
	collider.merging_away = true
	collider.add_collision_exception_with(self)
	add_collision_exception_with(collider)
	grow_buffer += collider.size+collider.grow_buffer
	collider.grow_buffer = 0

func dance(collider):
	var collision_normal = (position-collider.position).normalized()
	if collision_normal.dot(velocity) < 0:
		velocity = velocity.reflect(collision_normal)
		var new_angle = rad2deg(velocity.angle())
		if angle >= new_angle:
			angle += DANCE_STRENGTH
		else:
			angle -= DANCE_STRENGTH
		refresh_velocity()

func bounce(collider):
	var collision_normal = (position-collider.position).normalized()
	if collision_normal.dot(velocity) < 0:
		velocity = velocity.bounce(collision_normal)
		angle = rad2deg(velocity.angle())
		refresh_velocity()

func refresh():
	if size < min_size:
		size = min_size
	refresh_size()
	refresh_velocity()
	refresh_raycasts()

func refresh_size():
	var s = float(size)/PI
	$MeshInstance2D.scale = Vector2(s, s)
	$CollisionShape2D.scale = Vector2(s, s)
	radius = s * Main.SIZE_TO_SCALE
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

func set_size(new_size):
	size = new_size
	refresh()
