extends Level

func _ready():
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle2)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle3)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle4)
	for beam in $Statics/Beams.get_children():
		$Statics/Button.switchables.append(beam)
		beam.possible_colors.append(Circle.ColorType.WHITE)
		beam.possible_colors.append(Circle.ColorType.BLUE)
		beam.possible_colors.append(Circle.ColorType.GREEN)
		beam.possible_colors.append(Circle.ColorType.RED)
