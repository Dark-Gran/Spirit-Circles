extends Node2D
class_name Level

export (String) var level_name = "..."
export (bool) var FocusPower_enabled = true
export (bool) var PlayerCircle_enabled = true
export (bool) var Stopwatch_enabled = true

const CircleScene = preload("res://src/world/Circle.tscn")

func create_circle(pos, color_type, angle, size, buffer):
	var c = CircleScene.instance()
	c.position = pos
	c.color_type = color_type
	c.angle = angle
	c.size = size
	c.grow_buffer = buffer
	c.get_node("CollisionShape2D").disabled = true
	$Circles.add_child(c)
	c.refresh()
	#if get_node_or_null("Statics/Beams") != null:
	#	for beam in $Statics/Beams.get_children():
	#		if Main.bodies_collide_with_motion(c, beam, Vector2.ZERO, Vector2.ZERO):
	#			beam.circles_inside.append(c)
	return c
