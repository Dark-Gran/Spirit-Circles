extends Level

func _ready():
	$Statics/Button.switchables.append($Statics/Beam)
	$Statics/Beam.possible_colors.append(Circle.ColorType.WHITE)
	$Statics/Beam.possible_colors.append(Circle.ColorType.BLUE)
	$Statics/Beam.possible_colors.append(Circle.ColorType.GREEN)
