extends Level

func _ready():
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle2)
	$Statics/Button2.switchables.append($Statics/Rotatables/RotatableTriangle3)
	$Statics/Button2.switchables.append($Statics/Rotatables/RotatableTriangle4)
	$Statics/Button.switchables.append($Statics/Beams/Beam)
	$Statics/Button2.switchables.append($Statics/Beams/Beam)
	$Statics/Beams/Beam.possible_colors.append(Circle.ColorType.WHITE)
	$Statics/Beams/Beam.possible_colors.append(Circle.ColorType.BLUE)
	$Statics/Beams/Beam.possible_colors.append(Circle.ColorType.GREEN)
	$Statics/Beams/Beam.possible_colors.append(Circle.ColorType.RED)
