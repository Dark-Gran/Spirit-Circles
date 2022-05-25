extends KinematicBody2D
class_name Circle

var ParticlesWhite = preload("res://src/world/circle_effects/ParticlesWhite.tscn")
var ParticlesBlue = preload("res://src/world/circle_effects/ParticlesBlue.tscn")
var ParticlesGreen = preload("res://src/world/circle_effects/ParticlesGreen.tscn")
var ParticlesRed = preload("res://src/world/circle_effects/ParticlesRed.tscn")
var GlowBlue = preload("res://src/world/circle_effects/GlowBlue.tscn")
var GlowGreen = preload("res://src/world/circle_effects/GlowGreen.tscn")

enum ColorType {WHITE, BLUE, GREEN, RED}
const ct_dict = {
	ColorType.WHITE: {
		"color": Color.white,
		"speed": 1,
		"lowest_power": 10
	},
	ColorType.BLUE: {
		"color": Color.blue,
		"speed": 0.8,
		"lowest_power": 10
	},
	ColorType.GREEN: {
		"color": Color(0, 0.6, 0), # todo color-palette
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
const SPLIT_PART_ANGLE = 20 # see split()
const STUCK_CAP = 3 # see process() "Stuck"

var default_sprite_scale # taken directly from sprite

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
var particle_alpha = 1

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
	$Sprite.modulate = color_info.get("color")
	default_sprite_scale = $Sprite.scale
	create_effects()
	refresh()
	
func create_effects():
	var particles
	var glow
	match (color_type):
		ColorType.WHITE:
			particles = ParticlesWhite.instance()
		ColorType.BLUE:
			particles = ParticlesBlue.instance()
			glow = GlowBlue.instance()
		ColorType.GREEN:
			particles = ParticlesGreen.instance()
			glow = GlowGreen.instance()
		ColorType.RED:
			particles = ParticlesRed.instance()
	if particles != null:
		add_child(particles)
	if glow != null:
		add_child(glow)

func _process(delta):
	refresh_particle_alpha(delta)

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
		$CollisionShape2D.disabled = false
		stuck_timer = 0
	# Reset collison-exceptions
	if grow_buffer == 0: # possibly in-future: debug red beams without this line (note: issues with collide_with_motion()/overlaps_body()?)
		if ignored_while_overlapping.size() > 0:
			var not_to_ignore_anymore = Array()
			for i in ignored_while_overlapping:
				if i != null && is_instance_valid(i):
					if i.is_in_group("circles"):
						if merging_away || !circles_overlap(self, i):
							not_to_ignore_anymore.append(i)
					else:
						if !$StuckDetector.overlaps_body(i):
						#if i.get_node_or_null("CollisionShape2D") != null && !Main.bodies_collide_with_motion(self, i, Vector2.ZERO, Vector2.ZERO):
							not_to_ignore_anymore.append(i)
				else:
					not_to_ignore_anymore.append(i)
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
	var r = 0
	var collision
	while movement.length() > 0 && r <= MAX_MOVE_ATTEMPTS:
		collision = move_and_collide(movement, true, true, true)
		if collision:
			collide(collision)
			if should_ignore_collision(collision.collider, self):
				move_and_collide(movement)
				break
			else:
				move_and_collide(collision.travel)
				var rad_angle = deg2rad(angle)
				if rad_angle < collision.remainder.angle():
					movement = collision.remainder.rotated(rad_angle-collision.remainder.angle())
				else:
					movement = collision.remainder.rotated(collision.remainder.angle()-rad_angle)
		else:
			move_and_collide(movement)
			break
		r += 1
	# Stuck in wall -> Split
	if !unbreakable:
		var i = 0
		for b in $StuckDetector.get_overlapping_bodies():
			if !b.is_in_group("beams") && !b.is_in_group("circles"):
				i += 1
		if i > 1:
			stuck_timer += delta
			if stuck_timer > STUCK_CAP:
				stuck_timer = 0
				split_on_stuck($StuckDetector.get_overlapping_bodies())
		elif stuck_timer > 0:
			stuck_timer = 0

# COLLISIONS

func should_ignore_collision(a, b):
	return "color_type" in a && "color_type" in b && (a.color_type == b.color_type || a.color_type == ColorType.RED || b.color_type == ColorType.RED)

func collide(collision):
	var collider = collision.collider
	if collider.is_in_group("circles"):
		if !collider.merging_away && !merging_away:
			var humbled = size <= collider.size
			# Merge
			if color_type == collider.color_type:
				if !collider.unbreakable && !unbreakable:
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
		elif collider.color_type == ColorType.WHITE && color_type != ColorType.RED:
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
			split(collider, collision)

func bounce(collision):
	if collision.normal.dot(velocity) < 0:
		velocity = velocity.bounce(collision.normal)
		angle = rad2deg(velocity.angle())
		refresh_velocity()

func mergeIn(collider):
	collider.merging_away = true
	collider.get_node("Particles").z_index = -2
	if (collider.has_node("Glows")):
		collider.get_node("Glows").z_index = -4
	collider.get_node("Sprite").z_index = -3
	collider.particle_alpha = 0
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

func split(collider, collision):
	var toSplit = self
	var splitter = collider
	if color_type == ColorType.RED:
		toSplit = collider
		splitter = self
	# Get outcome angle
	toSplit.add_to_ignore_while_overlapping(splitter)
	var splitter_direction = Vector2.ZERO
	if splitter.is_in_group("circles"):
		splitter.add_to_ignore_while_overlapping(toSplit)
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
		if splitter.is_in_group("circles"):
			splitter.add_to_ignore_while_overlapping(new_circle)
		if collider.is_in_group("beams"):
			collider.add_circle_inside(new_circle)
			collider.add_circle_inside(toSplit)
		return new_circle
	elif !toSplit.unbreakable: # Redirect toSplit if too small
		toSplit.angle = mid_angle
		toSplit.refresh()
		if collider.is_in_group("beams"):
			collider.add_circle_inside(toSplit)
		return null

func split_on_stuck(overlaps):
	if overlaps.size() > 0:
		var new_circle = split(overlaps[0], null)
		if new_circle:
			for o in overlaps:
				o.add_collision_exception_with(self)
				add_to_ignore_while_overlapping(o)
				o.add_collision_exception_with(new_circle)
				new_circle.add_to_ignore_while_overlapping(o)
				if o.is_in_group("beams"):
					o.add_circle_inside(new_circle)

func add_to_ignore_while_overlapping(i):
	if !ignored_while_overlapping.has(i):
		add_collision_exception_with(i)
		ignored_while_overlapping.append(i)

func remove_from_ignore_while_overlapping(i):
	remove_collision_exception_with(i)
	ignored_while_overlapping.erase(i)
	if i != null && is_instance_valid(i):
		if !i.is_in_group("circles"):
			i.remove_collision_exception_with(self)
			if i.is_in_group("beams"):
				i.circles_inside.erase(self)

# REFRESHERS

func refresh():
	if size < MIN_SIZE:
		size = MIN_SIZE
	refresh_size()
	refresh_velocity()
	refresh_raycasts()
	refresh_particles()

func refresh_particles():
	if has_node("Particles") && !merging_away:
		var s: float = 0
		var s2: float = 0
		var a: float = 1
		var a2: float = 1
		match color_type:
			ColorType.BLUE:
				s = 14
				a = 0.6
			ColorType.GREEN:
				s = 40
				a = 0.7
				s2 = 7.5
				a2 = 0.2
			ColorType.RED:
				s = 20
				a = 0.75
				s2 = 7.5
				a2 = 0.2
		if size < s2:
			particle_alpha = a2
			if color_type == ColorType.GREEN || color_type == ColorType.RED:
				$Particles/Particles2D3.emitting = false
				$Particles/Particles2D4.emitting = false
		elif size < s:
			particle_alpha = a
			if color_type == ColorType.GREEN || color_type == ColorType.RED:
				$Particles/Particles2D3.emitting = true
				$Particles/Particles2D4.emitting = false
		else:
			particle_alpha = 1
			if color_type == ColorType.GREEN || color_type == ColorType.RED:
				$Particles/Particles2D3.emitting = true
				$Particles/Particles2D4.emitting = true

func refresh_particle_alpha(delta):
	if has_node("Particles"):
		var change = delta
		var particles
		if color_type == ColorType.GREEN || color_type == ColorType.RED:
			if merging_away:
				particles = $Particles/Particles2D2
				change *= 2
			else:
				particles = $Particles/Inner
		else:
			particles = $Particles
			if color_type == ColorType.BLUE:
				smooth_modulate_a($Glows/Sprite, change, particle_alpha)
		if particles != null && particles.modulate.a != particle_alpha:
			smooth_modulate_a(particles, change, particle_alpha)

func smooth_modulate_a(modulee, change, target_a):
	if (modulee.modulate.a > target_a && modulee.modulate.a-change > target_a) || (modulee.modulate.a < target_a && modulee.modulate.a+change < target_a):
		if modulee.modulate.a > target_a:
			modulee.modulate.a -= change
		else:
				modulee.modulate.a += change
	else:
		modulee.modulate.a = target_a

func refresh_size():
	var s = float(size)/PI
	var new_scale = Vector2(s, s)
	$Sprite.scale = new_scale * default_sprite_scale
	if (has_node("Particles")):
		$Particles.scale = new_scale
	if (has_node("Glows")):
		$Glows.scale = new_scale
	$CollisionShape2D.scale = new_scale
	$StuckDetector.scale = new_scale
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
