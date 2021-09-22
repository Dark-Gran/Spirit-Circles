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

func circles_overlap(c1, c2):
	var r1 = c1.size*SIZE_TO_SCALE
	var r2 = c2.size*SIZE_TO_SCALE
	var distance = sqrt(pow(c2.position.y-c1.position.y, 2) + pow(c2.position.x-c1.position.x, 2))
	return distance <= r1+r2
