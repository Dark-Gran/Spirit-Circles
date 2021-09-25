extends KinematicBody2D

export (Circle.ColorType) var color_type = Circle.ColorType.WHITE

var possible_colors = Array()

func _ready():
	refresh()

func refresh():
	$MeshInstance2D.modulate = Circle.ct_dict.get(color_type).get("color")
	$MeshInstance2D.modulate.a = 0.5*$MeshInstance2D.modulate.a

func switch():
	var found = false
	for p in possible_colors:
		if found:
			color_type = p
			refresh()
			return found
		elif p == color_type:
			found = true
	color_type = possible_colors[0]
	refresh()
	return found
