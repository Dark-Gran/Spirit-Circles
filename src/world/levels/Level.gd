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
	$Circles.add_child(c)
	return c
