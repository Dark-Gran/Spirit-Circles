extends Area2D

export (int) var angle = 0
export (float) var size = 1

var speed = 70
var velocity = Vector2(0, 0)
var velocity_direction = Vector2(0, 0)
var radius = size*Main.SIZE_TO_SCALE
var pc_radius = 40

var top_portal = 0
var left_portal = 0
var bot_portal = Main.DEFAULT_HEIGHT
var right_portal = Main.DEFAULT_WIDTH

var ray_point_a # End or Collision-point
var ray_point_b # not present or End
const RAY_TRESH = 0.01

func _ready():
	ray_point_a = position
	ray_point_b = null
	collision_layer = 1
	collision_mask = 1
	refresh_size()
	refresh_velocity()
	refresh_raycasts()

func _physics_process(delta):
	# Move
	position += velocity*delta
	# RayCast
	var cast = velocity*Main.PREDICTION_DISTANCE
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
		var r = (size*Main.SIZE_TO_SCALE + Main.PC_RADIUS - RAY_TRESH)
		var sic = Geometry.segment_intersects_circle(to_local(position), cast, to_local(collider.position), r)
		ray_point_a = to_global(cast*sic)
		var remaining_cast = to_global(cast)-ray_point_a
		var collision_normal = (ray_point_a - collider.position).normalized()
		var bounced = remaining_cast.bounce(collision_normal)
		ray_point_b = ray_point_a+bounced
	else:
		ray_point_a = to_global(cast)
		ray_point_b = null

func _on_Circle_area_entered(area): # Collided
	var collision_normal = (position-area.position).normalized()
	if collision_normal.dot(velocity) < 0:
		velocity = velocity.bounce(collision_normal)
		angle = rad2deg(velocity.angle())
		refresh_velocity()

func refresh_size():
	$MeshInstance2D.scale = Vector2(size, size)
	$CollisionShape2D.scale = Vector2(size, size)
	radius = size * Main.SIZE_TO_SCALE

func refresh_raycasts():
	var d = velocity_direction * radius
	var ray = Vector2(d.y, -d.x)
	$RayCastA.position = -ray
	$RayCastB.position = ray

func refresh_velocity():
	velocity = Vector2(speed*cos(deg2rad(angle)), speed*sin(deg2rad(angle)))
	velocity_direction = velocity.normalized()
	refresh_raycasts()

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
