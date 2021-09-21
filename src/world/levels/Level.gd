extends Node2D
class_name Level

export (String) var level_name = "..."
export (bool) var FocusPower_enabled = true
export (bool) var PlayerCircle_enabled = true
export (bool) var Stopwatch_enabled = true

func create_circle(pos, color_type, angle, size): # todo
	print("- creating new circle")
	var c = Circle.new()
	c.queue_free()
