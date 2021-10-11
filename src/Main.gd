extends Node

const DEFAULT_WIDTH = 1920
const DEFAULT_HEIGHT = 1080
const SIZE_TO_SCALE = 10
const PC_RADIUS = 40

var current_scene = null

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	goto_scene("res://src/world/World.tscn")

func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	current_scene.free()
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

func fix_angle(angle):
	while angle > 360:
		angle -= 360
	while angle <= -360:
		angle += 360
	return angle

#if angle_difference > 180:
#	angle_difference = -(360-angle_difference)
#elif angle_difference <= -180:
#	angle_difference = 360+angle_difference

#func bodies_collide_with_motion(a, b, motion_a, motion_b):
#	return a.get_node("CollisionShape2D").shape.collide_with_motion(a.get_node("CollisionShape2D").global_transform, motion_a, b.get_node("CollisionShape2D").shape, b.get_node("CollisionShape2D").global_transform, motion_b)
