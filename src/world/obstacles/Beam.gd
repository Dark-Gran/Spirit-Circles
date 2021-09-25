extends KinematicBody2D

export (Circle.ColorType) var color_type = Circle.ColorType.WHITE

func _ready():
	$MeshInstance2D.modulate = Circle.ct_dict.get(color_type).get("color")
